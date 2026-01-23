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

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(FitTodayColor.gradientPrimary)
                    .frame(width: 44, height: 44)

                Text(String(greeting.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Greeting Column
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(FitTodayColor.textSecondary)

                Text(greeting)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)
            }

            Spacer()

            // Notification Button
            Button(action: {}) {
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
}

// MARK: - Quick Stats Component

struct HomeQuickStats: View {
    let workoutsThisWeek: Int
    let caloriesBurned: String
    let streakDays: Int

    var body: some View {
        HStack(spacing: 12) {
            statCard(
                label: "This Week",
                value: "\(workoutsThisWeek)",
                unit: "workouts",
                valueColor: FitTodayColor.textPrimary
            )

            statCard(
                label: "Calories",
                value: caloriesBurned,
                unit: "burned",
                valueColor: FitTodayColor.brandPrimary
            )

            statCard(
                label: "Streak",
                value: "\(streakDays)",
                unit: "days",
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
