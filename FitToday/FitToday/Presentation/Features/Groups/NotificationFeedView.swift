//
//  NotificationFeedView.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import SwiftUI

// MARK: - NotificationFeedView

struct NotificationFeedView: View {
    @State private var viewModel: NotificationFeedViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: NotificationFeedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.isEmpty {
                loadingView
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                notificationsList
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isEmpty && viewModel.unreadCount > 0 {
                ToolbarItem(placement: .primaryAction) {
                    Button("Mark All Read") {
                        Task {
                            await viewModel.markAllAsRead()
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
        .task {
            await viewModel.loadNotifications()
            await viewModel.startObserving()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading notifications...")
                .font(.subheadline)
                .foregroundStyle(FitTodayColor.textSecondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("No Notifications")
                .font(.headline)
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("When someone joins your group or your rank changes, you'll see it here.")
                .font(.subheadline)
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notificationsList: some View {
        List {
            if !viewModel.todayNotifications.isEmpty {
                Section("Today") {
                    ForEach(viewModel.todayNotifications) { notification in
                        NotificationRowView(notification: notification) {
                            Task {
                                await viewModel.markAsRead(notification)
                            }
                        }
                        .listRowBackground(FitTodayColor.surface)
                    }
                }
            }

            if !viewModel.yesterdayNotifications.isEmpty {
                Section("Yesterday") {
                    ForEach(viewModel.yesterdayNotifications) { notification in
                        NotificationRowView(notification: notification) {
                            Task {
                                await viewModel.markAsRead(notification)
                            }
                        }
                        .listRowBackground(FitTodayColor.surface)
                    }
                }
            }

            if !viewModel.earlierNotifications.isEmpty {
                Section("Earlier") {
                    ForEach(viewModel.earlierNotifications) { notification in
                        NotificationRowView(notification: notification) {
                            Task {
                                await viewModel.markAsRead(notification)
                            }
                        }
                        .listRowBackground(FitTodayColor.surface)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FitTodayColor.background)
    }
}
