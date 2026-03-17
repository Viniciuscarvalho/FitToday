//
//  FirebaseBadgeRepository.swift
//  FitToday
//

import FirebaseFirestore
import Foundation

final class FirebaseBadgeRepository: BadgeRepository, @unchecked Sendable {
    private let db = Firestore.firestore()
    private let authService: FirebaseAuthService

    init(authService: FirebaseAuthService = FirebaseAuthService()) {
        self.authService = authService
    }

    // MARK: - BadgeRepository

    func getUserBadges(userId: String) async throws -> [Badge] {
        let snapshot = try await badgesCollection(userId: userId).getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: FBBadge.self).toDomain()
        }
    }

    func saveBadge(_ badge: Badge, userId: String) async throws {
        let fbBadge = FBBadge.fromDomain(badge)
        try badgesCollection(userId: userId)
            .document(badge.type.rawValue)
            .setData(from: fbBadge)
    }

    func updateBadgeVisibility(_ badgeId: String, isPublic: Bool, userId: String) async throws {
        try await badgesCollection(userId: userId)
            .document(badgeId)
            .updateData(["isPublic": isPublic])
    }

    // MARK: - Private

    private func badgesCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("badges")
    }
}
