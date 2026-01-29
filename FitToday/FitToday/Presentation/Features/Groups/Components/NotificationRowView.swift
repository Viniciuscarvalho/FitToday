//
//  NotificationRowView.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import SwiftUI

// MARK: - NotificationRowView

struct NotificationRowView: View {
    let notification: GroupNotification
    var onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Icon based on notification type
            notificationIcon
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(notification.isRead ? FitTodayColor.textSecondary : FitTodayColor.textPrimary)
                    .lineLimit(2)

                Text(timeAgoText)
                    .font(.caption)
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            Spacer()

            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(FitTodayColor.brandPrimary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    // MARK: - Computed Views

    @ViewBuilder
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)

            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconForegroundColor)
        }
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch notification.type {
        case .newMember:
            return "person.badge.plus"
        case .rankChange:
            return "chart.line.uptrend.xyaxis"
        case .weekEnded:
            return "flag.checkered"
        }
    }

    private var iconBackgroundColor: Color {
        switch notification.type {
        case .newMember:
            return FitTodayColor.brandPrimary.opacity(0.2)
        case .rankChange:
            return Color.orange.opacity(0.2)
        case .weekEnded:
            return Color.purple.opacity(0.2)
        }
    }

    private var iconForegroundColor: Color {
        switch notification.type {
        case .newMember:
            return FitTodayColor.brandPrimary
        case .rankChange:
            return Color.orange
        case .weekEnded:
            return Color.purple
        }
    }

    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    VStack {
        NotificationRowView(
            notification: GroupNotification(
                id: "1",
                userId: "user1",
                groupId: "group1",
                type: .newMember,
                message: "John joined your group!",
                isRead: false,
                createdAt: Date()
            )
        )

        NotificationRowView(
            notification: GroupNotification(
                id: "2",
                userId: "user1",
                groupId: "group1",
                type: .rankChange,
                message: "You moved up to #2 in Check-ins!",
                isRead: true,
                createdAt: Date().addingTimeInterval(-3600)
            )
        )

        NotificationRowView(
            notification: GroupNotification(
                id: "3",
                userId: "user1",
                groupId: "group1",
                type: .weekEnded,
                message: "Week ended! See the final standings.",
                isRead: false,
                createdAt: Date().addingTimeInterval(-86400)
            )
        )
    }
    .padding()
    .background(FitTodayColor.background)
}
