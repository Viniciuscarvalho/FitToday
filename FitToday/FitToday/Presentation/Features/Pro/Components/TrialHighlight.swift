//
//  LifetimeValueHighlight.swift
//  FitToday
//

import SwiftUI

struct LifetimeValueHighlight: View {
    var body: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "infinity")
                    .foregroundStyle(FitTodayColor.neonCyan)
                Text("PAGUE UMA VEZ, USE PARA SEMPRE")
                    .font(FitTodayFont.accent(size: 16))
                    .foregroundStyle(FitTodayColor.neonCyan)
            }

            Text("Sem assinatura. Sem renovação. Acesso vitalício.")
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
