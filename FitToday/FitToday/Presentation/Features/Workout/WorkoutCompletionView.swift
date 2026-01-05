//
//  WorkoutCompletionView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI

struct WorkoutCompletionView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore

    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: statusIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundStyle(statusColor)

            VStack(spacing: FitTodaySpacing.sm) {
                Text(titleText)
                    .font(.system(.title2, weight: .bold))
                Text(descriptionText)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            VStack(spacing: FitTodaySpacing.sm) {
                Button(primaryCTATitle) {
                    finalizeFlow(goToHistory: false)
                }
                .fitPrimaryStyle()

                Button("Ver histórico") {
                    finalizeFlow(goToHistory: true)
                }
                .fitSecondaryStyle()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Resumo")
        .navigationBarBackButtonHidden(true)
    }

    private func finalizeFlow(goToHistory: Bool) {
        sessionStore.reset()
        router.pop(on: .home) // summary
        router.pop(on: .home) // detail
        router.pop(on: .home) // workout list

        if goToHistory {
            router.select(tab: .history)
        }
    }

    private var statusIcon: String {
        switch status {
        case .completed: return "checkmark.seal.fill"
        case .skipped: return "figure.walk"
        }
    }

    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .skipped: return .orange
        }
    }

    private var titleText: String {
        switch status {
        case .completed: return "Treino concluído!"
        case .skipped: return "Treino pulado"
        }
    }

    private var descriptionText: String {
        switch status {
        case .completed:
            return "Registramos sua sessão de hoje no histórico. Mantenha a consistência!"
        case .skipped:
            return "Tudo bem! Registramos como pulado — amanhã terá outro treino esperando."
        }
    }

    private var primaryCTATitle: String {
        status == .completed ? "Voltar para Home" : "Voltar para Home"
    }

    private var status: WorkoutStatus {
        sessionStore.lastCompletionStatus ?? .completed
    }
}

