//
//  LeaveGroupUseCase.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation

// MARK: - LeaveGroupUseCase

struct LeaveGroupUseCase: Sendable {
    private let groupRepository: GroupRepository
    private let userRepository: UserRepository
    private let authRepository: AuthenticationRepository
    private let analytics: AnalyticsTracking?

    init(
        groupRepository: GroupRepository,
        userRepository: UserRepository,
        authRepository: AuthenticationRepository,
        analytics: AnalyticsTracking? = nil
    ) {
        self.groupRepository = groupRepository
        self.userRepository = userRepository
        self.authRepository = authRepository
        self.analytics = analytics
    }

    // MARK: - Execute

    func execute(groupId: String) async throws {
        // 1. Validate user is authenticated
        guard let user = try await authRepository.currentUser() else {
            throw DomainError.notAuthenticated
        }

        // 2. Check if this is the last member (before removing)
        let members = try await groupRepository.getMembers(groupId: groupId)
        let isLastMember = members.count <= 1

        // 3. Calculate duration in group (for analytics)
        let currentMember = members.first { $0.id == user.id }
        let durationDays: Int
        if let joinedAt = currentMember?.joinedAt {
            durationDays = Calendar.current.dateComponents([.day], from: joinedAt, to: Date()).day ?? 0
        } else {
            durationDays = 0
        }

        // 4. Remove user from group
        try await groupRepository.leaveGroup(groupId: groupId, userId: user.id)

        // 5. Clear user's currentGroupId
        try await userRepository.updateCurrentGroup(user.id, groupId: nil)

        // 6. Track analytics event
        analytics?.trackGroupLeft(groupId: groupId, userId: user.id, durationDays: durationDays)
        analytics?.setUserInGroup(false)
        analytics?.setUserRole(nil)

        // 7. If last member left, auto-delete the group
        if isLastMember {
            try? await groupRepository.deleteGroup(groupId)
            #if DEBUG
            print("[LeaveGroupUseCase] Last member left, group \(groupId) auto-deleted")
            #endif
        }
    }
}
