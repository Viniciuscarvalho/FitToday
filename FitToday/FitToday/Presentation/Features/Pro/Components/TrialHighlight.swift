//
//  TrialHighlight.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Destaque do trial gratuito de 7 dias
// Componente extraído para manter a view principal < 100 linhas
struct TrialHighlight: View {
    var body: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "gift.fill")
                    .foregroundStyle(FitTodayColor.neonCyan)
                Text("7 DIAS GRÁTIS")
                    .font(FitTodayFont.accent(size: 16))
                    .foregroundStyle(FitTodayColor.neonCyan)
            }

            Text("Experimente todos os recursos Pro sem compromisso")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(FitTodaySpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.neonCyan.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(FitTodayColor.neonCyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
