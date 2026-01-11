//
//  OptimizedPaywallView.swift
//  FitToday
//
//  Paywall otimizado com trial 7 dias e comparação Free vs Pro.
//

import SwiftUI
import StoreKit

// MARK: - Optimized Paywall View

struct OptimizedPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @StateObject private var storeService: StoreKitService
    
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
        _storeService = StateObject(wrappedValue: storeService)
        self.onPurchaseSuccess = onPurchaseSuccess
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FitTodaySpacing.xl) {
                    heroSection
                    trialHighlight
                    comparisonSection
                    plansSection
                    ctaSection
                    restoreSection
                    legalSection
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
                // Preferir plano anual por padrão
                selectedProduct = storeService.yearlyProduct ?? storeService.monthlyProduct
            }
            .errorToast(errorMessage: $errorMessage)
            .onChange(of: storeService.purchaseState) { _, newState in
                handlePurchaseStateChange(newState)
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Ícone com glow animado
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [FitTodayColor.brandPrimary.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FitTodayColor.brandPrimary, FitTodayColor.neonCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("FitToday Pro")
                .font(FitTodayFont.display(size: 32, weight: .extraBold))
                .foregroundStyle(FitTodayColor.textPrimary)
            
            Text("Treinos personalizados por IA\nque se adaptam ao seu corpo")
                .font(FitTodayFont.ui(size: 17, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FitTodaySpacing.md)
    }
    
    // MARK: - Trial Highlight
    
    private var trialHighlight: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "gift.fill")
                    .foregroundStyle(FitTodayColor.neonCyan)
                Text("7 DIAS GRÁTIS")
                    .font(FitTodayFont.accent(size: 16))
                    .foregroundStyle(FitTodayColor.neonCyan)
            }
            
            Text("Experimente todos os recursos Pro sem compromisso")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .padding(FitTodaySpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.neonCyan.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(FitTodayColor.neonCyan.opacity(0.3), lineWidth: 1)
                )
        )
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
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button {
                Task {
                    await purchaseSelectedProduct()
                }
            } label: {
                HStack(spacing: FitTodaySpacing.sm) {
                    if storeService.purchaseState == .purchasing {
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
            .disabled(selectedProduct == nil || storeService.purchaseState == .purchasing)
            
            Text("Cancele a qualquer momento")
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }
    
    private var ctaText: String {
        guard let product = selectedProduct else { return "Assinar" }
        
        if product.hasIntroOffer, let intro = product.introOfferDescription {
            return "Começar \(intro)"
        }
        
        return "Assinar por \(product.displayPrice)/\(product.periodDescription)"
    }
    
    // MARK: - Restore Section
    
    private var restoreSection: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "arrow.clockwise")
                Text("Já é Pro? Restaurar compra")
            }
            .font(FitTodayFont.ui(size: 14, weight: .medium))
            .foregroundStyle(FitTodayColor.brandPrimary)
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Text("Assinatura renovada automaticamente após o período de trial. Cancele a qualquer momento nas configurações do iPhone.")
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            HStack(spacing: FitTodaySpacing.md) {
                Link("Termos", destination: URL(string: "https://fittoday.app/terms")!)
                Text("•").foregroundStyle(FitTodayColor.textSecondary)
                Link("Privacidade", destination: URL(string: "https://fittoday.app/privacy")!)
            }
            .font(FitTodayFont.ui(size: 11, weight: .medium))
            .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .padding(.top, FitTodaySpacing.sm)
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

// MARK: - Feature Comparison Table

private struct FeatureComparisonTable: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recurso")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .frame(width: 60)
                Text("Pro")
                    .frame(width: 60)
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
            .font(FitTodayFont.ui(size: 12, weight: .semiBold))
            .foregroundStyle(FitTodayColor.textSecondary)
            .padding(.horizontal, FitTodaySpacing.md)
            .padding(.vertical, FitTodaySpacing.sm)
            .background(FitTodayColor.surface)
            
            Divider().background(FitTodayColor.outline.opacity(0.2))
            
            // Features
            FeatureComparisonRow(
                feature: "Treinos IA personalizados",
                freeValue: .limited("1/sem"),
                proValue: .unlimited
            )
            FeatureComparisonRow(
                feature: "Ajuste por dor muscular",
                freeValue: .no,
                proValue: .yes
            )
            FeatureComparisonRow(
                feature: "Substituição inteligente",
                freeValue: .no,
                proValue: .yes
            )
            FeatureComparisonRow(
                feature: "Histórico de treinos",
                freeValue: .limited("7 dias"),
                proValue: .unlimited
            )
            FeatureComparisonRow(
                feature: "Exercícios com GIFs",
                freeValue: .yes,
                proValue: .yes
            )
            FeatureComparisonRow(
                feature: "Programas da Biblioteca",
                freeValue: .yes,
                proValue: .yes
            )
        }
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(FitTodayColor.outline.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct FeatureComparisonRow: View {
    let feature: String
    let freeValue: FeatureValue
    let proValue: FeatureValue
    
    enum FeatureValue {
        case yes
        case no
        case limited(String)
        case unlimited
        
        var icon: String {
            switch self {
            case .yes, .unlimited: return "checkmark.circle.fill"
            case .no: return "xmark.circle"
            case .limited: return "minus.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .yes, .unlimited: return FitTodayColor.brandPrimary
            case .no: return FitTodayColor.textSecondary.opacity(0.5)
            case .limited: return .orange
            }
        }
        
        var text: String? {
            switch self {
            case .limited(let text): return text
            case .unlimited: return "∞"
            default: return nil
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(feature)
                .font(FitTodayFont.ui(size: 13, weight: .medium))
                .foregroundStyle(FitTodayColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            featureIcon(for: freeValue)
                .frame(width: 60)
            
            featureIcon(for: proValue)
                .frame(width: 60)
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
    }
    
    private func featureIcon(for value: FeatureValue) -> some View {
        Group {
            if let text = value.text {
                Text(text)
                    .font(FitTodayFont.ui(size: 11, weight: .semiBold))
                    .foregroundStyle(value.color)
            } else {
                Image(systemName: value.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(value.color)
            }
        }
    }
}

// MARK: - Optimized Plan Card

private struct OptimizedPlanCard: View {
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

// MARK: - Preview

#Preview("Optimized Paywall") {
    OptimizedPaywallView(storeService: StoreKitService())
}

