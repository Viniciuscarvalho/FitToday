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
    private let updateGroupStreakUseCase: UpdateGroupStreakUseCaseProtocol?
    private let pendingQueue: PendingSyncQueue?
    private let analytics: AnalyticsTracking?

    init(
        leaderboardRepository: LeaderboardRepository,
        userRepository: UserRepository,
        authRepository: AuthenticationRepository,
        historyRepository: WorkoutHistoryRepository,
        updateGroupStreakUseCase: UpdateGroupStreakUseCaseProtocol? = nil,
        pendingQueue: PendingSyncQueue? = nil,
        analytics: AnalyticsTracking? = nil
    ) {
        self.leaderboardRepository = leaderboardRepository
        self.userRepository = userRepository
        self.authRepository = authRepository
        self.historyRepository = historyRepository
        self.updateGroupStreakUseCase = updateGroupStreakUseCase
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
        #if DEBUG
        print("[SyncWorkoutCompletionUseCase] 🏋️ Starting sync for entry: \(entry.id)")
        print("[SyncWorkoutCompletionUseCase]    Status: \(entry.status)")
        print("[SyncWorkoutCompletionUseCase]    Duration: \(entry.durationMinutes ?? 0) min")
        print("[SyncWorkoutCompletionUseCase]    Title: \(entry.title)")
        #endif

        // 1. Skip if workout skipped (not completed)
        guard entry.status == .completed else {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ❌ Skipping: workout status is \(entry.status), not completed")
            #endif
            return
        }

        // 2. Validate minimum duration (30 minutes)
        let workoutDuration = entry.durationMinutes ?? 0
        guard workoutDuration >= Self.minimumWorkoutMinutes else {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ❌ Workout too short (\(workoutDuration) min), minimum is \(Self.minimumWorkoutMinutes) min")
            #endif
            return
        }

        // 3. Verify authentication
        guard let user = try await authRepository.currentUser() else {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ❌ Skipping: user not authenticated")
            #endif
            return
        }

        #if DEBUG
        print("[SyncWorkoutCompletionUseCase] 👤 User authenticated: \(user.displayName) (\(user.id))")
        print("[SyncWorkoutCompletionUseCase]    Photo URL: \(user.photoURL?.absoluteString ?? "nil")")
        print("[SyncWorkoutCompletionUseCase]    Group ID: \(user.currentGroupId ?? "nil")")
        print("[SyncWorkoutCompletionUseCase]    Privacy shareWorkoutData: \(user.privacySettings.shareWorkoutData)")
        #endif

        // 4. Track personal stats for solo users (no group required)
        await trackPersonalStats(entry: entry, userId: user.id)

        // 5. Verify group membership for group challenges
        guard let groupId = user.currentGroupId else {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ℹ️ User has no group - personal stats tracked, skipping group challenges")
            #endif
            return
        }

        // 5. Respect privacy settings
        guard user.privacySettings.shareWorkoutData else {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ❌ Skipping: user privacy settings block workout sharing")
            #endif
            return
        }

        #if DEBUG
        print("[SyncWorkoutCompletionUseCase] ✅ All conditions met - syncing workout to group \(groupId)")
        #endif

        // 6. Update member weekly stats
        try await leaderboardRepository.updateMemberWeeklyStats(
            groupId: groupId,
            userId: user.id,
            workoutMinutes: workoutDuration
        )

        #if DEBUG
        print("[SyncWorkoutCompletionUseCase] 📊 Updated member weekly stats: +\(workoutDuration) min")
        #endif

        // 6. Fetch current week's challenges
        let challenges = try await leaderboardRepository.getCurrentWeekChallenges(groupId: groupId)

        #if DEBUG
        print("[SyncWorkoutCompletionUseCase] 🏆 Found \(challenges.count) challenges for group \(groupId)")
        for challenge in challenges {
            print("[SyncWorkoutCompletionUseCase]    - \(challenge.type.rawValue) (id: \(challenge.id), active: \(challenge.isActive))")
        }
        #endif

        // 7. Update check-ins challenge
        if let checkInsChallenge = challenges.first(where: { $0.type == .checkIns }) {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] 📝 Incrementing check-in for challenge \(checkInsChallenge.id)")
            print("[SyncWorkoutCompletionUseCase]    User: \(user.displayName)")
            print("[SyncWorkoutCompletionUseCase]    Photo: \(user.photoURL?.absoluteString ?? "nil")")
            #endif

            try await leaderboardRepository.incrementCheckIn(
                challengeId: checkInsChallenge.id,
                userId: user.id,
                displayName: user.displayName,
                photoURL: user.photoURL
            )
            // Track check-ins sync event (value is incremented, so we don't have exact count here)
            analytics?.trackWorkoutSynced(userId: user.id, groupId: groupId, challengeType: .checkIns, value: 1)

            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ✅ Check-in incremented successfully")
            #endif
        } else {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ⚠️ No check-ins challenge found for this week")
            #endif
        }

        // 8. Compute and update streak challenge
        if let streakChallenge = challenges.first(where: { $0.type == .streak }) {
            let streak = try await computeCurrentStreak(userId: user.id)

            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] 🔥 Updating streak to \(streak) days for challenge \(streakChallenge.id)")
            #endif

            try await leaderboardRepository.updateStreak(
                challengeId: streakChallenge.id,
                userId: user.id,
                streakDays: streak,
                displayName: user.displayName,
                photoURL: user.photoURL
            )
            // Track streak sync event
            analytics?.trackWorkoutSynced(userId: user.id, groupId: groupId, challengeType: .streak, value: streak)

            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ✅ Streak updated successfully")
            #endif
        } else {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ⚠️ No streak challenge found for this week")
            #endif
        }

        // 9. Update Group Streak (weekly 3-workout compliance)
        if let updateGroupStreakUseCase {
            do {
                let result = try await updateGroupStreakUseCase.execute(
                    userId: user.id,
                    displayName: user.displayName,
                    photoURL: user.photoURL
                )

                #if DEBUG
                if result.userBecameCompliant {
                    print("[SyncWorkoutCompletionUseCase] User became compliant for group streak")
                }
                if result.allMembersCompliant {
                    print("[SyncWorkoutCompletionUseCase] All members are now compliant!")
                }
                #endif
            } catch {
                // Group streak update failure should not block the rest of the sync
                #if DEBUG
                print("[SyncWorkoutCompletionUseCase] Group streak update failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Private Methods

    /// BUG FIX #7: Use consistent calendar with user's timezone for streak calculations
    /// This prevents timezone-related issues when calculating consecutive days
    private static var streakCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current // Use user's timezone for local day boundaries
        return calendar
    }

    private func computeCurrentStreak(userId: String) async throws -> Int {
        let entries = try await historyRepository.listEntries()
        let calendar = Self.streakCalendar

        // BUG FIX #3: Only count workouts >= 30 minutes for streak calculation
        let completedDates = entries
            .filter { $0.status == .completed && ($0.durationMinutes ?? 0) >= Self.minimumWorkoutMinutes }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)

        // Remove duplicates (multiple workouts on same day)
        let uniqueDates = Array(Set(completedDates)).sorted(by: >)

        guard let mostRecent = uniqueDates.first else { return 0 }
        let today = calendar.startOfDay(for: Date())

        // Streak broken if most recent is not today or yesterday
        guard mostRecent == today || calendar.dateComponents([.day], from: mostRecent, to: today).day == 1 else {
            return 0
        }

        // Count consecutive days
        var streak = 1
        for i in 1..<uniqueDates.count {
            let prev = uniqueDates[i-1]
            let current = uniqueDates[i]
            if calendar.dateComponents([.day], from: current, to: prev).day == 1 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Personal Stats Tracking (Solo Users)

    /// Tracks personal stats for the user regardless of group membership.
    /// This allows solo users to still track their workouts and maintain streaks.
    private func trackPersonalStats(entry: WorkoutHistoryEntry, userId: String) async {
        #if DEBUG
        print("[SyncWorkoutCompletionUseCase] 📊 Tracking personal stats for user \(userId)")
        print("[SyncWorkoutCompletionUseCase]    Duration: \(entry.durationMinutes ?? 0) min")
        print("[SyncWorkoutCompletionUseCase]    Calories: \(entry.caloriesBurned ?? 0)")
        #endif

        // Compute and log current streak
        do {
            let streak = try await computeCurrentStreak(userId: userId)
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] 🔥 Personal streak: \(streak) days")
            #endif
        } catch {
            #if DEBUG
            print("[SyncWorkoutCompletionUseCase] ❌ Failed to compute personal streak: \(error.localizedDescription)")
            #endif
        }
    }
}
