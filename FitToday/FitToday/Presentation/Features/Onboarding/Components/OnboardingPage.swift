//
//  OnboardingPage.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Página de introdução do onboarding
// Componente extraído para manter a view principal < 100 linhas
struct OnboardingPage: View {
    let title: String
    let bullets: [String]

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(FitTodayFont.display(size: 32, weight: .extraBold))
                .tracking(1.5)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(FitTodayColor.brandPrimary)
                            .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))
                        Text(bullet)
                            .font(FitTodayFont.ui(size: 17, weight: .medium))
                            .foregroundStyle(FitTodayColor.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
            )
            .fitCardBorder()
            .cornerRadius(FitTodayRadius.md)
            .fitCardShadow()
        }
        .padding(.horizontal, 8)
    }

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Treinos que se adaptam a você",
            bullets: [
                "Responda 2 perguntas por dia e receba um treino seguro.",
                "Sem precisar pensar em séries, ordem ou ajustes."
            ]
        ),
        OnboardingPage(
            title: "Fluxo ultra rápido",
            bullets: [
                "Menos de 10 segundos para responder.",
                "Sempre alinhado ao seu objetivo atual."
            ]
        ),
        OnboardingPage(
            title: "Free vs Pro",
            bullets: [
                "Biblioteca básica gratuita para começar agora.",
                "Plano Pro libera IA, ajustes por dor e histórico."
            ]
        )
    ]
}
