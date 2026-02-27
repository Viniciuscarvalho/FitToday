//
//  ExercisePreviewRow.swift
//  FitToday
//
//  Row displaying an exercise preview with image, name, and sets/reps badge.
//

import SwiftUI

struct ExercisePreviewRow: View {
    let exerciseName: String
    let imageURL: URL?
    let setsAndReps: String
    let muscleGroup: String?

    private let imageSize: CGFloat = 48

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Exercise image
            CachedAsyncImage(
                url: imageURL,
                placeholder: Image(systemName: "dumbbell.fill"),
                size: CGSize(width: imageSize, height: imageSize)
            )
            .frame(width: imageSize, height: imageSize)
            .background(FitTodayColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))

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
            imageURL: nil,
            setsAndReps: "3 x 12",
            muscleGroup: "Chest"
        )
        ExercisePreviewRow(
            exerciseName: "Running",
            imageURL: nil,
            setsAndReps: "20 min",
            muscleGroup: nil
        )
        ExercisePreviewRow(
            exerciseName: "Lateral Raise",
            imageURL: nil,
            setsAndReps: "4 x 15",
            muscleGroup: "Shoulders"
        )
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
