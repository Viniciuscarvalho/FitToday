//
//  WorkoutCardCompact.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Card compacto de treino para exibição vertical
// Componente extraído para manter a view principal < 100 linhas
struct WorkoutCardCompact: View {
    let workout: LibraryWorkout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FitTodaySpacing.md) {
                // Thumbnail placeholder (gradiente)
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "figure.run")
                            .font(.system(.title3))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(workout.title)
                        .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: FitTodaySpacing.sm) {
                        Label("\(workout.estimatedDurationMinutes) min", systemImage: "clock")
                        Label("\(workout.exerciseCount)", systemImage: "figure.strengthtraining.traditional")
                        intensityBadge
                    }
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var intensityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(intensityColor)
                .frame(width: 6, height: 6)
            Text(workout.intensity.displayName)
        }
    }

    private var intensityColor: Color {
        switch workout.intensity {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
}
