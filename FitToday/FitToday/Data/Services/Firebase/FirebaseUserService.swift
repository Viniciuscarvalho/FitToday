//
//  FirebaseUserService.swift
//  FitToday
//
//  Created by Claude on 16/01/26.
//

import FirebaseFirestore
import Foundation

// MARK: - FirebaseUserService

actor FirebaseUserService {
    private let db = Firestore.firestore()

    // MARK: - Get User

    func getUser(_ userId: String) async throws -> FBUser? {
        let snapshot = try await db.collection("users").document(userId).getDocument()

        guard snapshot.exists else {
            return nil
        }

        return try snapshot.data(as: FBUser.self)
    }

    // MARK: - Update User

    func updateUser(_ user: FBUser) async throws {
        guard let userId = user.id else {
            throw NSError(
                domain: "FirebaseUserService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "User ID is required"]
            )
        }

        try await db.collection("users").document(userId).setData(from: user, merge: true)
    }

    // MARK: - Update Privacy Settings

    func updatePrivacySettings(_ userId: String, settings: FBPrivacySettings) async throws {
        try await db.collection("users").document(userId).updateData([
            "privacySettings": [
                "shareWorkoutData": settings.shareWorkoutData
            ]
        ])
    }

    // MARK: - Update Current Group

    func updateCurrentGroup(_ userId: String, groupId: String?) async throws {
        if let groupId = groupId {
            try await db.collection("users").document(userId).updateData([
                "currentGroupId": groupId
            ])
        } else {
            // Remove field if nil
            try await db.collection("users").document(userId).updateData([
                "currentGroupId": FieldValue.delete()
            ])
        }
    }
}
