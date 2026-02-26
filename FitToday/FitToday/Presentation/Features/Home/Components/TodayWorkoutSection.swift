//
//  TodayWorkoutSection.swift
//  FitToday
//
//  Section showing today's workout exercises on the Home screen.
//

import SwiftUI

struct TodayWorkoutSection: View {
    let workout: ProgramWorkout
    let programName: String?
    let onStartWorkout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Section header
            HStack {
                Text("home.today.title".localized)
                    .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                if let programName {
                    Text(String(format: "home.today.from_program".localized, programName))
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
            .padding(.horizontal, FitTodaySpacing.md)

            // Pro tip
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)

                Text("home.today.pro_tip".localized)
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .lineLimit(2)
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            .padding(.horizontal, FitTodaySpacing.md)

            // Exercise list
            VStack(spacing: FitTodaySpacing.xs) {
                ForEach(workout.exercises.prefix(6)) { exercise in
                    ExercisePreviewRow(
                        exerciseName: exercise.name,
                        imageURL: exercise.imageURL,
                        setsAndReps: exercise.setsRepsDescription,
                        muscleGroup: WgerCategoryMapping.localizedName(
                            for: exercise.wgerExercise.category ?? 0
                        )
                    )
                }

                if workout.exercises.count > 6 {
                    Text("+ \(workout.exercises.count - 6) \("home.today.more_exercises".localized)")
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .padding(.top, FitTodaySpacing.xs)
                }
            }
            .padding(.horizontal, FitTodaySpacing.md)

            // Start workout button
            Button(action: onStartWorkout) {
                Text("home.today.start".localized)
                    .font(FitTodayFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.md)
                    .background(FitTodayColor.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, FitTodaySpacing.md)
        }
    }
}
