//
//  SorenessCard.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Card de seleção de nível de dor muscular
// Componente extraído para manter a view principal < 100 linhas
struct SorenessCard: View {
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
            Text(title)
                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
            Text(subtitle)
                .font(FitTodayFont.ui(size: 13, weight: .medium))
        }
        .foregroundStyle(isSelected ? Color.white : FitTodayColor.textPrimary)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(isSelected ? color : color.opacity(0.2))
        )
        .techCornerBorders(color: isSelected ? Color.white.opacity(0.5) : color.opacity(0.4), length: 12, thickness: 1.5)
        .fitCardShadow()
        .contentShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}
