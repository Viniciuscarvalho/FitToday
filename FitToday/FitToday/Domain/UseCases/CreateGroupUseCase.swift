//
//  CreateGroupUseCase.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation

// MARK: - CreateGroupUseCase

struct CreateGroupUseCase: Sendable {
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

    func execute(name: String) async throws -> SocialGroup {
        // 1. Validate user is authenticated
        guard let user = try await authRepository.currentUser() else {
            throw DomainError.notAuthenticated
        }

        // 2. Validate user NOT already in a group (MVP: 1-group limit)
        guard user.currentGroupId == nil else {
            throw DomainError.alreadyInGroup
        }

        // 3. Create group with user as owner
        let group = try await groupRepository.createGroup(name: name, ownerId: user.id)

        // 4. Update user's currentGroupId
        try await userRepository.updateCurrentGroup(user.id, groupId: group.id)

        // 5. Update group member with actual user info (display name and photo)
        try await groupRepository.addMember(
            groupId: group.id,
            userId: user.id,
            displayName: user.displayName,
            photoURL: user.photoURL
        )

        // 6. Track analytics event
        analytics?.trackGroupCreated(groupId: group.id, userId: user.id)
        analytics?.setUserInGroup(true)
        analytics?.setUserRole(.admin)

        return group
    }
}
