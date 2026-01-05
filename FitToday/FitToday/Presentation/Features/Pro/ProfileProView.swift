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
        .navigationBarTitleDisplayMode(.large)
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
                
                SettingsRow(icon: "flame", title: "Refazer Questionário Diário") {
                    resetDailyCheckIn()
                    router.push(.dailyQuestionnaire, on: .profile)
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
                
                SettingsRow(icon: "questionmark.circle", title: "Ajuda e Suporte") {
                    openSupportURL()
                }
            }
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
        }
    }
    
    private func resetDailyCheckIn() {
        // Limpa o questionário do dia para permitir responder novamente
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.lastDailyCheckInDate)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.lastDailyCheckInData)
        DailyWorkoutStateManager.shared.resetForNewDay()
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
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    Button {
                        resetAIUsageCounter()
                    } label: {
                        HStack(spacing: FitTodaySpacing.md) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Resetar contador de IA")
                                    .font(.system(.body))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                Text("Limpa o limite diário de uso da OpenAI")
                                    .font(.system(.caption))
                                    .foregroundStyle(FitTodayColor.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(FitTodayColor.textTertiary)
                        }
                        .padding()
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    Button {
                        clearExerciseDBCache()
                    } label: {
                        HStack(spacing: FitTodaySpacing.md) {
                            Image(systemName: "photo.stack")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Limpar cache de mídias")
                                    .font(.system(.body))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                Text("Força nova busca de imagens do ExerciseDB")
                                    .font(.system(.caption))
                                    .foregroundStyle(FitTodayColor.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(FitTodayColor.textTertiary)
                        }
                        .padding()
                    }
                    .buttonStyle(.plain)
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
    
    private func resetAIUsageCounter() {
        // Limpa o registro de uso diário da OpenAI
        UserDefaults.standard.removeObject(forKey: "openai_usage_records")
        
        // Feedback visual
        restoreMessage = "Contador de IA resetado! Você pode gerar novos treinos com IA."
        showingRestoreAlert = true
    }
    
    private func clearExerciseDBCache() {
        // Limpa o mapeamento de IDs do ExerciseDB
        UserDefaults.standard.removeObject(forKey: "exercisedb_id_mapping_v1")
        
        // Feedback visual
        restoreMessage = "Cache de mídias limpo! As imagens serão buscadas novamente."
        showingRestoreAlert = true
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
    var badge: String? = nil
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
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, FitTodaySpacing.sm)
                        .padding(.vertical, FitTodaySpacing.xs)
                        .background(FitTodayColor.warning)
                        .cornerRadius(FitTodayRadius.pill)
                }
                
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

