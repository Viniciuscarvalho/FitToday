//
//  PrefetchingOverlay.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

// 💡 Learn: Overlay de loading para prefetch de imagens do treino
// Componente extraído para manter a view principal < 100 linhas
struct PrefetchingOverlay: View {
    var body: some View {
        ZStack {
            FitTodayColor.background.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: FitTodaySpacing.md) {
                ProgressView()
                    .controlSize(.large)
                    .tint(FitTodayColor.brandPrimary)

                VStack(spacing: FitTodaySpacing.xs) {
                    Text("Preparando treino...")
                        .font(FitTodayFont.display(size: 17, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text("Carregando imagens para uso offline")
                        .font(FitTodayFont.ui(size: 13, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .padding(FitTodaySpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
                    .retroGridOverlay(spacing: 25)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .techCornerBorders(length: 16, thickness: 2)
            .padding()
        }
        .transition(.opacity)
    }
}
