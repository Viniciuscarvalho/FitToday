//
//  WorkoutPlanHeader.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Componente extraído para cabeçalho do plano de treino
// Mantém a view principal < 100 linhas seguindo as diretrizes do projeto
struct WorkoutPlanHeader: View {
    let plan: WorkoutPlan
    let timerStore: WorkoutTimerStore
    let onStartWorkout: () -> Void
    let onToggleTimer: () -> Void
    let onViewExercise: () -> Void

    var body: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text(plan.title)
                    .font(FitTodayFont.display(size: 24, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text(plan.focusDescription)
                    .font(FitTodayFont.ui(size: 17, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)

                metadataChips

                actionButtons
            }
        }
    }

    // MARK: - Metadata Chips

    private var metadataChips: some View {
        HStack(spacing: FitTodaySpacing.md) {
            WorkoutMetaChip(
                icon: "clock",
                label: "\(plan.estimatedDurationMinutes) min"
            )
            WorkoutMetaChip(
                icon: "bolt.fill",
                label: plan.intensity.displayTitle
            )

            // Exibe o tempo decorrido se o treino já começou
            if timerStore.hasStarted {
                WorkoutMetaChip(
                    icon: "timer",
                    label: timerStore.formattedTime
                )
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if !timerStore.hasStarted {
            Button("Começar agora", action: onStartWorkout)
                .fitPrimaryStyle()
                .padding(.top, FitTodaySpacing.sm)
        } else {
            HStack(spacing: FitTodaySpacing.sm) {
                Button {
                    onToggleTimer()
                } label: {
                    Label(
                        timerStore.isRunning ? "Pausar" : "Retomar",
                        systemImage: timerStore.isRunning ? "pause.fill" : "play.fill"
                    )
                }
                .fitSecondaryStyle()

                Button("Ver exercício", action: onViewExercise)
                    .fitPrimaryStyle()
            }
            .padding(.top, FitTodaySpacing.sm)
        }
    }
}

// MARK: - Metadata Chip Component

struct WorkoutMetaChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(.footnote, weight: .semibold))
            Text(label)
                .font(FitTodayFont.ui(size: 13, weight: .medium))
        }
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.pill)
    }
}
