//
//  HomeHeader.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//  Redesigned on 23/01/26 - New avatar-based design
//

import SwiftUI

struct HomeHeader: View {
    let greeting: String
    let dateFormatted: String
    let isPro: Bool
    let goalBadgeText: String?
    var userName: String?
    var userPhotoURL: URL?
    var onNotificationTap: (() -> Void)?

    // Computed: first name only for display (nil when no user name)
    private var displayName: String? {
        guard let name = userName, !name.isEmpty else { return nil }
        return name.components(separatedBy: " ").first ?? name
    }

    // Check if user has a name to display
    private var hasUserName: Bool {
        guard let name = userName else { return false }
        return !name.isEmpty
    }

    // Avatar initial from user name or greeting
    private var avatarInitial: String {
        if let name = userName, !name.isEmpty {
            return String(name.prefix(1)).uppercased()
        }
        // For greeting, use first letter of first word
        return String(greeting.prefix(1)).uppercased()
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let photoURL = userPhotoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }

            // Greeting Column
            VStack(alignment: .leading, spacing: 2) {
                if let name = displayName {
                    // Show greeting + name when user is logged in
                    Text(greeting)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    Text(name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                } else {
                    // Show only greeting (larger) when no user name
                    Text(greeting)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }
            }

            Spacer()

            // Notification Button
            Button(action: { onNotificationTap?() }) {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(FitTodayColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.sm)
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(FitTodayColor.gradientPrimary)
                .frame(width: 44, height: 44)

            Text(avatarInitial)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Quick Stats Component

struct HomeQuickStats: View {
    let workoutsThisWeek: Int
    let caloriesBurned: String
    let streakDays: Int

    var body: some View {
        HStack(spacing: 12) {
            statCard(
                label: "home.stats.this_week".localized,
                value: "\(workoutsThisWeek)",
                unit: "home.stats.workouts".localized,
                valueColor: FitTodayColor.textPrimary
            )

            statCard(
                label: "home.stats.calories".localized,
                value: caloriesBurned,
                unit: "home.stats.burned".localized,
                valueColor: FitTodayColor.brandPrimary
            )

            statCard(
                label: "home.stats.streak".localized,
                value: "\(streakDays)",
                unit: "home.stats.days".localized,
                valueColor: FitTodayColor.success
            )
        }
        .padding(.horizontal)
    }

    private func statCard(
        label: String,
        value: String,
        unit: String,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(valueColor)

            Text(unit)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
