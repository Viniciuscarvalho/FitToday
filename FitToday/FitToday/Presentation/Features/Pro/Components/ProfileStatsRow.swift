//
//  ProfileStatsRow.swift
//  FitToday
//

import SwiftUI

/// A row of 3 key profile stats: streak, total minutes, and completed workouts.
struct ProfileStatsRow: View {
    let streak: Int
    let totalMinutes: Int
    let completedWorkouts: Int

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            statCell(icon: "flame.fill", value: "\(streak)", label: "days")
            statCell(icon: "clock.fill", value: "\(totalMinutes)", label: "min")
            statCell(icon: "checkmark.circle.fill", value: "\(completedWorkouts)", label: "workouts")
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
        )
    }

    // MARK: - Stat Cell

    private func statCell(icon: String, value: String, label: String) -> some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text(value)
                .font(FitTodayFont.ui(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(label)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ProfileStatsRow(
        streak: 12,
        totalMinutes: 480,
        completedWorkouts: 34
    )
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
