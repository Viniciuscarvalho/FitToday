//
//  ExerciseCard.swift
//  FitToday
//
//  Created by Claude on 03/03/26.
//

import SwiftUI

/// Card displaying an exercise with animated image, name, sets, reps, and rest.
/// Uses ExerciseAnimatedView for the image area.
struct ExerciseCard: View {
    let exerciseId: String
    let name: String
    let sets: Int
    let reps: String
    let restSeconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Animated image area
            ExerciseAnimatedView(exerciseId: exerciseId, cornerRadius: 12)
                .frame(height: 200)
                .clipped()

            // Exercise info
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(name)
                    .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(2)

                HStack(spacing: FitTodaySpacing.md) {
                    Label("\(sets) séries", systemImage: "repeat")
                    Label("\(reps) reps", systemImage: "arrow.up.arrow.down")
                    Label("\(restSeconds)s", systemImage: "timer")
                }
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
            }
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.bottom, FitTodaySpacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FitTodayColor.surface)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
