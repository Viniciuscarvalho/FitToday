//
//  FirebaseUserRepository.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import Foundation

// MARK: - FirebaseUserRepository

final class FirebaseUserRepository: UserRepository, @unchecked Sendable {
    private let userService: FirebaseUserService

    init(userService: FirebaseUserService = FirebaseUserService()) {
        self.userService = userService
    }

    // MARK: - UserRepository

    func getUser(_ userId: String) async throws -> SocialUser? {
        guard let fbUser = try await userService.getUser(userId) else {
            return nil
        }
        return fbUser.toDomain()
    }

    func updateUser(_ user: SocialUser) async throws {
        let fbUser = user.toFirestore()
        try await userService.updateUser(fbUser)
    }

    func updatePrivacySettings(_ userId: String, settings: PrivacySettings) async throws {
        let fbSettings = FBPrivacySettings(shareWorkoutData: settings.shareWorkoutData)
        try await userService.updatePrivacySettings(userId, settings: fbSettings)
    }

    func updateCurrentGroup(_ userId: String, groupId: String?) async throws {
        try await userService.updateCurrentGroup(userId, groupId: groupId)
    }
}
