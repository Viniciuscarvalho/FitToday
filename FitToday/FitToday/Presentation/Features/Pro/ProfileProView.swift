//
//  ProfileProView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

struct ProfileProView: View {
    @Environment(\.dependencyResolver) private var resolver
    @EnvironmentObject private var router: AppRouter
    @State private var entitlement: ProEntitlement = .free
    @State private var showingPaywall = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    
    // Debug mode state
    #if DEBUG
    @State private var debugModeEnabled = false
    @State private var debugIsPro = false
    #endif
    
    private var entitlementRepository: EntitlementRepository? {
        resolver.resolve(EntitlementRepository.self)
    }
    
    private var storeKitRepository: StoreKitEntitlementRepository? {
        resolver.resolve(EntitlementRepository.self) as? StoreKitEntitlementRepository
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                profileHeader
                subscriptionSection
                settingsSection
                #if DEBUG
                debugSection
                #endif
                appInfoSection
            }
            .padding()
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Perfil")
        .task {
            await loadEntitlement()
        }
        .sheet(isPresented: $showingPaywall) {
            if let repo = storeKitRepository {
                PaywallView(storeService: repo.service) {
                    Task {
                        await loadEntitlement()
                    }
                }
            }
        }
        .alert("Restaurar Compras", isPresented: $showingRestoreAlert) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Circle()
                .fill(FitTodayColor.brandPrimary.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(FitTodayColor.brandPrimary)
                )
            
            if entitlement.isPro {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(FitTodayColor.brandPrimary)
                    Text("Assinante Pro")
                        .font(.system(.headline, weight: .semibold))
                }
                
                if let expiration = entitlement.expirationDate {
                    Text("Renova em \(expiration.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            } else {
                Text("Usuário Free")
                    .font(.system(.headline))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FitTodaySpacing.lg)
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(title: "Assinatura", actionTitle: nil)
            
            if entitlement.isPro {
                proSubscriptionCard
            } else {
                freeSubscriptionCard
            }
        }
    }
    
    private var proSubscriptionCard: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("FitToday Pro Ativo")
                        .font(.system(.headline, weight: .semibold))
                }
                
                Text("Você tem acesso a todos os recursos premium, incluindo treinos adaptados e questionário diário.")
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)
                
                Button {
                    openSubscriptionManagement()
                } label: {
                    Text("Gerenciar Assinatura")
                        .font(.system(.subheadline, weight: .medium))
                }
            }
        }
    }
    
    private var freeSubscriptionCard: some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
                HStack {
                    Image(systemName: "star.circle")
                        .foregroundStyle(FitTodayColor.brandPrimary)
                    Text("Desbloqueie o Pro")
                        .font(.system(.headline, weight: .semibold))
                }
                
                Text("Tenha treinos adaptados ao seu dia, ajuste por dor muscular e muito mais.")
                    .font(.system(.subheadline))
                    .foregroundStyle(FitTodayColor.textSecondary)
                
                Button {
                    showingPaywall = true
                } label: {
                    Text("Ver Planos")
                }
                .fitPrimaryStyle()
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(title: "Configurações", actionTitle: nil)
            
            VStack(spacing: 0) {
                SettingsRow(icon: "person.text.rectangle", title: "Editar Perfil de Treino") {
                    router.push(.onboarding, on: .profile)
                }
                
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(icon: "arrow.counterclockwise", title: "Restaurar Compras") {
                    Task {
                        await restorePurchases()
                    }
                }
                
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(icon: "bell", title: "Notificações") {
                    openNotificationSettings()
                }
                
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(icon: "questionmark.circle", title: "Ajuda e Suporte") {
                    openSupportURL()
                }
            }
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
        }
    }
    
    // MARK: - Debug Section (only in DEBUG builds)
    
    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(title: "🛠 Modo Debug", actionTitle: nil)
            
            VStack(spacing: 0) {
                Toggle(isOn: $debugModeEnabled) {
                    HStack(spacing: FitTodaySpacing.md) {
                        Image(systemName: "ladybug.fill")
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ativar Modo Debug")
                                .font(.system(.body))
                                .foregroundStyle(FitTodayColor.textPrimary)
                            Text("Sobrescreve o status real do StoreKit")
                                .font(.system(.caption))
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }
                }
                .tint(FitTodayColor.brandPrimary)
                .padding()
                .onChange(of: debugModeEnabled) { _, enabled in
                    handleDebugModeChange(enabled)
                }
                
                if debugModeEnabled {
                    Divider()
                        .padding(.leading, 56)
                    
                    Toggle(isOn: $debugIsPro) {
                        HStack(spacing: FitTodaySpacing.md) {
                            Image(systemName: debugIsPro ? "crown.fill" : "person.fill")
                                .foregroundStyle(debugIsPro ? .yellow : FitTodayColor.textSecondary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(debugIsPro ? "Modo Pro" : "Modo Free")
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                Text("Simular status de assinatura")
                                    .font(.system(.caption))
                                    .foregroundStyle(FitTodayColor.textSecondary)
                            }
                        }
                    }
                    .tint(.yellow)
                    .padding()
                    .onChange(of: debugIsPro) { _, isPro in
                        handleDebugProChange(isPro)
                    }
                }
            }
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.md)
                    .stroke(.orange.opacity(0.5), lineWidth: 1)
            )
            
            Text("⚠️ Esta seção é visível apenas em builds de desenvolvimento.")
                .font(.system(.caption2))
                .foregroundStyle(.orange)
                .padding(.horizontal, FitTodaySpacing.sm)
        }
    }
    
    private func handleDebugModeChange(_ enabled: Bool) {
        DebugEntitlementOverride.shared.isEnabled = enabled
        if enabled {
            debugIsPro = DebugEntitlementOverride.shared.isPro
            handleDebugProChange(debugIsPro)
        } else {
            // Restaurar status real
            Task {
                await loadEntitlement()
            }
        }
    }
    
    private func handleDebugProChange(_ isPro: Bool) {
        DebugEntitlementOverride.shared.isPro = isPro
        entitlement = DebugEntitlementOverride.shared.entitlement
    }
    #endif
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Text("FitToday v\(appVersion)")
                .font(.system(.caption))
                .foregroundStyle(FitTodayColor.textSecondary)
            
            HStack(spacing: FitTodaySpacing.md) {
                Link("Termos", destination: URL(string: "https://fittoday.app/terms")!)
                Text("•")
                Link("Privacidade", destination: URL(string: "https://fittoday.app/privacy")!)
            }
            .font(.system(.caption))
            .foregroundStyle(FitTodayColor.brandPrimary)
        }
        .padding(.top, FitTodaySpacing.lg)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // MARK: - Actions
    
    private func loadEntitlement() async {
        #if DEBUG
        if DebugEntitlementOverride.shared.isEnabled {
            entitlement = DebugEntitlementOverride.shared.entitlement
            debugModeEnabled = true
            debugIsPro = DebugEntitlementOverride.shared.isPro
            return
        }
        #endif
        
        if let repo = entitlementRepository {
            do {
                entitlement = try await repo.currentEntitlement()
            } catch {
                print("Failed to load entitlement: \(error)")
            }
        }
    }
    
    private func restorePurchases() async {
        guard let repo = storeKitRepository else { return }
        let restored = await repo.service.restorePurchases()
        if restored {
            await loadEntitlement()
            restoreMessage = "Sua assinatura foi restaurada com sucesso!"
        } else {
            restoreMessage = "Nenhuma assinatura encontrada para restaurar."
        }
        showingRestoreAlert = true
    }
    
    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSupportURL() {
        if let url = URL(string: "mailto:support@fittoday.app") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Subviews

private struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FitTodaySpacing.md) {
                Image(systemName: icon)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(.caption))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProfileProView()
            .environment(\.dependencyResolver, Container())
            .environmentObject(AppRouter())
    }
}

