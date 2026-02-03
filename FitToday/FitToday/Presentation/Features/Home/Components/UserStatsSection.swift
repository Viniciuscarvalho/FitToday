//
//  UserStatsSection.swift
//  FitToday
//
//  Section displaying user weekly stats from workout history.
//

import SwiftUI

/// Section displaying weekly stats from workout history and Apple Health.
struct UserStatsSection: View {
    let workoutsThisWeek: Int
    let caloriesBurnedFormatted: String
    let streakDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("home.stats.title".localized)
                .font(FitTodayFont.ui(size: 11, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)
                .tracking(1)

            HStack(spacing: FitTodaySpacing.md) {
                // Workouts this week
                StatCard(
                    value: "\(workoutsThisWeek)",
                    label: "home.stats.workouts".localized,
                    icon: "figure.strengthtraining.traditional",
                    color: FitTodayColor.brandPrimary
                )

                // Calories burned
                StatCard(
                    value: caloriesBurnedFormatted,
                    label: "home.stats.calories".localized,
                    icon: "flame.fill",
                    color: .orange
                )

                // Streak (only show if > 0)
                if streakDays > 0 {
                    StatCard(
                        value: "\(streakDays)",
                        label: "home.stats.streak".localized,
                        icon: "bolt.fill",
                        color: FitTodayColor.warning
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        UserStatsSection(
            workoutsThisWeek: 4,
            caloriesBurnedFormatted: "1.2k",
            streakDays: 5
        )

        UserStatsSection(
            workoutsThisWeek: 0,
            caloriesBurnedFormatted: "0",
            streakDays: 0
        )
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
