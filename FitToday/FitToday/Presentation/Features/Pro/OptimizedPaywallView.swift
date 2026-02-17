//
//  OptimizedPaywallView.swift
//  FitToday
//
//  Paywall com compra única (non-consumable) e comparação Free vs Pro.
//

import SwiftUI
import StoreKit

struct OptimizedPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var storeService: StoreKitService

    @State private var selectedProduct: Product?
    @State private var errorMessage: ErrorMessage?

    private let onPurchaseSuccess: () -> Void
    private let onDismiss: () -> Void

    init(
        storeService: StoreKitService,
        onPurchaseSuccess: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        _storeService = State(initialValue: storeService)
        self.onPurchaseSuccess = onPurchaseSuccess
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FitTodaySpacing.xl) {
                    PaywallHeroSection()

                    LifetimeValueHighlight()

                    lifetimePriceSection

                    FeatureComparisonTable()

                    PaywallCTASection(
                        selectedProduct: selectedProduct,
                        isPurchasing: storeService.purchaseState == .purchasing,
                        onPurchase: { Task { await purchaseSelectedProduct() } },
                        onRestore: { Task { await restorePurchases() } }
                    )

                    LegalSection()
                }
                .padding()
            }
            .background(
                ZStack {
                    FitTodayColor.background
                    RetroGridPattern(lineColor: FitTodayColor.gridLine.opacity(0.2), spacing: 40)
                }
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
            }
            .task {
                await storeService.loadProducts()
                selectedProduct = storeService.lifetimeProduct
            }
            .errorToast(errorMessage: $errorMessage)
            .onChange(of: storeService.purchaseState) { _, newState in
                handlePurchaseStateChange(newState)
            }
        }
    }

    // MARK: - Lifetime Price Section

    private var lifetimePriceSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            if let product = storeService.lifetimeProduct {
                VStack(spacing: FitTodaySpacing.xs) {
                    Text(product.displayPrice)
                        .font(FitTodayFont.display(size: 40, weight: .extraBold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text("pagamento único")
                        .font(FitTodayFont.ui(size: 15, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
                .padding(FitTodaySpacing.lg)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                        .fill(FitTodayColor.brandPrimary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                        .stroke(FitTodayColor.brandPrimary.opacity(0.3), lineWidth: 2)
                )
                .techCornerBorders(color: FitTodayColor.neonCyan, length: 16, thickness: 2)
            } else if storeService.purchaseState == .loading {
                ProgressView()
                    .frame(height: 100)
            }
        }
    }

    // MARK: - Actions

    private func purchaseSelectedProduct() async {
        guard let product = selectedProduct else { return }
        let success = await storeService.purchase(product)
        if success {
            onPurchaseSuccess()
            dismiss()
        }
    }

    private func restorePurchases() async {
        let restored = await storeService.restorePurchases()
        if restored {
            onPurchaseSuccess()
            dismiss()
        } else if storeService.purchaseState != .failed("") {
            errorMessage = ErrorMessage(title: "Restaurar Compras", message: "Nenhuma compra encontrada para restaurar.")
        }
    }

    private func handlePurchaseStateChange(_ state: StoreKitService.PurchaseState) {
        if case .failed(let message) = state {
            errorMessage = ErrorMessage(title: "Erro", message: message)
        }
    }
}

// MARK: - Preview

#Preview("Paywall") {
    OptimizedPaywallView(storeService: StoreKitService())
}
