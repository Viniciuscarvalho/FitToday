//
//  ExercisePreviewRow.swift
//  FitToday
//
//  Row displaying an exercise preview with image, name, and sets/reps badge.
//

import SwiftUI

struct ExercisePreviewRow: View {
    let exerciseName: String
    let exerciseId: String?
    let setsAndReps: String
    let muscleGroup: String?

    private let imageSize: CGFloat = 48

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Exercise image from Firebase Storage
            if let exerciseId {
                ExerciseImageView(exerciseId: exerciseId, imageIndex: 0, cornerRadius: FitTodayRadius.sm)
                    .frame(width: imageSize, height: imageSize)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .fill(FitTodayColor.surfaceElevated)
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
                .frame(width: imageSize, height: imageSize)
            }

            // Name and muscle group
            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseName)
                    .font(FitTodayFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)

                if let muscleGroup {
                    Text(muscleGroup)
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }

            Spacer()

            // Sets and reps badge
            Text(setsAndReps)
                .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.vertical, FitTodaySpacing.xs)
                .background(FitTodayColor.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.xs))
        }
        .padding(FitTodaySpacing.sm)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        ExercisePreviewRow(
            exerciseName: "Bench Press",
            exerciseId: nil,
            setsAndReps: "3 x 12",
            muscleGroup: "Chest"
        )
        ExercisePreviewRow(
            exerciseName: "Running",
            exerciseId: nil,
            setsAndReps: "20 min",
            muscleGroup: nil
        )
        ExercisePreviewRow(
            exerciseName: "Lateral Raise",
            exerciseId: nil,
            setsAndReps: "4 x 15",
            muscleGroup: "Shoulders"
        )
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
