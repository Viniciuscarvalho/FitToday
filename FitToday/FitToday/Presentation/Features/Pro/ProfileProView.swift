//
//  ProfileProView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import SwiftData
import Swinject

struct ProfileProView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadEntitlement()
        }
        .sheet(isPresented: $showingPaywall, onDismiss: {
            showingPaywall = false
        }, content: {
            if let repo = storeKitRepository {
                PaywallView(
                    storeService: repo.service,
                    onPurchaseSuccess: {
                        Task {
                            await loadEntitlement()
                        }
                    },
                    onDismiss: {}
                )
            }
        })
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
                
                SettingsRow(icon: "heart.fill", title: "Apple Health") {
                    router.push(.healthKitSettings, on: .profile)
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
                        clearExerciseDBMapping()
                    } label: {
                        HStack(spacing: FitTodaySpacing.md) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Limpar mapping de exercícios")
                                    .font(.system(.body))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                Text("Força re-match de exercícios locais → ExerciseDB")
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
                        clearExerciseDBTargetList()
                    } label: {
                        HStack(spacing: FitTodaySpacing.md) {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundStyle(.green)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Limpar cache de targets")
                                    .font(.system(.body))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                Text("Força nova busca da lista de músculos-alvo")
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
                        clearAllExerciseDBCaches()
                    } label: {
                        HStack(spacing: FitTodaySpacing.md) {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Limpar todos os caches ExerciseDB")
                                    .font(.system(.body, weight: .semibold))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                Text("Mapping + TargetList + Mídias resolvidas")
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
                        clearWorkoutCompositionCaches()
                    } label: {
                        HStack(spacing: FitTodaySpacing.md) {
                            Image(systemName: "figure.run.circle.fill")
                                .foregroundStyle(.cyan)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Limpar cache de treinos")
                                    .font(.system(.body, weight: .semibold))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                Text("Força nova geração de treinos via IA")
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
                        seedTestData()
                    } label: {
                        HStack(spacing: FitTodaySpacing.md) {
                            Image(systemName: "testtube.2")
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Criar dados de teste")
                                    .font(.system(.body, weight: .semibold))
                                    .foregroundStyle(FitTodayColor.textPrimary)
                                Text("Perfil + Pro + CheckIn (para debug)")
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
    
    /// Limpa o mapeamento persistido de exercícios locais → ExerciseDB.
    /// 
    /// **Checklist de Validação Manual:**
    /// 1. Abrir um exercício que não tinha mídia antes
    /// 2. Limpar o mapping usando este botão
    /// 3. Navegar para o mesmo exercício novamente
    /// 4. Verificar nos logs DEBUG se o exercício foi re-mapeado
    /// 5. Confirmar que a mídia aparece (se o match foi bem-sucedido)
    private func clearExerciseDBMapping() {
        // Limpa o mapeamento persistido de IDs do ExerciseDB
        // O cache em memória será limpo naturalmente quando o app recarregar
        UserDefaults.standard.removeObject(forKey: "exercisedb_id_mapping_v1")
        
        // Feedback visual
        restoreMessage = "Mapping de exercícios limpo! Os exercícios serão re-mapeados na próxima visualização."
        showingRestoreAlert = true
    }
    
    /// Limpa o cache persistido da lista de targets (músculos-alvo) do ExerciseDB.
    /// 
    /// **Checklist de Validação Manual:**
    /// 1. Verificar nos logs se o targetList foi carregado anteriormente
    /// 2. Limpar o cache usando este botão
    /// 3. Navegar para um exercício que usa resolução por target (ex: peito, bíceps)
    /// 4. Verificar nos logs DEBUG se o targetList foi recarregado da API
    /// 5. Confirmar que a resolução por target funciona corretamente
    private func clearExerciseDBTargetList() {
        // Limpa o cache persistido de targetList
        // O cache em memória será limpo naturalmente quando o app recarregar
        UserDefaults.standard.removeObject(forKey: "exercisedb_target_list_v1")
        UserDefaults.standard.removeObject(forKey: "exercisedb_target_list_timestamp_v1")
        
        // Feedback visual
        restoreMessage = "Cache de targets limpo! A lista será recarregada na próxima busca."
        showingRestoreAlert = true
    }
    
    /// Limpa todos os caches do ExerciseDB (mapping + targetList).
    /// 
    /// **Checklist de Validação Manual:**
    /// 1. Limpar todos os caches usando este botão
    /// 2. Navegar para um exercício com nome divergente (ex: "Lever Pec Deck Fly")
    /// 3. Verificar nos logs DEBUG o caminho completo de resolução:
    ///    - Target derivado e se foi válido
    ///    - Candidatos encontrados por target
    ///    - Scores dos top 3 candidatos
    ///    - Match escolhido ou fallback por nome
    /// 4. Confirmar que a mídia aparece após o re-match
    /// 5. Verificar que o mapping foi persistido para evitar nova busca
    private func clearAllExerciseDBCaches() {
        // Limpa todos os caches persistidos do ExerciseDB
        // Os caches em memória serão limpos naturalmente quando o app recarregar
        UserDefaults.standard.removeObject(forKey: "exercisedb_id_mapping_v1")
        UserDefaults.standard.removeObject(forKey: "exercisedb_target_list_v1")
        UserDefaults.standard.removeObject(forKey: "exercisedb_target_list_timestamp_v1")
        
        // Feedback visual
        restoreMessage = "Todos os caches do ExerciseDB foram limpos! O app fará novas buscas na próxima visualização."
        showingRestoreAlert = true
    }
    
    /// Limpa todos os caches de composição de treino (OpenAI + SwiftData).
    /// 
    /// **Checklist de Validação Manual:**
    /// 1. Limpar os caches usando este botão
    /// 2. Gerar um novo treino
    /// 3. Verificar nos logs DEBUG:
    ///    - [BlueprintInput] cacheKey deve variar
    ///    - [OpenAICache] deve mostrar MISS (não HIT)
    ///    - [DynamicHybrid] deve fazer nova chamada à OpenAI
    /// 4. Confirmar que o treino gerado tem exercícios diferentes
    private func clearWorkoutCompositionCaches() {
        Task {
            // 1. Limpar cache de composição (SwiftData)
            if let cacheRepo = resolver.resolve(WorkoutCompositionCacheRepository.self) {
                do {
                    try await cacheRepo.clearAll()
                    print("[Debug] ✅ Cache de composição (SwiftData) limpo")
                } catch {
                    print("[Debug] ⚠️ Erro ao limpar cache de composição: \(error)")
                }
            }
            
            // 2. Nota: O OpenAIResponseCache é em memória e será limpo ao reiniciar o app
            print("[Debug] ℹ️ Cache de respostas OpenAI (memória) será limpo ao reiniciar o app")
            
            // Feedback visual
            await MainActor.run {
                restoreMessage = "Caches de treino limpos! Reinicie o app para limpar o cache em memória da OpenAI. Novos treinos serão gerados na próxima requisição."
                showingRestoreAlert = true
            }
        }
    }
    
    /// Cria dados de teste para debug (Perfil + Pro + CheckIn)
    private func seedTestData() {
        Task {
            // 1. Criar perfil de teste
            if let modelContainer = resolver.resolve(ModelContainer.self) {
                await DebugDataSeeder.seedTestProfileIfNeeded(in: modelContainer.mainContext)
            }
            
            // 2. Ativar modo Pro
            DebugDataSeeder.enableProMode()
            debugModeEnabled = true
            debugIsPro = true
            
            // 3. Criar check-in de teste
            DebugDataSeeder.seedDailyCheckIn()
            
            // Feedback visual
            await MainActor.run {
                restoreMessage = "Dados de teste criados!\n\n• Perfil: Hipertrofia + Academia\n• Modo Pro: Ativado\n• Check-in: FullBody + Sem dor\n\nVá para Home e toque em 'Ver Treino de Hoje'"
                showingRestoreAlert = true
                
                // Atualizar estado local
                entitlement = DebugEntitlementOverride.shared.entitlement
            }
        }
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
            .environment(AppRouter())
    }
}

