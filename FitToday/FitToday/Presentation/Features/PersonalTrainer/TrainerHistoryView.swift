//
//  TrainerHistoryView.swift
//  FitToday
//
//  Workout history view grouped by period for trainer-assigned workouts.
//

import SwiftUI

struct TrainerHistoryView: View {
    let workouts: [TrainerWorkout]

    private var thisWeekWorkouts: [TrainerWorkout] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return workouts.filter { $0.createdAt >= weekStart }.sorted { $0.createdAt > $1.createdAt }
    }

    private var lastWeekWorkouts: [TrainerWorkout] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? Date()
        return workouts.filter { $0.createdAt >= lastWeekStart && $0.createdAt < weekStart }.sorted { $0.createdAt > $1.createdAt }
    }

    private var olderWorkouts: [TrainerWorkout] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? Date()
        return workouts.filter { $0.createdAt < lastWeekStart }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            if workouts.isEmpty {
                emptyView
            } else {
                LazyVStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                    if !thisWeekWorkouts.isEmpty {
                        sectionView(title: "trainer.history.this_week".localized, workouts: thisWeekWorkouts)
                    }

                    if !lastWeekWorkouts.isEmpty {
                        sectionView(title: "trainer.history.last_week".localized, workouts: lastWeekWorkouts)
                    }

                    if !olderWorkouts.isEmpty {
                        sectionView(title: "trainer.history.older".localized, workouts: olderWorkouts)
                    }
                }
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.vertical, FitTodaySpacing.sm)
            }
        }
        .scrollIndicators(.hidden)
        .background(FitTodayColor.background)
    }

    // MARK: - Section

    private func sectionView(title: String, workouts: [TrainerWorkout]) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text(title)
                .font(FitTodayFont.ui(size: 16, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            ForEach(workouts) { workout in
                WorkoutHistoryCard(workout: workout)
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("trainer.history.empty".localized)
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("trainer.history.empty_message".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, FitTodaySpacing.xxl)
    }
}
