//
//  PaywallCTASection.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI
import StoreKit

// 💡 Learn: Seção de CTA do paywall com botão de compra
// Componente extraído para manter a view principal < 100 linhas
struct PaywallCTASection: View {
    let selectedProduct: Product?
    let isPurchasing: Bool
    let onPurchase: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Botão principal de compra
            Button(action: onPurchase) {
                HStack(spacing: FitTodaySpacing.sm) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(ctaText)
                            .font(FitTodayFont.ui(size: 17, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundStyle(.white)
            }
            .disabled(selectedProduct == nil || isPurchasing)

            Text("Cancele a qualquer momento")
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)

            // Botão de restaurar compras
            Button(action: onRestore) {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text("Já é Pro? Restaurar compra")
                }
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.brandPrimary)
            }
        }
    }

    private var ctaText: String {
        guard let product = selectedProduct else { return "Assinar" }

        if product.hasIntroOffer, let intro = product.introOfferDescription {
            return "Começar \(intro)"
        }

        return "Assinar por \(product.displayPrice)/\(product.periodDescription)"
    }
}
