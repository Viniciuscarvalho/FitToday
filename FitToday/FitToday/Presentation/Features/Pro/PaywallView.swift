//
//  PaywallView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import StoreKit
import Swinject

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    // 💡 Learn: Com @Observable, usamos @State em vez de @StateObject
    @State private var storeService: StoreKitService
    @State private var selectedProduct: Product?
    @State private var showingError = false
    @State private var errorMessage = ""

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
                    headerSection
                    benefitsSection
                    plansSection
                    ctaSection
                    alternativeSection
                    legalSection
                }
                .padding()
            }
            .background(
                ZStack {
                    FitTodayColor.background
                    RetroGridPattern(lineColor: FitTodayColor.gridLine.opacity(0.3), spacing: 40)  // Grid background
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
            .alert("Ops!", isPresented: $showingError) {
                Button("Ok", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: storeService.purchaseState) { _, newState in
                handlePurchaseStateChange(newState)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [FitTodayColor.brandPrimary, FitTodayColor.brandPrimary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.5))  // Neon glow

            Text("FitToday Pro")
                .font(FitTodayFont.display(size: 36, weight: .extraBold))  // Retro font
                .tracking(1.5)
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Treinos adaptados ao seu dia,\ntodo dia")
                .font(FitTodayFont.ui(size: 20, weight: .medium))  // Retro font
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FitTodaySpacing.lg)
    }
    
    // MARK: - Benefits
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            BenefitRow(
                icon: "sparkles",
                title: "Treinos personalizados diariamente",
                description: "Planos adaptados ao seu objetivo e nível"
            )
            BenefitRow(
                icon: "bandage",
                title: "Ajuste inteligente por dor muscular",
                description: "Respeitamos seu corpo e evitamos lesões"
            )
            BenefitRow(
                icon: "slider.horizontal.3",
                title: "Séries e repetições adaptadas",
                description: "Volume ajustado ao seu nível de experiência"
            )
            BenefitRow(
                icon: "dumbbell",
                title: "Treinos conforme equipamentos",
                description: "Academia completa, básica, casa ou peso corporal"
            )
            BenefitRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Histórico de treinos",
                description: "Acompanhe sua evolução dia a dia"
            )
            BenefitRow(
                icon: "photo.on.rectangle.angled",
                title: "Exercícios com imagens explicativas",
                description: "GIFs e fotos para execução correta"
            )
            BenefitRow(
                icon: "brain.head.profile",
                title: "Assistente de treino inteligente",
                description: "IA seleciona os melhores exercícios para você"
            )
            BenefitRow(
                icon: "heart.text.square",
                title: "Treinos ajustados a limitações físicas",
                description: "Adaptações para dores e condições informadas"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
                .retroGridOverlay(spacing: 30)  // Grid overlay
        )
        .techCornerBorders(length: 20, thickness: 2)  // Tech corners
        .cornerRadius(FitTodayRadius.lg)
    }
    
    // MARK: - Plans
    
    private var plansSection: some View {
        VStack(spacing: FitTodaySpacing.md) {
            if storeService.purchaseState == .loading && storeService.products.isEmpty {
                ProgressView()
                    .frame(height: 150)
            } else {
                ForEach(storeService.products, id: \.id) { product in
                    PlanCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isBestValue: product.id == StoreKitProductID.proYearly
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
    }
    
    // MARK: - CTA
    
    private var ctaSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button {
                Task {
                    await purchaseSelectedProduct()
                }
            } label: {
                if storeService.purchaseState == .purchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(ctaText)
                }
            }
            .fitPrimaryStyle()
            .disabled(selectedProduct == nil || storeService.purchaseState == .purchasing)
            .accessibilityLabel("Assinar plano Pro")
            .accessibilityHint("Concluir compra para liberar treinos adaptados")
            
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restaurar compras")
                    .font(FitTodayFont.ui(size: 15, weight: .medium))  // Retro font
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
            .accessibilityLabel("Restaurar compras anteriores")
            .accessibilityHint("Tente recuperar assinaturas já pagas")
        }
    }
    
    private var ctaText: String {
        guard let product = selectedProduct else { return "Assinar" }
        if let intro = product.introOfferDescription {
            return "Começar \(intro)"
        }
        return "Assinar por \(product.displayPrice)/\(product.periodDescription)"
    }
    
    // MARK: - Alternative
    
    private var alternativeSection: some View {
        Button {
            onDismiss()
            router.select(tab: .programs)
            dismiss()
        } label: {
            Text("Ver treinos gratuitos na Biblioteca")
                .font(FitTodayFont.ui(size: 15, weight: .medium))  // Retro font
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }
    
    // MARK: - Legal
    
    private var legalSection: some View {
        VStack(spacing: FitTodaySpacing.xs) {
            Text("Assinatura renovada automaticamente. Cancele a qualquer momento nas configurações do iPhone.")
                .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: FitTodaySpacing.md) {
                Link("Termos de Uso", destination: URL(string: "https://fittoday.app/terms")!)
                Text("•")
                Link("Privacidade", destination: URL(string: "https://fittoday.app/privacy")!)
            }
            .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
            .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .padding(.top, FitTodaySpacing.md)
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
            errorMessage = "Nenhuma assinatura encontrada para restaurar."
            showingError = true
        }
    }
    
    private func handlePurchaseStateChange(_ state: StoreKitService.PurchaseState) {
        if case .failed(let message) = state {
            errorMessage = message
            showingError = true
        }
    }
}

// MARK: - Subviews

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.md) {
            Image(systemName: icon)
                .font(.system(.title2))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 32)
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))  // Neon glow

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))  // Retro font
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text(description)
                    .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
    }
}

private struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(FitTodayFont.ui(size: 17, weight: .semiBold))  // Retro font
                        if isBestValue {
                            Text("MELHOR VALOR")
                                .font(FitTodayFont.accent(size: 9))  // Bungee retro font
                                .tracking(0.5)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FitTodayColor.brandPrimary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    if let intro = product.introOfferDescription {
                        Text(intro)
                            .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
                            .foregroundStyle(FitTodayColor.brandPrimary)
                    }

                    if product.id == StoreKitProductID.proYearly {
                        Text("\(product.localizedPricePerMonth)/mês")
                            .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(FitTodayFont.display(size: 20, weight: .bold))  // Retro font
                    Text(product.periodDescription)
                        .font(FitTodayFont.ui(size: 12, weight: .medium))  // Retro font
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            }
            .padding()
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .fill(FitTodayColor.brandPrimary.opacity(0.1))
                            .diagonalStripes(color: FitTodayColor.neonCyan, spacing: 10, opacity: 0.15)  // Diagonal stripes
                    } else {
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .fill(FitTodayColor.surface)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(isSelected ? FitTodayColor.neonCyan : FitTodayColor.outline.opacity(0.3), lineWidth: isSelected ? 2 : 1)  // Neon cyan border
            )
            .techCornerBorders(color: isSelected ? FitTodayColor.neonCyan : FitTodayColor.techBorder.opacity(0.3), length: 14, thickness: 1.5)  // Tech corners
        }
        .buttonStyle(.plain)
        .foregroundStyle(FitTodayColor.textPrimary)
        .fitGlowEffect(color: isSelected ? FitTodayColor.neonCyan.opacity(0.2) : Color.clear.opacity(0))  // Glow when selected
    }
}

#Preview {
    PaywallView(storeService: StoreKitService())
}

