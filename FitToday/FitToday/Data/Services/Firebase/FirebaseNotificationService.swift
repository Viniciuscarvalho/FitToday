//
//  FirebaseNotificationService.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import FirebaseFirestore
import Foundation

// MARK: - FirebaseNotificationService

actor FirebaseNotificationService {
    private let db = Firestore.firestore()
    private let collectionName = "notifications"

    // MARK: - Fetch Notifications

    /// Fetches notifications for a user, limited to the last 7 days.
    func fetchNotifications(userId: String) async throws -> [FBNotification] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .whereField("createdAt", isGreaterThan: Timestamp(date: sevenDaysAgo))
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: FBNotification.self)
        }
    }

    // MARK: - Observe Notifications (Real-Time)

    func observeNotifications(userId: String) -> AsyncStream<[FBNotification]> {
        AsyncStream { continuation in
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

            let listener = db.collection(collectionName)
                .whereField("userId", isEqualTo: userId)
                .whereField("createdAt", isGreaterThan: Timestamp(date: sevenDaysAgo))
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else {
                        return
                    }

                    let notifications = documents.compactMap { doc in
                        try? doc.data(as: FBNotification.self)
                    }

                    continuation.yield(notifications)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Mark as Read

    func markAsRead(notificationId: String) async throws {
        try await db.collection(collectionName)
            .document(notificationId)
            .updateData(["isRead": true])
    }

    // MARK: - Mark All as Read

    func markAllAsRead(userId: String) async throws {
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }

        try await batch.commit()
    }

    // MARK: - Create Notification

    func createNotification(
        userId: String,
        groupId: String,
        type: NotificationType,
        message: String
    ) async throws {
        let notification = FBNotification(
            id: nil,
            userId: userId,
            groupId: groupId,
            type: type.rawValue,
            message: message,
            isRead: false,
            createdAt: nil // ServerTimestamp
        )

        _ = try await db.collection(collectionName).addDocument(from: notification)
    }

    // MARK: - Get Unread Count

    func getUnreadCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .count
            .getAggregation(source: .server)

        return Int(truncating: snapshot.count)
    }
}
