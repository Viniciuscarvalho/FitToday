//
//  NotificationFeedViewModel.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation
import Swinject

// MARK: - NotificationFeedViewModel

@MainActor
@Observable
final class NotificationFeedViewModel {

    // MARK: - Published Properties

    private(set) var notifications: [GroupNotification] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Computed Properties

    var todayNotifications: [GroupNotification] {
        notifications.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    var yesterdayNotifications: [GroupNotification] {
        notifications.filter { Calendar.current.isDateInYesterday($0.createdAt) }
    }

    var earlierNotifications: [GroupNotification] {
        notifications.filter {
            !Calendar.current.isDateInToday($0.createdAt) &&
            !Calendar.current.isDateInYesterday($0.createdAt)
        }
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var isEmpty: Bool {
        notifications.isEmpty
    }

    // MARK: - Dependencies

    private let notificationRepository: FirebaseNotificationRepository
    private let authRepository: AuthenticationRepository
    nonisolated(unsafe) private var observationTask: Task<Void, Never>?

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.notificationRepository = FirebaseNotificationRepository(
            notificationService: resolver.resolve(FirebaseNotificationService.self)!
        )
        self.authRepository = resolver.resolve(AuthenticationRepository.self)!
    }

    // For previews/testing
    init(
        notificationRepository: FirebaseNotificationRepository,
        authRepository: AuthenticationRepository
    ) {
        self.notificationRepository = notificationRepository
        self.authRepository = authRepository
    }

    // MARK: - Public Methods

    func loadNotifications() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            guard let user = try await authRepository.currentUser() else {
                isLoading = false
                return
            }

            notifications = try await notificationRepository.getNotifications(userId: user.id)
        } catch {
            self.error = error
            #if DEBUG
            print("[NotificationFeedViewModel] Failed to load notifications: \(error)")
            #endif
        }

        isLoading = false
    }

    func startObserving() async {
        guard let user = try? await authRepository.currentUser() else { return }

        observationTask?.cancel()
        observationTask = Task {
            for await updatedNotifications in notificationRepository.observeNotifications(userId: user.id) {
                self.notifications = updatedNotifications
            }
        }
    }

    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }

    func markAsRead(_ notification: GroupNotification) async {
        guard !notification.isRead else { return }

        do {
            try await notificationRepository.markAsRead(notification.id)

            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                var updated = notifications[index]
                updated.isRead = true
                notifications[index] = updated
            }
        } catch {
            #if DEBUG
            print("[NotificationFeedViewModel] Failed to mark as read: \(error)")
            #endif
        }
    }

    func markAllAsRead() async {
        guard let user = try? await authRepository.currentUser() else { return }

        do {
            try await notificationRepository.markAllAsRead(userId: user.id)

            // Update local state
            notifications = notifications.map { notification in
                var updated = notification
                updated.isRead = true
                return updated
            }
        } catch {
            #if DEBUG
            print("[NotificationFeedViewModel] Failed to mark all as read: \(error)")
            #endif
        }
    }
}
