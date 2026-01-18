//
//  FirebaseNotificationRepository.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation

// MARK: - FirebaseNotificationRepository

struct FirebaseNotificationRepository: NotificationRepository, Sendable {
    private let notificationService: FirebaseNotificationService

    init(notificationService: FirebaseNotificationService) {
        self.notificationService = notificationService
    }

    // MARK: - NotificationRepository

    func getNotifications(userId: String) async throws -> [GroupNotification] {
        let fbNotifications = try await notificationService.fetchNotifications(userId: userId)
        return fbNotifications.map { $0.toDomain() }
    }

    func observeNotifications(userId: String) -> AsyncStream<[GroupNotification]> {
        AsyncStream { continuation in
            Task {
                for await fbNotifications in notificationService.observeNotifications(userId: userId) {
                    let notifications = fbNotifications.map { $0.toDomain() }
                    continuation.yield(notifications)
                }
            }
        }
    }

    func markAsRead(_ notificationId: String) async throws {
        try await notificationService.markAsRead(notificationId: notificationId)
    }

    func createNotification(_ notification: GroupNotification) async throws {
        try await notificationService.createNotification(
            userId: notification.userId,
            groupId: notification.groupId,
            type: notification.type,
            message: notification.message
        )
    }

    // MARK: - Extended Methods

    func markAllAsRead(userId: String) async throws {
        try await notificationService.markAllAsRead(userId: userId)
    }

    func getUnreadCount(userId: String) async throws -> Int {
        try await notificationService.getUnreadCount(userId: userId)
    }
}
