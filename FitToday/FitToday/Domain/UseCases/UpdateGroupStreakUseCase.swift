//
//  UpdateGroupStreakUseCase.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import Foundation

// MARK: - Protocol

protocol UpdateGroupStreakUseCaseProtocol: Sendable {
    /// Increments workout count for a user in their group's current week streak
    /// - Parameters:
    ///   - userId: The user who completed the workout
    ///   - displayName: User's display name
    ///   - photoURL: User's photo URL
    /// - Returns: Whether the user became compliant with this workout
    func execute(userId: String, displayName: String, photoURL: URL?) async throws -> UpdateGroupStreakResult
}

// MARK: - Result

struct UpdateGroupStreakResult: Sendable {
    let groupId: String
    let userBecameCompliant: Bool
    let allMembersCompliant: Bool
    let currentWorkoutCount: Int
    let milestone: StreakMilestone?

    static let noGroup = UpdateGroupStreakResult(
        groupId: "",
        userBecameCompliant: false,
        allMembersCompliant: false,
        currentWorkoutCount: 0,
        milestone: nil
    )
}

// MARK: - Implementation

struct UpdateGroupStreakUseCase: UpdateGroupStreakUseCaseProtocol {
    private let groupStreakRepository: GroupStreakRepository
    private let authRepository: AuthenticationRepository
    private let notificationRepository: NotificationRepository?
    private let analytics: AnalyticsTracking?

    init(
        groupStreakRepository: GroupStreakRepository,
        authRepository: AuthenticationRepository,
        notificationRepository: NotificationRepository? = nil,
        analytics: AnalyticsTracking? = nil
    ) {
        self.groupStreakRepository = groupStreakRepository
        self.authRepository = authRepository
        self.notificationRepository = notificationRepository
        self.analytics = analytics
    }

    func execute(userId: String, displayName: String, photoURL: URL?) async throws -> UpdateGroupStreakResult {
        // 1. Get user's current group
        guard let user = try await authRepository.currentUser(),
              let groupId = user.currentGroupId else {
            return .noGroup
        }

        // 2. Get current streak status before update
        let statusBefore = try await groupStreakRepository.getStreakStatus(groupId: groupId)
        let memberStatusBefore = statusBefore.currentWeek?.memberCompliance.first { $0.id == userId }
        let wasCompliant = memberStatusBefore?.isCompliant ?? false

        // 3. Increment workout count
        try await groupStreakRepository.incrementWorkoutCount(
            groupId: groupId,
            userId: userId,
            displayName: displayName,
            photoURL: photoURL
        )

        // 4. Get updated status
        let statusAfter = try await groupStreakRepository.getStreakStatus(groupId: groupId)
        let memberStatusAfter = statusAfter.currentWeek?.memberCompliance.first { $0.id == userId }
        let isNowCompliant = memberStatusAfter?.isCompliant ?? false

        // 5. Check if user just became compliant
        let userBecameCompliant = !wasCompliant && isNowCompliant

        // 6. Check if all members are now compliant
        let allMembersCompliant = statusAfter.currentWeek?.isAllCurrentlyCompliant ?? false

        // 7. Send notification if user became compliant
        if userBecameCompliant {
            await sendComplianceNotification(
                groupId: groupId,
                userId: userId,
                displayName: displayName,
                allCompliant: allMembersCompliant
            )

            // Track analytics
            analytics?.trackEvent(
                name: "group_streak_member_compliant",
                parameters: [
                    "group_id": groupId,
                    "user_id": userId,
                    "all_compliant": String(allMembersCompliant)
                ]
            )
        }

        // 8. Check for milestone if all compliant (milestone is awarded at week end by Cloud Function)
        let milestone = statusAfter.justAchievedMilestone

        return UpdateGroupStreakResult(
            groupId: groupId,
            userBecameCompliant: userBecameCompliant,
            allMembersCompliant: allMembersCompliant,
            currentWorkoutCount: memberStatusAfter?.workoutCount ?? 0,
            milestone: milestone
        )
    }

    // MARK: - Private Methods

    private func sendComplianceNotification(
        groupId: String,
        userId: String,
        displayName: String,
        allCompliant: Bool
    ) async {
        guard let notificationRepository else { return }

        do {
            let message: String
            if allCompliant {
                message = String(localized: "\(displayName) completed their 3 workouts! All members are now compliant for this week!")
            } else {
                message = String(localized: "\(displayName) completed their 3 workouts for this week!")
            }

            let notification = GroupNotification(
                id: UUID().uuidString,
                userId: "", // Will be set by repository for all group members
                groupId: groupId,
                type: .rankChange, // Reusing existing type for now
                message: message,
                isRead: false,
                createdAt: Date()
            )

            try await notificationRepository.createNotification(notification)
        } catch {
            #if DEBUG
            print("[UpdateGroupStreakUseCase] Failed to send notification: \(error.localizedDescription)")
            #endif
        }
    }
}
