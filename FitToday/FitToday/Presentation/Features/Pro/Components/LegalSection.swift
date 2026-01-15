//
//  LegalSection.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Seção legal do paywall com termos e privacidade
// Componente extraído para manter a view principal < 100 linhas
struct LegalSection: View {
    var body: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Text("Assinatura renovada automaticamente após o período de trial. Cancele a qualquer momento nas configurações do iPhone.")
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: FitTodaySpacing.md) {
                Link("Termos", destination: URL(string: "https://fittoday.app/terms")!)
                Text("•").foregroundStyle(FitTodayColor.textSecondary)
                Link("Privacidade", destination: URL(string: "https://fittoday.app/privacy")!)
            }
            .font(FitTodayFont.ui(size: 11, weight: .medium))
            .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .padding(.top, FitTodaySpacing.sm)
    }
}
