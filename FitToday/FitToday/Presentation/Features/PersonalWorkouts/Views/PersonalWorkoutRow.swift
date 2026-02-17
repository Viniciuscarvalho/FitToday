//
//  PersonalWorkoutRow.swift
//  FitToday
//
//  Row para exibir um treino do Personal na lista.
//

import SwiftUI

/// Row para exibir um treino do Personal na lista.
struct PersonalWorkoutRow: View {
    let workout: PersonalWorkout
    let isCached: Bool

    init(workout: PersonalWorkout, isCached: Bool = false) {
        self.workout = workout
        self.isCached = isCached
    }

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Ícone do tipo de arquivo
            fileIcon

            // Informações do treino
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                HStack {
                    Text(workout.title)
                        .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    if workout.isNew {
                        newBadge
                    }
                }

                if let description = workout.description {
                    Text(description)
                        .font(FitTodayFont.ui(size: 13))
                        .foregroundStyle(FitTodayColor.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: FitTodaySpacing.sm) {
                    Label(workout.relativeDate, systemImage: "clock")
                        .font(FitTodayFont.ui(size: 12))
                        .foregroundStyle(FitTodayColor.textTertiary)

                    if isCached {
                        Label("Offline", systemImage: "arrow.down.circle.fill")
                            .font(FitTodayFont.ui(size: 12))
                            .foregroundStyle(FitTodayColor.success)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FitTodayColor.textTertiary)
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(
                    workout.isNew ? FitTodayColor.brandPrimary.opacity(0.3) : FitTodayColor.outline.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Subviews

    private var fileIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                .fill(iconBackgroundColor)
                .frame(width: 48, height: 48)

            Image(systemName: workout.fileType.icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
        }
    }

    private var newBadge: some View {
        Text("personal.new_badge".localized)
            .font(FitTodayFont.ui(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(FitTodayColor.brandPrimary)
            .clipShape(Capsule())
    }

    private var iconBackgroundColor: Color {
        switch workout.fileType {
        case .pdf:
            return Color.red.opacity(0.1)
        case .image:
            return Color.blue.opacity(0.1)
        }
    }

    private var iconColor: Color {
        switch workout.fileType {
        case .pdf:
            return Color.red
        case .image:
            return Color.blue
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        PersonalWorkoutRow(
            workout: .fixture(
                title: "Treino A - Peito e Tríceps",
                description: "Treino focado em hipertrofia muscular",
                viewedAt: nil
            ),
            isCached: false
        )

        PersonalWorkoutRow(
            workout: .fixture(
                title: "Treino B - Costas e Bíceps",
                description: "Foco em força e definição",
                viewedAt: Date()
            ),
            isCached: true
        )

        PersonalWorkoutRow(
            workout: .fixture(
                title: "Treino C - Pernas",
                fileType: .image,
                viewedAt: Date()
            ),
            isCached: false
        )
    }
    .padding()
    .background(FitTodayColor.background)
}
#endif
