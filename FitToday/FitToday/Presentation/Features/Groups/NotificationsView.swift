//
//  NotificationsView.swift
//  FitToday
//
//  Created by Claude on 27/01/26.
//

import SwiftUI
import Swinject

struct NotificationsView: View {
    @Environment(\.dependencyResolver) private var resolver
    @State private var viewModel: NotificationFeedViewModel?
    @State private var dependencyError: String?

    init(resolver: Resolver) {
        if resolver.resolve(FirebaseNotificationService.self) != nil,
           resolver.resolve(AuthenticationRepository.self) != nil {
            _viewModel = State(initialValue: NotificationFeedViewModel(resolver: resolver))
            _dependencyError = State(initialValue: nil)
        } else {
            _viewModel = State(initialValue: nil)
            _dependencyError = State(initialValue: "notifications.error.config".localized)
        }
    }

    var body: some View {
        Group {
            if let error = dependencyError {
                DependencyErrorView(message: error)
            } else if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("notifications.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func contentView(viewModel: NotificationFeedViewModel) -> some View {
        Group {
            if viewModel.isLoading && viewModel.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                notificationsList(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadNotifications()
            await viewModel.startObserving()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
        .toolbar {
            if !viewModel.isEmpty && viewModel.unreadCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("notifications.mark_all_read".localized) {
                        Task { await viewModel.markAllAsRead() }
                    }
                    .font(.system(size: 14))
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            VStack(spacing: FitTodaySpacing.sm) {
                Text("notifications.empty.title".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("notifications.empty.subtitle".localized)
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func notificationsList(viewModel: NotificationFeedViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Today
                if !viewModel.todayNotifications.isEmpty {
                    sectionHeader("notifications.section.today".localized)
                    ForEach(viewModel.todayNotifications) { notification in
                        NotificationRowView(notification: notification) {
                            Task { await viewModel.markAsRead(notification) }
                        }
                        .padding(.horizontal)
                        Divider().padding(.leading, 64)
                    }
                }

                // Yesterday
                if !viewModel.yesterdayNotifications.isEmpty {
                    sectionHeader("notifications.section.yesterday".localized)
                    ForEach(viewModel.yesterdayNotifications) { notification in
                        NotificationRowView(notification: notification) {
                            Task { await viewModel.markAsRead(notification) }
                        }
                        .padding(.horizontal)
                        Divider().padding(.leading, 64)
                    }
                }

                // Earlier
                if !viewModel.earlierNotifications.isEmpty {
                    sectionHeader("notifications.section.earlier".localized)
                    ForEach(viewModel.earlierNotifications) { notification in
                        NotificationRowView(notification: notification) {
                            Task { await viewModel.markAsRead(notification) }
                        }
                        .padding(.horizontal)
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .padding(.bottom, FitTodaySpacing.xl)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(FitTodayColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, FitTodaySpacing.lg)
            .padding(.bottom, FitTodaySpacing.sm)
    }
}

#Preview {
    NavigationStack {
        NotificationsView(resolver: Container())
    }
}
