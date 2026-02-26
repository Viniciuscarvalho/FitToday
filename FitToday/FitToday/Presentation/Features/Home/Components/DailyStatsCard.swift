//
//  DailyStatsCard.swift
//  FitToday
//
//  Summary card displaying the user's daily workout statistics.
//

import SwiftUI

struct DailyStatsCard: View {
    let workoutsThisWeek: Int
    let caloriesBurned: String
    let streakDays: Int

    var body: some View {
        HStack(spacing: FitTodaySpacing.lg) {
            // Activity icon with gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                )

            // Stats summary
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                statRow(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(workoutsThisWeek)",
                    label: "home.stats.workouts".localized,
                    sublabel: "home.stats.this_week".localized
                )

                statRow(
                    icon: "bolt.fill",
                    value: caloriesBurned,
                    label: "home.stats.calories".localized,
                    sublabel: "home.stats.burned".localized
                )

                statRow(
                    icon: "flame",
                    value: "\(streakDays)",
                    label: "home.stats.days".localized,
                    sublabel: "home.stats.streak".localized
                )
            }

            Spacer()
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .stroke(FitTodayColor.outline.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func statRow(icon: String, value: String, label: String, sublabel: String) -> some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 16)

            Text(value)
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("\(label) \(sublabel)")
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    VStack {
        DailyStatsCard(
            workoutsThisWeek: 3,
            caloriesBurned: "1.2k",
            streakDays: 20
        )
    }
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
