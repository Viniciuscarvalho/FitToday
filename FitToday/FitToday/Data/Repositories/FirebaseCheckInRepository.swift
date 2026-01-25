//
//  FirebaseCheckInRepository.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import FirebaseFirestore
import Foundation

// MARK: - FirebaseCheckInRepository

/// Repository for managing check-ins using Firestore and Firebase Storage.
/// Thread-safe implementation using actor isolation.
actor FirebaseCheckInRepository: CheckInRepository {
    private let db = Firestore.firestore()
    private let storageService: StorageServicing

    // MARK: - Constants

    private enum Constants {
        static let groupsCollection = "groups"
        static let checkInsCollection = "checkIns"
        static let storagePath = "checkIns"
        static let defaultLimit = 50
    }

    // MARK: - Init

    init(storageService: StorageServicing) {
        self.storageService = storageService
    }

    // MARK: - CheckInRepository

    func createCheckIn(_ checkIn: CheckIn) async throws {
        let ref = db.collection(Constants.groupsCollection)
            .document(checkIn.groupId)
            .collection(Constants.checkInsCollection)
            .document(checkIn.id)

        let fbCheckIn = FBCheckIn(from: checkIn)
        try await ref.setData(from: fbCheckIn)
    }

    func getCheckIns(groupId: String, limit: Int, after: Date?) async throws -> [CheckIn] {
        var query = db.collection(Constants.groupsCollection)
            .document(groupId)
            .collection(Constants.checkInsCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let after = after {
            query = query.whereField("createdAt", isLessThan: Timestamp(date: after))
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap {
            try? $0.data(as: FBCheckIn.self).toDomain()
        }
    }

    func observeCheckIns(groupId: String) -> AsyncStream<[CheckIn]> {
        AsyncStream { continuation in
            let listener = db.collection(Constants.groupsCollection)
                .document(groupId)
                .collection(Constants.checkInsCollection)
                .order(by: "createdAt", descending: true)
                .limit(to: Constants.defaultLimit)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Error observing check-ins: \(error.localizedDescription)")
                        return
                    }

                    guard let docs = snapshot?.documents else { return }

                    let checkIns = docs.compactMap {
                        try? $0.data(as: FBCheckIn.self).toDomain()
                    }
                    continuation.yield(checkIns)
                }

            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
    }

    func uploadPhoto(imageData: Data, groupId: String, userId: String) async throws -> URL {
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "\(Constants.storagePath)/\(groupId)/\(userId)/\(timestamp).jpg"
        return try await storageService.uploadImage(data: imageData, path: path)
    }
}
