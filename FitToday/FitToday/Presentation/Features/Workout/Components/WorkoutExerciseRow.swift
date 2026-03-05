//
//  WorkoutExerciseRow.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Row card para exibir exercício no plano de treino
// Componente extraído para manter a view principal < 100 linhas
struct WorkoutExerciseRow: View {
    let index: Int
    let prescription: ExercisePrescription
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.md) {
            ExerciseImageView(exerciseId: prescription.exercise.id, imageIndex: 0, cornerRadius: FitTodayRadius.sm)
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text("\(index). \(prescription.exercise.name)")
                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("\(prescription.sets)x · \(prescription.reps.lowerBound)-\(prescription.reps.upperBound) reps")
                    .font(FitTodayFont.ui(size: 13, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)

                if let tip = prescription.tip {
                    Text(tip)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textTertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if isCurrent {
                FitBadge(text: "Atual", style: .info)
            }
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .fitCardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prescription.exercise.name), \(prescription.sets) séries de \(prescription.reps.display) repetições")
    }
}
