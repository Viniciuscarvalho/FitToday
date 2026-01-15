//
//  FocusCard.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Card de seleção de foco do treino
// Componente extraído para manter a view principal < 100 linhas
struct FocusCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
                .fitGlowEffect(color: isSelected ? FitTodayColor.brandPrimary.opacity(0.4) : Color.clear.opacity(0))
            Text(title)
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text(subtitle)
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(FitTodayColor.brandPrimary.opacity(0.12))
                        .diagonalStripes(color: FitTodayColor.neonCyan, spacing: 10, opacity: 0.15)
                } else {
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(FitTodayColor.surface)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(isSelected ? FitTodayColor.neonCyan : FitTodayColor.outline.opacity(0.3), lineWidth: 1.5)
        )
        .techCornerBorders(color: isSelected ? FitTodayColor.neonCyan : FitTodayColor.techBorder.opacity(0.3), length: 12, thickness: 1.5)
        .fitCardShadow()
        .contentShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}
