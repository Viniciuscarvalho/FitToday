//
//  HomeHeader.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Header da Home com saudação e badges
// Componente extraído para manter a view principal < 100 linhas
struct HomeHeader: View {
    let greeting: String
    let dateFormatted: String
    let isPro: Bool
    let goalBadgeText: String?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(greeting)
                    .font(FitTodayFont.ui(size: 28, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text(dateFormatted)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            Spacer()

            HStack(spacing: FitTodaySpacing.sm) {
                if let badgeText = goalBadgeText {
                    goalBadge(text: badgeText)
                }

                if isPro {
                    proBadge
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, FitTodaySpacing.sm)
    }

    // MARK: - Subviews

    private func goalBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(FitTodayColor.brandPrimary)
            .padding(.horizontal, FitTodaySpacing.sm)
            .padding(.vertical, FitTodaySpacing.xs)
            .background(FitTodayColor.surface)
            .clipShape(Capsule())
    }

    private var proBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 11, weight: .bold))
            Text("PRO")
                .font(FitTodayFont.ui(size: 11, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(
            LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
    }
}
