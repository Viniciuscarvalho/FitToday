//
//  ContinueWorkoutCard.swift
//  FitToday
//
//  Card showing previous/in-progress workout to continue.
//

import SwiftUI

/// Card for displaying a workout that can be continued.
struct ContinueWorkoutCard: View {
    let workoutName: String
    let lastSessionInfo: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Section Label
            Text("home.continue.section_title".localized)
                .font(FitTodayFont.ui(size: 11, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textTertiary)
                .tracking(1)

            // Workout Info Card
            HStack {
                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(workoutName)
                        .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text(lastSessionInfo)
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                Button(action: onContinue) {
                    HStack(spacing: FitTodaySpacing.xs) {
                        Text("home.continue.button".localized)
                            .font(FitTodayFont.ui(size: 13, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, FitTodaySpacing.md)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .background(
                        Capsule()
                            .fill(FitTodayColor.brandPrimary)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(FitTodayColor.outline.opacity(0.5), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ContinueWorkoutCard(
            workoutName: "Treino A - Peito e Tríceps",
            lastSessionInfo: "Último: ontem • Próximo exercício...",
            onContinue: {}
        )
    }
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
