//
//  JoinGroupUseCase.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation

// MARK: - JoinGroupUseCase

struct JoinGroupUseCase: Sendable {
    private let groupRepository: GroupRepository
    private let userRepository: UserRepository
    private let authRepository: AuthenticationRepository
    private let notificationRepository: NotificationRepository?
    private let analytics: AnalyticsTracking?

    init(
        groupRepository: GroupRepository,
        userRepository: UserRepository,
        authRepository: AuthenticationRepository,
        notificationRepository: NotificationRepository? = nil,
        analytics: AnalyticsTracking? = nil
    ) {
        self.groupRepository = groupRepository
        self.userRepository = userRepository
        self.authRepository = authRepository
        self.notificationRepository = notificationRepository
        self.analytics = analytics
    }

    // MARK: - Execute

    func execute(groupId: String, inviteSource: InviteSource = .link) async throws {
        // 1. Validate user is authenticated
        guard let user = try await authRepository.currentUser() else {
            throw DomainError.notAuthenticated
        }

        // 2. Validate user NOT already in a group (MVP: 1-group limit)
        guard user.currentGroupId == nil else {
            throw DomainError.alreadyInGroup
        }

        // 3. Fetch group to verify it exists
        guard let group = try await groupRepository.getGroup(groupId) else {
            throw DomainError.groupNotFound
        }

        // 4. Validate group is not full (max 10 members)
        guard group.memberCount < 10 else {
            throw DomainError.groupFull
        }

        // 5. Get existing members before adding (for notification)
        let existingMembers = try await groupRepository.getMembers(groupId: groupId)

        // 6. Add user as member to the group
        try await groupRepository.addMember(
            groupId: groupId,
            userId: user.id,
            displayName: user.displayName,
            photoURL: user.photoURL
        )

        // 7. Update user's currentGroupId
        try await userRepository.updateCurrentGroup(user.id, groupId: groupId)

        // 8. Track analytics event
        analytics?.trackGroupJoined(groupId: groupId, userId: user.id, inviteSource: inviteSource)
        analytics?.setUserInGroup(true)
        analytics?.setUserRole(.member)

        // 9. Create notifications for existing members (non-blocking, don't fail if this fails)
        await notifyExistingMembers(
            existingMembers: existingMembers,
            newMemberName: user.displayName,
            groupId: groupId,
            newMemberId: user.id
        )
    }

    // MARK: - Private Methods

    private func notifyExistingMembers(
        existingMembers: [GroupMember],
        newMemberName: String,
        groupId: String,
        newMemberId: String
    ) async {
        guard let notificationRepo = notificationRepository else { return }

        for member in existingMembers where member.id != newMemberId && member.isActive {
            let notification = GroupNotification(
                id: UUID().uuidString,
                userId: member.id,
                groupId: groupId,
                type: .newMember,
                message: "\(newMemberName) joined your group!",
                isRead: false,
                createdAt: Date()
            )

            do {
                try await notificationRepo.createNotification(notification)
            } catch {
                #if DEBUG
                print("[JoinGroupUseCase] Failed to create notification for \(member.id): \(error)")
                #endif
                // Don't throw - notifications are non-critical
            }
        }
    }
}
