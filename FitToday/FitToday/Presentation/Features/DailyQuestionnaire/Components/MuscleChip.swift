//
//  MuscleChip.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Chip para seleção de grupos musculares com dor
// Componente extraído para manter a view principal < 100 linhas
struct MuscleChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(FitTodayFont.ui(size: 12, weight: .medium))
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? FitTodayColor.brandPrimary.opacity(0.2) : FitTodayColor.surface)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline.opacity(0.4), lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? FitTodayColor.brandPrimary : FitTodayColor.textSecondary)
    }
}
