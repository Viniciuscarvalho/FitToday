//
//  FloatingTimerBar.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Timer bar flutuante para acompanhamento de treino em andamento
// Componente extraído para manter a view principal < 100 linhas
struct FloatingTimerBar: View {
    let timerStore: WorkoutTimerStore
    let onToggleTimer: () -> Void
    let onFinish: () -> Void
    let isFinishing: Bool

    var body: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Tempo decorrido
            timeDisplay

            Spacer()

            // Botão de pausar/retomar
            toggleButton

            // Botão de finalizar
            finishButton
        }
        .padding(.horizontal, FitTodaySpacing.lg)
        .padding(.vertical, FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
                .retroGridOverlay(spacing: 20)
                .shadow(color: FitTodayColor.neonCyan.opacity(0.2), radius: 12, x: 0, y: -4)
        )
        .techCornerBorders(color: FitTodayColor.neonCyan, length: 20, thickness: 2)
        .scanlineOverlay()
        .padding(.horizontal)
        .padding(.bottom, FitTodaySpacing.sm)
    }

    // MARK: - Time Display

    private var timeDisplay: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: "timer")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(FitTodayColor.neonCyan)
                .fitGlowEffect(color: FitTodayColor.neonCyan.opacity(0.5))

            Text(timerStore.formattedTime)
                .font(FitTodayFont.display(size: 22, weight: .black))
                .foregroundStyle(FitTodayColor.textPrimary)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Toggle Button

    private var toggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onToggleTimer()
            }
        } label: {
            Image(systemName: timerStore.isRunning ? "pause.fill" : "play.fill")
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(timerStore.isRunning ? Color.orange : FitTodayColor.brandPrimary)
                .clipShape(Circle())
        }
        .accessibilityLabel(timerStore.isRunning ? "Pausar treino" : "Retomar treino")
    }

    // MARK: - Finish Button

    private var finishButton: some View {
        Button(action: onFinish) {
            Image(systemName: "checkmark")
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.green)
                .clipShape(Circle())
        }
        .accessibilityLabel("Finalizar treino")
        .disabled(isFinishing)
    }
}
