//
//  WorkoutHistoryCard.swift
//  FitToday
//
//  Card displaying a trainer-assigned workout with exercises and completion status.
//

import SwiftUI

struct WorkoutHistoryCard: View {
    let workout: TrainerWorkout

    private var exerciseItems: [TrainerWorkoutItem] {
        workout.phases.flatMap { $0.items }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text(workout.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                statusBadge
            }

            // Exercise List
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                ForEach(Array(exerciseItems.prefix(4).enumerated()), id: \.offset) { _, item in
                    exerciseRow(item)
                }

                if exerciseItems.count > 4 {
                    Text("trainer.history.more_exercises".localized(with: exerciseItems.count - 4))
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        let isCompleted = !workout.isActive
        return Text(isCompleted ? "trainer.history.completed".localized : "trainer.history.not_completed".localized)
            .font(FitTodayFont.ui(size: 11, weight: .semiBold))
            .foregroundStyle(isCompleted ? FitTodayColor.success : FitTodayColor.warning)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isCompleted ? FitTodayColor.success : FitTodayColor.warning).opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ item: TrainerWorkoutItem) -> some View {
        HStack(spacing: FitTodaySpacing.sm) {
            Circle()
                .fill(FitTodayColor.brandPrimary)
                .frame(width: 6, height: 6)

            Text(item.exerciseName)
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .lineLimit(1)

            Spacer()

            Text("\(item.sets)x\(item.reps.lowerBound)-\(item.reps.upperBound)")
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }
}
