//
//  PaywallHeroSection.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Hero section do paywall com animação de glow
// Componente extraído para manter a view principal < 100 linhas
struct PaywallHeroSection: View {
    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Ícone com glow animado
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [FitTodayColor.brandPrimary.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FitTodayColor.brandPrimary, FitTodayColor.neonCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("FitToday Pro")
                .font(FitTodayFont.display(size: 32, weight: .extraBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Treinos personalizados por IA\nque se adaptam ao seu corpo")
                .font(FitTodayFont.ui(size: 17, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FitTodaySpacing.md)
    }
}
