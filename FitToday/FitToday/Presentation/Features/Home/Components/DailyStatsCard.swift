//
//  DailyStatsCard.swift
//  FitToday
//
//  Summary card displaying workout stats with progress ring and stat pills.
//

import SwiftUI

struct DailyStatsCard: View {
    let workoutsThisWeek: Int
    let weeklyTarget: Int
    let caloriesBurned: String
    let streakDays: Int
    let totalSets: Int
    let avgDuration: Int

    private var progress: Double {
        guard weeklyTarget > 0 else { return 0 }
        return min(Double(workoutsThisWeek) / Double(weeklyTarget), 1.0)
    }

    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            // Top row: progress ring + streak
            HStack(spacing: FitTodaySpacing.lg) {
                // Progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(FitTodayColor.surfaceElevated, lineWidth: 8)
                        .frame(width: 80, height: 80)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    // Center text
                    VStack(spacing: 0) {
                        Text("\(workoutsThisWeek)/\(weeklyTarget)")
                            .font(FitTodayFont.ui(size: 20, weight: .bold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                    }
                }

                // Labels + streak
                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    Text("home.stats.workouts_week".localized)
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    HStack(spacing: FitTodaySpacing.xs) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                        Text("\(streakDays)")
                            .font(FitTodayFont.ui(size: 20, weight: .bold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                        Text("home.stats.day_streak".localized)
                            .font(FitTodayFont.ui(size: 14, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }

                Spacer()
            }

            // Bottom row: stat pills
            HStack(spacing: FitTodaySpacing.sm) {
                statPill(icon: "bolt.fill", value: caloriesBurned, label: "cal")
                statPill(icon: "figure.strengthtraining.traditional", value: "\(totalSets)", label: "home.stats.total_sets".localized)
                statPill(icon: "clock.fill", value: "\(avgDuration)", label: "home.stats.avg_duration".localized)
            }
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

    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text(value)
                .font(FitTodayFont.ui(size: 14, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(label)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(FitTodayColor.surfaceElevated)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack {
        DailyStatsCard(
            workoutsThisWeek: 3,
            weeklyTarget: 4,
            caloriesBurned: "1.2k",
            streakDays: 20,
            totalSets: 32,
            avgDuration: 45
        )
    }
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
