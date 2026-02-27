//
//  DailyWorkoutSuggestionCard.swift
//  FitToday
//
//  Card showing the daily workout suggestion with start action.
//

import SwiftUI

struct DailyWorkoutSuggestionCard: View {
    let workoutTitle: String
    let muscleGroups: String
    let duration: String
    let level: String
    let exerciseCount: Int
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Header icon row
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text("Today's Workout")
                    .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Spacer()
            }

            // Workout title
            Text(workoutTitle)
                .font(FitTodayFont.ui(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Muscle groups
            Text(muscleGroups)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)

            // Info badges
            HStack(spacing: FitTodaySpacing.sm) {
                infoBadge(icon: "clock", text: duration)
                infoBadge(icon: "chart.bar", text: level)
                infoBadge(icon: "list.number", text: "\(exerciseCount) exercises")
            }

            // Start button
            Button(action: onStart) {
                HStack(spacing: FitTodaySpacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Start Workout")
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                }
                .foregroundStyle(FitTodayColor.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FitTodayColor.gradientPrimary)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
            }
            .buttonStyle(.plain)
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .stroke(FitTodayColor.outline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func infoBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
        }
        .foregroundStyle(FitTodayColor.textSecondary)
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(FitTodayColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.xs))
    }
}

// MARK: - Preview

#Preview {
    DailyWorkoutSuggestionCard(
        workoutTitle: "Upper Body Power",
        muscleGroups: "Chest, Shoulders, Triceps",
        duration: "45 min",
        level: "Intermediate",
        exerciseCount: 8,
        onStart: {}
    )
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
