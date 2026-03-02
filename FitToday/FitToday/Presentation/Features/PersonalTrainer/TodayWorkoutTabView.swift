//
//  TodayWorkoutTabView.swift
//  FitToday
//
//  "Hoje" tab in the TrainerDashboard — shows today's workout from the personal trainer.
//

import SwiftUI

struct TodayWorkoutTabView: View {
    let workouts: [TrainerWorkout]
    let onViewHistory: () -> Void

    @Environment(AppRouter.self) private var router

    private var todayWorkout: TrainerWorkout? {
        workouts.first { workout in
            guard let scheduledDate = workout.schedule.scheduledDate else { return false }
            return Calendar.current.isDateInToday(scheduledDate)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                if let workout = todayWorkout {
                    workoutAvailableView(workout)
                } else {
                    emptyStateView
                }
            }
            .padding(FitTodaySpacing.md)
        }
        .background(FitTodayColor.background)
    }

    // MARK: - Workout Available

    private func workoutAvailableView(_ workout: TrainerWorkout) -> some View {
        VStack(spacing: FitTodaySpacing.lg) {
            // Workout header card
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                HStack(spacing: FitTodaySpacing.sm) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(FitTodayColor.brandPrimary)

                    Text("Treino de Hoje")
                        .font(FitTodayFont.ui(size: 20, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }

                Text(workout.title)
                    .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                if let description = workout.description, !description.isEmpty {
                    Text(description)
                        .font(FitTodayFont.ui(size: 14, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                // Info chips
                HStack(spacing: FitTodaySpacing.sm) {
                    infoChip(icon: "clock", text: "\(workout.estimatedDurationMinutes) min")
                    infoChip(icon: "flame", text: workout.intensity.displayName)
                    infoChip(icon: "target", text: workout.focus.displayName)
                }

                if let scheduledDate = workout.schedule.scheduledDate {
                    Text("Enviado \(scheduledDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(FitTodaySpacing.lg)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))

            // View workout detail button
            Button {
                router.push(.cmsWorkoutDetail(workout.id), on: .home)
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Ver treino completo")
                }
            }
            .fitPrimaryStyle()

            // Exercises preview
            if !workout.phases.isEmpty {
                exercisesPreview(workout)
            }
        }
    }

    // MARK: - Exercises Preview

    private func exercisesPreview(_ workout: TrainerWorkout) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("Exercícios")
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.xs)

            ForEach(Array(workout.phases.enumerated()), id: \.offset) { _, phase in
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(phase.name)
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                        .padding(.horizontal, FitTodaySpacing.xs)

                    ForEach(Array(phase.items.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: FitTodaySpacing.md) {
                            Text("\(index + 1)")
                                .font(FitTodayFont.ui(size: 13, weight: .bold))
                                .foregroundStyle(FitTodayColor.brandPrimary)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(FitTodayColor.brandPrimary.opacity(0.15)))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.exerciseName)
                                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                    .lineLimit(1)

                                Text("\(item.sets) x \(item.reps.display)")
                                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                                    .foregroundStyle(FitTodayColor.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, FitTodaySpacing.md)
                        .padding(.vertical, FitTodaySpacing.sm)
                        .background(FitTodayColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Spacer()
                .frame(height: FitTodaySpacing.xxl)

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundStyle(FitTodayColor.textSecondary.opacity(0.5))

            Text("Nenhum treino para hoje")
                .font(FitTodayFont.ui(size: 20, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Seu personal ainda não enviou o treino de hoje.")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                onViewHistory()
            } label: {
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Ver treinos anteriores")
                }
            }
            .fitSecondaryStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(FitTodaySpacing.lg)
    }

    // MARK: - Helpers

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
        }
        .foregroundStyle(FitTodayColor.textSecondary)
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, 6)
        .background(FitTodayColor.background)
        .clipShape(Capsule())
    }
}
