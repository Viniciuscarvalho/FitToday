//
//  SyncWorkoutCompletionUseCase.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation

// MARK: - SyncWorkoutCompletionUseCase

struct SyncWorkoutCompletionUseCase: Sendable {
    private let leaderboardRepository: LeaderboardRepository
    private let userRepository: UserRepository
    private let authRepository: AuthenticationRepository
    private let historyRepository: WorkoutHistoryRepository
    private let pendingQueue: PendingSyncQueue?
    private let analytics: AnalyticsTracking?

    init(
        leaderboardRepository: LeaderboardRepository,
        userRepository: UserRepository,
        authRepository: AuthenticationRepository,
        historyRepository: WorkoutHistoryRepository,
        pendingQueue: PendingSyncQueue? = nil,
        analytics: AnalyticsTracking? = nil
    ) {
        self.leaderboardRepository = leaderboardRepository
        self.userRepository = userRepository
        self.authRepository = authRepository
        self.historyRepository = historyRepository
        self.pendingQueue = pendingQueue
        self.analytics = analytics
    }

    // MARK: - Execute

    /// Execute sync for a workout entry. On network failure, gracefully enqueues for later retry.
    /// - Parameter entry: The workout history entry to sync.
    /// - Note: This method does NOT throw on network errors - it queues for retry instead.
    func execute(entry: WorkoutHistoryEntry) async {
        do {
            try await performSync(entry: entry)
        } catch {
            // Network or other error - enqueue for retry (graceful degradation)
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] Sync failed, enqueueing for retry: \(error.localizedDescription)")
            #endif

            await pendingQueue?.enqueue(entry)
        }
    }

    /// Minimum workout duration in minutes to count for challenges
    private static let minimumWorkoutMinutes = 30

    /// Internal sync method that can throw errors.
    /// Used by both execute() and queue processing.
    func performSync(entry: WorkoutHistoryEntry) async throws {
        // 1. Skip if workout skipped (not completed)
        guard entry.status == .completed else { return }

        // 2. Validate minimum duration (30 minutes)
        let workoutDuration = entry.durationMinutes ?? 0
        guard workoutDuration >= Self.minimumWorkoutMinutes else {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] Workout too short (\(workoutDuration) min), minimum is \(Self.minimumWorkoutMinutes) min")
            #endif
            return
        }

        // 3. Verify authentication and group membership
        guard let user = try await authRepository.currentUser(),
              let groupId = user.currentGroupId else { return }

        // 4. Respect privacy settings
        guard user.privacySettings.shareWorkoutData else { return }

        // 5. Update member weekly stats
        try await leaderboardRepository.updateMemberWeeklyStats(
            groupId: groupId,
            userId: user.id,
            workoutMinutes: workoutDuration
        )

        // 6. Fetch current week's challenges
        let challenges = try await leaderboardRepository.getCurrentWeekChallenges(groupId: groupId)

        // 7. Update check-ins challenge
        if let checkInsChallenge = challenges.first(where: { $0.type == .checkIns }) {
            try await leaderboardRepository.incrementCheckIn(challengeId: checkInsChallenge.id, userId: user.id)
            // Track check-ins sync event (value is incremented, so we don't have exact count here)
            analytics?.trackWorkoutSynced(userId: user.id, groupId: groupId, challengeType: .checkIns, value: 1)
        }

        // 8. Compute and update streak challenge
        if let streakChallenge = challenges.first(where: { $0.type == .streak }) {
            let streak = try await computeCurrentStreak(userId: user.id)
            try await leaderboardRepository.updateStreak(challengeId: streakChallenge.id, userId: user.id, streakDays: streak)
            // Track streak sync event
            analytics?.trackWorkoutSynced(userId: user.id, groupId: groupId, challengeType: .streak, value: streak)
        }
    }

    // MARK: - Private Methods

    private func computeCurrentStreak(userId: String) async throws -> Int {
        let entries = try await historyRepository.listEntries()
        let completedDates = entries
            .filter { $0.status == .completed }
            .map { Calendar.current.startOfDay(for: $0.date) }
            .sorted(by: >)

        guard let mostRecent = completedDates.first else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())

        // Streak broken if most recent is not today or yesterday
        guard mostRecent == today || Calendar.current.dateComponents([.day], from: mostRecent, to: today).day == 1 else {
            return 0
        }

        // Count consecutive days
        var streak = 1
        for i in 1..<completedDates.count {
            let prev = completedDates[i-1]
            let current = completedDates[i]
            if Calendar.current.dateComponents([.day], from: current, to: prev).day == 1 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}
