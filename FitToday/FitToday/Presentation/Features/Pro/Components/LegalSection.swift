//
//  LegalSection.swift
//  FitToday
//

import SwiftUI

struct LegalSection: View {
    var body: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Text("Compra única não renovável. O acesso é permanente após a confirmação do pagamento.")
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
