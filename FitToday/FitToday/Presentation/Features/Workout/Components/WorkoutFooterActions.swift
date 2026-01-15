//
//  WorkoutFooterActions.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Ações do footer do treino (retomar/pular)
// Componente extraído para manter a view principal < 100 linhas
struct WorkoutFooterActions: View {
    let isFinishing: Bool
    let onResumeExercise: () -> Void
    let onSkipWorkout: () -> Void

    var body: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button("Retomar exercício atual", action: onResumeExercise)
                .fitSecondaryStyle()

            Button("Pular treino de hoje", action: onSkipWorkout)
                .buttonStyle(.plain)
                .foregroundStyle(Color.orange)
                .padding(.top, FitTodaySpacing.sm)
                .disabled(isFinishing)
        }
    }
}
