//
//  ProgramCardSmall.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Card compacto de programa para exibição horizontal
// Componente extraído para manter a view principal < 100 linhas
struct ProgramCardSmall: View {
    let program: Program
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                // Imagem hero do programa
                ZStack(alignment: .topLeading) {
                    Image(program.heroImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 100)
                        .clipped()

                    // Overlay sutil
                    LinearGradient(
                        colors: [.black.opacity(0.3), .clear, .black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Badge do objetivo
                    HStack(spacing: 4) {
                        Image(systemName: program.goalTag.iconName)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(FitTodayColor.surface.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(FitTodaySpacing.sm)
                }
                .frame(width: 150, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .stroke(FitTodayColor.outline.opacity(0.3), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(program.name)
                        .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .lineLimit(1)

                    Text(program.durationDescription)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                .padding(.horizontal, 2)
            }
            .frame(width: 150)
        }
        .buttonStyle(.plain)
    }
}
