//
//  PhaseModePicker.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Picker para modo de exibição de fases (Auto/Exercícios/Guiado)
// Componente extraído para manter a view principal < 100 linhas
struct PhaseModePicker: View {
    @Binding var displayMode: PhaseDisplayMode
    let isPro: Bool
    let isRegenerating: Bool
    let timerHasStarted: Bool
    let onShowModeInfo: () -> Void
    let onRegenerateWorkout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            header

            Picker("Modo", selection: $displayMode) {
                ForEach(PhaseDisplayMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Escolha como exibir aquecimento e aeróbio")

            // Botão de regenerar treino
            regenerateButton
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .fitCardShadow()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Modo de treino")
                .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                .tracking(0.5)
                .foregroundStyle(FitTodayColor.textSecondary)

            Spacer()

            // Badge PRO/Free
            FitBadge(
                text: isPro ? "PRO" : "Free",
                style: isPro ? .pro : .info
            )

            Button(action: onShowModeInfo) {
                Image(systemName: "info.circle")
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .accessibilityLabel("Informações sobre os modos")
        }
    }

    // MARK: - Regenerate Button

    @ViewBuilder
    private var regenerateButton: some View {
        Button(action: onRegenerateWorkout) {
            HStack(spacing: FitTodaySpacing.sm) {
                if isRegenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isPro ? "sparkles" : "arrow.clockwise")
                        .font(.system(.body, weight: .semibold))
                }

                Text(regenerateButtonTitle)
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.sm)
            .foregroundStyle(isPro ? FitTodayColor.textInverse : FitTodayColor.brandPrimary)
            .background(
                Group {
                    if isPro {
                        RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                            .fill(FitTodayColor.brandPrimary)
                            .diagonalStripes(color: FitTodayColor.neonCyan, spacing: 8, opacity: 0.2)
                    } else {
                        RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                            .fill(FitTodayColor.surface)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .stroke(FitTodayColor.brandPrimary, lineWidth: isPro ? 0 : 1.5)
            )
            .techCornerBorders(length: 12, thickness: 1.5)
        }
        .disabled(isRegenerating || timerHasStarted)
        .opacity(timerHasStarted ? 0.5 : 1)
        .padding(.top, FitTodaySpacing.xs)
        .accessibilityHint(isPro ? "Regenera o treino usando IA" : "Regenera o treino localmente")
    }

    private var regenerateButtonTitle: String {
        if isRegenerating {
            return "Regenerando..."
        }
        return isPro ? "Regenerar com IA ✨" : "Regenerar treino"
    }
}
