//
//  WeeksWorkoutSection.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Seção "Treinos da Semana" com lista de workouts
// Componente extraído para manter a view principal < 100 linhas
struct WeeksWorkoutSection: View {
    let workouts: [LibraryWorkout]
    let onWorkoutTap: (LibraryWorkout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(
                title: "Treinos da Semana",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal)

            if workouts.isEmpty {
                emptyState
            } else {
                workoutsList
            }
        }
        .padding(.top, FitTodaySpacing.lg)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(.largeTitle))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text("Nenhum treino disponível")
                .font(FitTodayFont.ui(size: 15, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FitTodaySpacing.xl)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .padding(.horizontal)
    }

    private var workoutsList: some View {
        LazyVStack(spacing: FitTodaySpacing.sm) {
            ForEach(workouts) { workout in
                WorkoutCardCompact(workout: workout) {
                    onWorkoutTap(workout)
                }
            }
        }
        .padding(.horizontal)
    }
}
