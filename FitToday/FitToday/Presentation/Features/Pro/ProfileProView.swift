//
//  ProfileProView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//  Refactored on 14/01/26 - Extracted components to separate files
//

import SwiftUI
import SwiftData
import Swinject

// 💡 Learn: View refatorada com componentes extraídos para manutenibilidade
// Seguindo diretriz de < 100 linhas por view
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
                ProfileHeader(entitlement: entitlement)

                subscriptionSection

                ProfileSettingsSection(
                    onEditProfile: { router.push(.onboarding, on: .profile) },
                    onRedoDailyQuestionnaire: redoDailyQuestionnaire,
                    onOpenHealthKit: { router.push(.healthKitSettings, on: .profile) },
                    onOpenPrivacySettings: { router.push(.privacySettings, on: .profile) },
                    onRestorePurchases: { Task { await restorePurchases() } },
                    onOpenSupport: openSupportURL
                )

                #if DEBUG
                DebugSection(
                    debugModeEnabled: $debugModeEnabled,
                    debugIsPro: $debugIsPro,
                    showingRestoreAlert: $showingRestoreAlert,
                    restoreMessage: $restoreMessage,
                    resolver: resolver,
                    onDebugModeChange: handleDebugModeChange,
                    onDebugProChange: handleDebugProChange
                )
                #endif

                AppInfoFooter()
            }
            .padding()
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadEntitlement() }
        .sheet(isPresented: $showingPaywall, onDismiss: {
            showingPaywall = false
        }) {
            paywallSheet
        }
        .alert("Restaurar Compras", isPresented: $showingRestoreAlert) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(title: "Assinatura", actionTitle: nil)

            SubscriptionCard(
                isPro: entitlement.isPro,
                onManageSubscription: openSubscriptionManagement,
                onShowPaywall: { showingPaywall = true }
            )
        }
    }

    // MARK: - Paywall Sheet

    @ViewBuilder
    private var paywallSheet: some View {
        if let repo = storeKitRepository {
            PaywallView(
                storeService: repo.service,
                onPurchaseSuccess: {
                    Task { await loadEntitlement() }
                },
                onDismiss: {}
            )
        }
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

    private func redoDailyQuestionnaire() {
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.lastDailyCheckInDate)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.lastDailyCheckInData)
        DailyWorkoutStateManager.shared.resetForNewDay()
        router.push(.dailyQuestionnaire, on: .profile)
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

    private func openSupportURL() {
        if let url = URL(string: "mailto:support@fittoday.app") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Debug Handlers

    #if DEBUG
    private func handleDebugModeChange(_ enabled: Bool) {
        DebugEntitlementOverride.shared.isEnabled = enabled
        if enabled {
            debugIsPro = DebugEntitlementOverride.shared.isPro
            handleDebugProChange(debugIsPro)
        } else {
            Task { await loadEntitlement() }
        }
    }

    private func handleDebugProChange(_ isPro: Bool) {
        DebugEntitlementOverride.shared.isPro = isPro
        entitlement = DebugEntitlementOverride.shared.entitlement
    }
    #endif
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileProView()
            .environment(\.dependencyResolver, Container())
            .environment(AppRouter())
    }
}
