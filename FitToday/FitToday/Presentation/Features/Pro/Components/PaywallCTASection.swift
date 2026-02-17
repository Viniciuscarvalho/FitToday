//
//  PaywallCTASection.swift
//  FitToday
//

import SwiftUI
import StoreKit

struct PaywallCTASection: View {
    let selectedProduct: Product?
    let isPurchasing: Bool
    let onPurchase: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
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

            Text("Pagamento único. Sem assinatura.")
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)

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
        guard let product = selectedProduct else { return "Desbloquear Pro" }
        return "Desbloquear Pro por \(product.displayPrice)"
    }
}
