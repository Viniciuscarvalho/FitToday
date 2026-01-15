//
//  OptimizedPaywallView.swift
//  FitToday
//
//  Paywall otimizado com trial 7 dias e comparação Free vs Pro.
//  Refactored on 15/01/26 - Extracted components to separate files
//

import SwiftUI
import StoreKit

// 💡 Learn: View refatorada com componentes extraídos para manutenibilidade
// Seguindo diretriz de < 100 linhas por view
struct OptimizedPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var storeService: StoreKitService

    @State private var selectedProduct: Product?
    @State private var errorMessage: ErrorMessage?
    @State private var showComparison = false

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

                    TrialHighlight()

                    comparisonSection

                    plansSection

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
                selectedProduct = storeService.yearlyProduct ?? storeService.monthlyProduct
            }
            .errorToast(errorMessage: $errorMessage)
            .onChange(of: storeService.purchaseState) { _, newState in
                handlePurchaseStateChange(newState)
            }
        }
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showComparison.toggle()
                }
            } label: {
                HStack {
                    Text("Comparar Free vs Pro")
                        .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Spacer()

                    Image(systemName: showComparison ? "chevron.up" : "chevron.down")
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .fill(FitTodayColor.surface)
                )
            }

            if showComparison {
                FeatureComparisonTable()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Plans Section

    private var plansSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            if storeService.purchaseState == .loading && storeService.products.isEmpty {
                ProgressView()
                    .frame(height: 150)
            } else {
                ForEach(storeService.products.sorted(by: { $0.price > $1.price }), id: \.id) { product in
                    OptimizedPlanCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isBestValue: product.id == StoreKitProductID.proYearly
                    ) {
                        withAnimation(.spring(response: 0.2)) {
                            selectedProduct = product
                        }
                    }
                }
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
            errorMessage = ErrorMessage(title: "Restaurar Compras", message: "Nenhuma assinatura encontrada para restaurar.")
        }
    }

    private func handlePurchaseStateChange(_ state: StoreKitService.PurchaseState) {
        if case .failed(let message) = state {
            errorMessage = ErrorMessage(title: "Erro", message: message)
        }
    }
}

// MARK: - Preview

#Preview("Optimized Paywall") {
    OptimizedPaywallView(storeService: StoreKitService())
}
