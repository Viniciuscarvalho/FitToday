//
//  SavedRoutineCard.swift
//  FitToday
//
//  Card component for displaying a saved routine in "Minhas Rotinas" section.
//

import SwiftUI

/// Card displaying a saved routine with swipe-to-delete functionality.
struct SavedRoutineCard: View {
    let routine: SavedRoutine
    let onDelete: () async -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Icon
            goalIcon
                .frame(width: 48, height: 48)

            // Info
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(routine.name)
                    .font(FitTodayFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .lineLimit(1)

                Text(routine.subtitle)
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .lineLimit(1)

                // Stats row
                HStack(spacing: FitTodaySpacing.md) {
                    statItem(icon: "figure.strengthtraining.traditional", text: "\(routine.workoutCount) treinos")
                    statItem(icon: "calendar", text: routine.sessionsDescription)
                }
            }

            Spacer()

            // Level badge
            levelBadge
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(goalColor.opacity(0.3), lineWidth: 1)
                )
        )
        .techCornerBorders(color: goalColor.opacity(0.4))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Remover", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "routine.delete.confirm".localized,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remover", role: .destructive) {
                Task {
                    await onDelete()
                }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Subviews

    private var goalIcon: some View {
        ZStack {
            Circle()
                .fill(goalColor.opacity(0.2))

            Image(systemName: routine.goalTag.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(goalColor)
        }
    }

    private var levelBadge: some View {
        Text(routine.level.displayName)
            .font(FitTodayFont.ui(size: 11, weight: .semiBold))
            .foregroundStyle(levelColor)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(levelColor.opacity(0.15))
            )
    }

    private func statItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(FitTodayColor.textTertiary)

            Text(text)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
    }

    // MARK: - Colors

    private var goalColor: Color {
        switch routine.goalTag {
        case .strength:
            return FitTodayColor.brandPrimary
        case .conditioning:
            return FitTodayColor.error
        case .aerobic:
            return FitTodayColor.success
        case .core:
            return FitTodayColor.warning
        case .endurance:
            return FitTodayColor.brandSecondary
        }
    }

    private var levelColor: Color {
        switch routine.level {
        case .beginner:
            return FitTodayColor.success
        case .intermediate:
            return FitTodayColor.warning
        case .advanced:
            return FitTodayColor.error
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SavedRoutineCard(
            routine: SavedRoutine(
                programId: "ppl_intermediate",
                name: "Push Pull Legs",
                subtitle: "Programa clássico de divisão muscular",
                goalTag: .strength,
                level: .intermediate,
                equipment: .gym,
                workoutCount: 6,
                sessionsPerWeek: 6,
                durationWeeks: 8
            ),
            onDelete: {}
        )

        SavedRoutineCard(
            routine: SavedRoutine(
                programId: "hiit_beginner",
                name: "HIIT Iniciante",
                subtitle: "Queima de gordura em 20 minutos",
                goalTag: .conditioning,
                level: .beginner,
                equipment: .bodyweight,
                workoutCount: 4,
                sessionsPerWeek: 4,
                durationWeeks: 4
            ),
            onDelete: {}
        )
    }
    .padding()
    .background(FitTodayColor.background)
    .preferredColorScheme(.dark)
}
