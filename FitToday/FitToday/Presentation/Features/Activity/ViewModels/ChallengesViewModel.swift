//
//  ChallengesViewModel.swift
//  FitToday
//
//  ViewModel for Challenges view using Firebase data.
//

import Foundation
import Swinject

// MARK: - ChallengesViewModel

@MainActor
@Observable final class ChallengesViewModel {
    // MARK: - Properties

    private(set) var challenges: [ChallengeDisplayModel] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var currentGroupId: String?
    private(set) var isInGroup = false
    private(set) var healthKitSyncStatus: String?

    private let resolver: Resolver
    nonisolated(unsafe) private var leaderboardTask: Task<Void, Never>?

    /// Flag to prevent repeated HealthKit syncs in the same session
    private var hasPerformedHealthKitSync = false

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: - Lifecycle

    func onAppear() async {
        // Run HealthKit sync and challenges load in parallel
        async let healthKitSync: () = syncHealthKitWorkoutsIfAuthorized()
        async let challengesLoad: () = loadChallenges()

        _ = await (healthKitSync, challengesLoad)
    }

    // MARK: - HealthKit Auto-Sync

    /// Automatically syncs Apple Health workouts to count towards challenges.
    /// This runs once per session when the challenges view appears.
    private func syncHealthKitWorkoutsIfAuthorized() async {
        // Only sync once per session to avoid repeated API calls
        guard !hasPerformedHealthKitSync else { return }

        guard let healthKitService = resolver.resolve(HealthKitServicing.self) else {
            #if DEBUG
            print("[ChallengesViewModel] ⚠️ HealthKit service not available")
            #endif
            return
        }

        // Check if HealthKit is authorized
        let authState = await healthKitService.authorizationState()
        guard authState == .authorized else {
            #if DEBUG
            print("[ChallengesViewModel] ⚠️ HealthKit not authorized, skipping sync")
            #endif
            return
        }

        guard let syncService = resolver.resolve(HealthKitHistorySyncService.self) else {
            #if DEBUG
            print("[ChallengesViewModel] ⚠️ HealthKit sync service not available")
            #endif
            return
        }

        hasPerformedHealthKitSync = true

        do {
            // Import external workouts from Apple Health (last 7 days)
            let imported = try await syncService.importExternalWorkouts(days: 7)

            // Also sync existing app workouts with HealthKit data
            let synced = try await syncService.syncLastDays(7)

            if imported > 0 || synced > 0 {
                healthKitSyncStatus = "✅ \(imported) treinos importados do Apple Health"
                #if DEBUG
                print("[ChallengesViewModel] ✅ HealthKit sync: \(imported) imported, \(synced) synced")
                #endif
            } else {
                #if DEBUG
                print("[ChallengesViewModel] ✅ HealthKit sync completed, no new workouts")
                #endif
            }
        } catch {
            #if DEBUG
            print("[ChallengesViewModel] ❌ HealthKit sync error: \(error.localizedDescription)")
            #endif
            // Don't show error to user - this is a background operation
        }
    }

    func refresh() async {
        // Reset sync flag to allow re-sync on pull-to-refresh
        hasPerformedHealthKitSync = false

        // Run HealthKit sync and challenges load in parallel
        async let healthKitSync: () = syncHealthKitWorkoutsIfAuthorized()
        async let challengesLoad: () = loadChallenges()

        _ = await (healthKitSync, challengesLoad)
    }

    // MARK: - Data Loading

    private func loadChallenges() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Get current user and their group
        guard let authRepo = resolver.resolve(AuthenticationRepository.self) else {
            errorMessage = "Serviço de autenticação não disponível"
            return
        }

        do {
            guard let user = try await authRepo.currentUser() else {
                // User not logged in - show empty state
                challenges = []
                isInGroup = false
                return
            }

            guard let groupId = user.currentGroupId else {
                // User not in a group - show empty state
                challenges = []
                isInGroup = false
                return
            }

            currentGroupId = groupId
            isInGroup = true

            // Fetch challenges from Firebase
            guard let leaderboardRepo = resolver.resolve(LeaderboardRepository.self) else {
                errorMessage = "Serviço de ranking não disponível"
                return
            }

            let firebaseChallenges = try await leaderboardRepo.getCurrentWeekChallenges(groupId: groupId)

            // Start observing leaderboards for each challenge
            await startObservingLeaderboards(groupId: groupId, challenges: firebaseChallenges)

        } catch is CancellationError {
            // Task was cancelled (e.g., view disappeared) - this is expected, don't show error
            #if DEBUG
            print("[ChallengesViewModel] Task cancelled - view likely disappeared")
            #endif
        } catch {
            #if DEBUG
            print("[ChallengesViewModel] Error loading challenges: \(error)")
            #endif
            errorMessage = "Erro ao carregar desafios: \(error.localizedDescription)"
        }
    }

    private func startObservingLeaderboards(groupId: String, challenges: [Challenge]) async {
        guard let leaderboardRepo = resolver.resolve(LeaderboardRepository.self),
              let authRepo = resolver.resolve(AuthenticationRepository.self) else {
            return
        }

        // Cancel previous observation
        leaderboardTask?.cancel()

        // Get current user for their entry
        let currentUserId = try? await authRepo.currentUser()?.id

        // Get the streams on the main actor
        let checkInsStream = leaderboardRepo.observeLeaderboard(groupId: groupId, type: .checkIns)
        let streakStream = leaderboardRepo.observeLeaderboard(groupId: groupId, type: .streak)

        leaderboardTask = Task { @MainActor in
            await withTaskGroup(of: Void.self) { group in
                // Observe check-ins leaderboard
                group.addTask { @MainActor in
                    for await snapshot in checkInsStream {
                        guard !Task.isCancelled else { return }
                        self.updateChallengeFromSnapshot(snapshot, currentUserId: currentUserId)
                    }
                }

                // Observe streak leaderboard
                group.addTask { @MainActor in
                    for await snapshot in streakStream {
                        guard !Task.isCancelled else { return }
                        self.updateChallengeFromSnapshot(snapshot, currentUserId: currentUserId)
                    }
                }
            }
        }
    }

    private func updateChallengeFromSnapshot(_ snapshot: LeaderboardSnapshot, currentUserId: String?) {
        let challenge = snapshot.challenge

        // Find current user's entry
        let userEntry = currentUserId.flatMap { userId in
            snapshot.entries.first { $0.id == userId }
        }

        // Calculate progress
        let currentValue = userEntry?.value ?? 0
        let targetValue: Int
        let unit: String
        let iconName: String
        let title: String
        let description: String

        switch challenge.type {
        case .checkIns:
            targetValue = 7 // 7 check-ins per week
            unit = "check-ins"
            iconName = "checkmark.circle.fill"
            title = "Desafio Semanal de Check-ins"
            description = "Complete 7 check-ins esta semana para liderar o ranking"
        case .streak:
            targetValue = 7 // 7 day streak
            unit = "dias"
            iconName = "flame.fill"
            title = "Streak Semanal"
            description = "Mantenha uma sequência de 7 dias consecutivos de treino"
        }

        let progress = targetValue > 0 ? min(Double(currentValue) / Double(targetValue), 1.0) : 0.0

        // Calculate days remaining
        let now = Date()
        let daysRemaining = max(0, Calendar.current.dateComponents([.day], from: now, to: challenge.weekEndDate).day ?? 0)

        let displayModel = ChallengeDisplayModel(
            id: challenge.id,
            title: title,
            description: description,
            type: challenge.type,
            iconName: iconName,
            progress: progress,
            currentValue: currentValue,
            targetValue: targetValue,
            unit: unit,
            daysRemaining: daysRemaining,
            participants: snapshot.entries.count,
            isActive: challenge.isActive,
            startDate: challenge.weekStartDate,
            endDate: challenge.weekEndDate
        )

        // Update or add challenge
        if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
            challenges[index] = displayModel
        } else {
            challenges.append(displayModel)
        }
    }

    // MARK: - Cleanup

    func stopObserving() {
        leaderboardTask?.cancel()
        leaderboardTask = nil
    }

    deinit {
        leaderboardTask?.cancel()
    }
}
