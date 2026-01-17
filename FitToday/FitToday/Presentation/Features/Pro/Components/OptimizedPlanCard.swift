//
//  OptimizedPlanCard.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI
import StoreKit

// 💡 Learn: Card de plano de assinatura com destaque de melhor valor
// Componente extraído para manter a view principal < 100 linhas
struct OptimizedPlanCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: FitTodaySpacing.xs) {
                            Text(product.displayName)
                                .font(FitTodayFont.ui(size: 17, weight: .bold))
                                .foregroundStyle(FitTodayColor.textPrimary)

                            if isBestValue {
                                Text("ECONOMIZE 50%")
                                    .font(FitTodayFont.accent(size: 9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(FitTodayColor.brandPrimary)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }

                        if product.hasIntroOffer, let intro = product.introOfferDescription {
                            Text("🎁 \(intro)")
                                .font(FitTodayFont.ui(size: 13, weight: .semiBold))
                                .foregroundStyle(FitTodayColor.neonCyan)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(FitTodayFont.display(size: 22, weight: .bold))
                            .foregroundStyle(FitTodayColor.textPrimary)

                        Text(product.periodDescription)
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }

                // Monthly breakdown for yearly
                if product.id == StoreKitProductID.proYearly {
                    Text("Equivale a \(product.localizedPricePerMonth)/mês")
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(isSelected ? FitTodayColor.brandPrimary.opacity(0.1) : FitTodayColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(
                        isSelected ? FitTodayColor.brandPrimary : FitTodayColor.outline.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
