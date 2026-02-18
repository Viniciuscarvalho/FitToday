//
//  TodayWorkoutCard.swift
//  FitToday
//
//  Card showing the user's generated workout of the day for re-viewing.
//

import SwiftUI

struct TodayWorkoutCard: View {
    let workout: GeneratedWorkout
    let onViewWorkout: () -> Void
    let onStartWorkout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text("home.today_workout.title".localized)
                    .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Spacer()
                Text("home.today_workout.generated".localized)
                    .font(FitTodayFont.ui(size: 11, weight: .medium))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }

            // Workout Info
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(workout.name)
                    .font(FitTodayFont.ui(size: 18, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                HStack(spacing: FitTodaySpacing.md) {
                    Label("\(workout.exerciseCount)", systemImage: "figure.strengthtraining.traditional")
                    Label("\(workout.estimatedDuration) min", systemImage: "clock")
                    Label("\(workout.totalSets) sets", systemImage: "repeat")
                }
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
            }

            // Actions
            HStack(spacing: FitTodaySpacing.sm) {
                Button(action: onViewWorkout) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.system(size: 12, weight: .semibold))
                        Text("home.today_workout.view".localized)
                            .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    }
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(FitTodayColor.brandPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: onStartWorkout) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("home.today_workout.start".localized)
                            .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(FitTodayColor.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .stroke(FitTodayColor.brandPrimary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
