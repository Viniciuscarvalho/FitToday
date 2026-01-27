//
//  PauseGroupStreakUseCase.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import Foundation

// MARK: - Protocol

protocol PauseGroupStreakUseCaseProtocol: Sendable {
    /// Pauses the group streak for the specified number of days
    /// - Parameters:
    ///   - groupId: The group to pause the streak for
    ///   - days: Number of days to pause (1-7)
    /// - Throws: GroupStreakError if user is not admin, pause already used, or invalid duration
    func pause(groupId: String, days: Int) async throws

    /// Resumes a paused streak early
    /// - Parameter groupId: The group to resume the streak for
    /// - Throws: GroupStreakError if user is not admin or streak is not paused
    func resume(groupId: String) async throws
}

// MARK: - Implementation

struct PauseGroupStreakUseCase: PauseGroupStreakUseCaseProtocol {
    private let groupStreakRepository: GroupStreakRepository
    private let groupRepository: GroupRepository
    private let authRepository: AuthenticationRepository
    private let analytics: AnalyticsTracking?

    /// Maximum number of days a streak can be paused
    static let maxPauseDays = 7

    init(
        groupStreakRepository: GroupStreakRepository,
        groupRepository: GroupRepository,
        authRepository: AuthenticationRepository,
        analytics: AnalyticsTracking? = nil
    ) {
        self.groupStreakRepository = groupStreakRepository
        self.groupRepository = groupRepository
        self.authRepository = authRepository
        self.analytics = analytics
    }

    // MARK: - Pause

    func pause(groupId: String, days: Int) async throws {
        // 1. Validate days parameter
        guard days > 0, days <= Self.maxPauseDays else {
            throw GroupStreakError.pauseDurationTooLong(maxDays: Self.maxPauseDays)
        }

        // 2. Get current user
        guard let user = try await authRepository.currentUser() else {
            throw GroupStreakError.notGroupAdmin
        }

        // 3. Verify user is admin
        let isAdmin = try await verifyIsAdmin(groupId: groupId, userId: user.id)
        guard isAdmin else {
            throw GroupStreakError.notGroupAdmin
        }

        // 4. Get current streak status
        let status = try await groupStreakRepository.getStreakStatus(groupId: groupId)

        // 5. Verify streak is active
        guard status.hasActiveStreak else {
            throw GroupStreakError.streakNotActive
        }

        // 6. Check if pause already used this month
        if status.pauseUsedThisMonth {
            throw GroupStreakError.pauseAlreadyUsedThisMonth
        }

        // 7. Calculate pause end date
        let pauseUntil = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        // 8. Pause the streak
        try await groupStreakRepository.pauseStreak(groupId: groupId, until: pauseUntil)

        // 9. Mark pause as used for this month
        try await groupStreakRepository.markPauseUsedThisMonth(groupId: groupId)

        // Track analytics
        analytics?.trackEvent(
            name: "group_streak_paused",
            parameters: [
                "group_id": groupId,
                "user_id": user.id,
                "pause_days": String(days),
                "streak_days": String(status.streakDays)
            ]
        )

        #if DEBUG
        print("[PauseGroupStreakUseCase] Streak paused for \(days) days until \(pauseUntil)")
        #endif
    }

    // MARK: - Resume

    func resume(groupId: String) async throws {
        // 1. Get current user
        guard let user = try await authRepository.currentUser() else {
            throw GroupStreakError.notGroupAdmin
        }

        // 2. Verify user is admin
        let isAdmin = try await verifyIsAdmin(groupId: groupId, userId: user.id)
        guard isAdmin else {
            throw GroupStreakError.notGroupAdmin
        }

        // 3. Get current streak status
        let status = try await groupStreakRepository.getStreakStatus(groupId: groupId)

        // 4. Verify streak is actually paused
        guard status.isPaused else {
            throw GroupStreakError.streakNotActive
        }

        // 5. Resume the streak
        try await groupStreakRepository.resumeStreak(groupId: groupId)

        // Track analytics
        analytics?.trackEvent(
            name: "group_streak_resumed",
            parameters: [
                "group_id": groupId,
                "user_id": user.id,
                "streak_days": String(status.streakDays)
            ]
        )

        #if DEBUG
        print("[PauseGroupStreakUseCase] Streak resumed")
        #endif
    }

    // MARK: - Private Methods

    private func verifyIsAdmin(groupId: String, userId: String) async throws -> Bool {
        let members = try await groupRepository.getMembers(groupId: groupId)
        guard let member = members.first(where: { $0.id == userId }) else {
            return false
        }
        return member.role == .admin
    }
}
