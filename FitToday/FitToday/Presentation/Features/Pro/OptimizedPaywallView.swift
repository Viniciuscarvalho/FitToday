//
//  OptimizedPaywallView.swift
//  FitToday
//
//  Paywall com assinaturas Pro e Elite (mensal/anual) via StoreKit 2.
//

import SwiftUI
import StoreKit

struct OptimizedPaywallView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var storeService: StoreKitService
    @State private var selectedTier: SubscriptionTier = .pro
    @State private var selectedPeriod: SubscriptionPeriod = .annual
    @State private var selectedProduct: Product?
    @State private var errorMessage: ErrorMessage?

    private let onPurchaseSuccess: () -> Void
    private let onDismiss: () -> Void

    enum SubscriptionPeriod: String, CaseIterable {
        case monthly = "Mensal"
        case annual = "Anual"
    }

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
                VStack(spacing: FitTodaySpacing.lg) {
                    PaywallHeroSection()

                    periodToggle

                    planCards

                    featureList

                    ctaSection

                    legalFooter
                }
                .padding(.horizontal, FitTodaySpacing.md)
                .padding(.bottom, FitTodaySpacing.xl)
            }
            .background(FitTodayColor.background.ignoresSafeArea())
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
                updateSelectedProduct()
            }
            .onChange(of: selectedTier) { _, _ in updateSelectedProduct() }
            .onChange(of: selectedPeriod) { _, _ in updateSelectedProduct() }
            .onChange(of: storeService.purchaseState) { _, newState in
                if case .failed(let msg) = newState {
                    errorMessage = ErrorMessage(title: "Erro", message: msg)
                }
            }
            .errorToast(errorMessage: $errorMessage)
        }
    }

    // MARK: - Period Toggle

    private var periodToggle: some View {
        HStack(spacing: 0) {
            ForEach(SubscriptionPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                } label: {
                    HStack(spacing: FitTodaySpacing.xs) {
                        Text(period.rawValue)
                            .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                            .foregroundStyle(selectedPeriod == period ? .white : FitTodayColor.textSecondary)

                        if period == .annual {
                            Text("Economize 33%")
                                .font(FitTodayFont.ui(size: 10, weight: .bold))
                                .foregroundStyle(selectedPeriod == .annual ? FitTodayColor.brandAccent : FitTodayColor.textTertiary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(selectedPeriod == .annual
                                              ? FitTodayColor.brandAccent.opacity(0.2)
                                              : Color.clear)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FitTodaySpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                            .fill(selectedPeriod == period ? FitTodayColor.brandPrimary : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        HStack(spacing: FitTodaySpacing.sm) {
            planCard(for: .pro)
            planCard(for: .elite)
        }
    }

    private func planCard(for tier: SubscriptionTier) -> some View {
        let isSelected = selectedTier == tier
        let product = productForCard(tier: tier)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTier = tier
            }
        } label: {
            VStack(spacing: FitTodaySpacing.sm) {
                // Tier badge
                HStack {
                    Image(systemName: tier == .elite ? "star.fill" : "crown.fill")
                        .font(.system(size: 12))
                    Text(tier.displayName)
                        .font(FitTodayFont.ui(size: 13, weight: .bold))
                }
                .foregroundStyle(isSelected ? .white : FitTodayColor.textPrimary)
                .padding(.horizontal, FitTodaySpacing.sm)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? tierColor(tier) : FitTodayColor.surfaceElevated)
                )

                // Price
                if let product {
                    VStack(spacing: 2) {
                        Text(product.displayPrice)
                            .font(FitTodayFont.display(size: 22, weight: .extraBold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                        Text(selectedPeriod == .annual ? "/ano" : "/mês")
                            .font(FitTodayFont.ui(size: 12, weight: .medium))
                            .foregroundStyle(FitTodayColor.textSecondary)
                        if selectedPeriod == .annual {
                            Text(monthlyEquivalent(for: product, tier: tier))
                                .font(FitTodayFont.ui(size: 11, weight: .medium))
                                .foregroundStyle(tierColor(tier))
                        }
                    }
                } else {
                    ProgressView()
                        .frame(height: 44)
                }

                // Best value badge
                if tier == .elite {
                    Text("Melhor valor")
                        .font(FitTodayFont.ui(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(tierColor(.elite)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(FitTodaySpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .fill(FitTodayColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .stroke(
                                isSelected ? tierColor(tier) : FitTodayColor.outline.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .fitGlowEffect(color: isSelected ? tierColor(tier).opacity(0.2) : .clear)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("O que está incluso")
                .font(FitTodayFont.ui(size: 15, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            ForEach(features(for: selectedTier), id: \.title) { feature in
                featureRow(icon: feature.icon, title: feature.title, subtitle: feature.subtitle)
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    private func featureRow(icon: String, title: String, subtitle: String?) -> some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(tierColor(selectedTier))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitTodayFont.ui(size: 14, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(tierColor(selectedTier))
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Button {
                Task { await purchaseSelectedProduct() }
            } label: {
                HStack(spacing: FitTodaySpacing.sm) {
                    if storeService.purchaseState == .purchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(ctaLabel)
                            .font(FitTodayFont.ui(size: 17, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [tierColor(selectedTier), tierColor(selectedTier).opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                .foregroundStyle(.white)
            }
            .disabled(selectedProduct == nil || storeService.purchaseState == .purchasing)

            Button {
                Task { await restorePurchases() }
            } label: {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text("Restaurar compras")
                }
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.brandPrimary)
            }
        }
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Text("A assinatura é renovada automaticamente. Cancele a qualquer momento nas configurações do dispositivo.")
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, FitTodaySpacing.sm)
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
            errorMessage = ErrorMessage(
                title: "Restaurar Compras",
                message: "Nenhuma assinatura ativa encontrada."
            )
        }
    }

    // MARK: - Helpers

    private func updateSelectedProduct() {
        let productID: String
        switch (selectedTier, selectedPeriod) {
        case (.pro, .monthly): productID = StoreKitProductID.proMonthly
        case (.pro, .annual): productID = StoreKitProductID.proAnnual
        case (.elite, .monthly): productID = StoreKitProductID.eliteMonthly
        case (.elite, .annual): productID = StoreKitProductID.eliteAnnual
        default: productID = StoreKitProductID.proAnnual
        }
        selectedProduct = storeService.product(id: productID)
    }

    private func productForCard(tier: SubscriptionTier) -> Product? {
        let id = selectedPeriod == .annual
            ? (tier == .pro ? StoreKitProductID.proAnnual : StoreKitProductID.eliteAnnual)
            : (tier == .pro ? StoreKitProductID.proMonthly : StoreKitProductID.eliteMonthly)
        return storeService.product(id: id)
    }

    private func monthlyEquivalent(for product: Product, tier: SubscriptionTier) -> String {
        // Annual price / 12 months — show as "R$X,XX/mês"
        guard let price = Double(product.price.description) else { return "" }
        let monthly = price / 12.0
        return String(format: "equivale a R$%.2f/mês", monthly).replacingOccurrences(of: ".", with: ",")
    }

    private var ctaLabel: String {
        guard let product = selectedProduct else {
            return "Assinar \(selectedTier.displayName)"
        }
        return "Assinar \(selectedTier.displayName) — \(product.displayPrice)"
    }

    private func tierColor(_ tier: SubscriptionTier) -> Color {
        tier == .elite ? FitTodayColor.brandAccent : FitTodayColor.brandPrimary
    }

    private struct PaywallFeature {
        let icon: String
        let title: String
        let subtitle: String?
    }

    private func features(for tier: SubscriptionTier) -> [PaywallFeature] {
        var list: [PaywallFeature] = [
            .init(icon: "bolt.fill", title: "Treinos IA Ilimitados", subtitle: tier == .pro ? "2 treinos IA por dia" : "Ilimitado"),
            .init(icon: "waveform.path.ecg", title: "Substituição inteligente de exercícios", subtitle: nil),
            .init(icon: "chart.bar.fill", title: "Histórico completo de treinos", subtitle: nil),
            .init(icon: "checkmark.seal.fill", title: "Programas premium de treinamento", subtitle: nil),
            .init(icon: "bubble.left.and.bubble.right.fill", title: "FitOrb — Assistente IA", subtitle: tier == .pro ? "Chat IA ilimitado" : "Chat com contexto expandido"),
        ]
        if tier == .elite {
            list.append(.init(icon: "person.fill.checkmark", title: "Personal Trainer integrado", subtitle: "Acesso à rede de trainers"))
            list.append(.init(icon: "flame.fill", title: "Desafios ilimitados", subtitle: "Sem limite de grupos simultâneos"))
        }
        return list
    }
}

// MARK: - Preview

#Preview("Paywall") {
    OptimizedPaywallView(storeService: StoreKitService())
}
