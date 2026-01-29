//
//  ProfileProView.swift (Settings Tab)
//  FitToday
//
//  Redesigned on 23/01/26 - New Settings layout with Premium and Apple Health
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
                headerSection

                // Premium Card
                premiumCard

                // Apple Health Integration
                appleHealthCard

                // Profile Settings
                settingsSection

                // Account
                accountSection

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
            .padding(.bottom, FitTodaySpacing.xl)
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadEntitlement() }
        .sheet(isPresented: $showingPaywall) {
            paywallSheet
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("settings.title".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)
            Text("settings.subtitle".localized)
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, FitTodaySpacing.md)
    }

    // MARK: - Premium Card

    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: entitlement.isPro ? "crown.fill" : "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text(entitlement.isPro ? "settings.pro.member".localized : "settings.pro.free".localized)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(entitlement.isPro ? FitTodayColor.success : FitTodayColor.brandPrimary)
                .clipShape(Capsule())

                Spacer()
            }

            if entitlement.isPro {
                // Pro content
                Text("settings.pro.title".localized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("settings.pro.access_all".localized)
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.textSecondary)

                // Sync status
                HStack(spacing: FitTodaySpacing.md) {
                    syncStatusItem(icon: "checkmark.icloud.fill", label: "settings.pro.cloud_sync".localized, isActive: true)
                    syncStatusItem(icon: "heart.fill", label: "settings.pro.apple_health".localized, isActive: true)
                    syncStatusItem(icon: "bolt.fill", label: "settings.pro.ai_workouts".localized, isActive: true)
                }
                .padding(.top, 4)

                Button {
                    openSubscriptionManagement()
                } label: {
                    HStack {
                        Spacer()
                        Text("settings.pro.manage".localized)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .padding(.vertical, 12)
                    .background(FitTodayColor.brandPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                // Free plan upgrade prompt
                Text("settings.pro.upgrade".localized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text("settings.pro.unlock_description".localized)
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.textSecondary)

                // Features preview
                VStack(alignment: .leading, spacing: 8) {
                    featureItem(icon: "sparkles", text: "settings.pro.unlimited_ai".localized)
                    featureItem(icon: "icloud.fill", text: "settings.pro.cloud_devices".localized)
                    featureItem(icon: "heart.fill", text: "settings.pro.health_integration".localized)
                }
                .padding(.top, 4)

                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Spacer()
                        Text("settings.pro.try_free".localized)
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .background(FitTodayColor.gradientPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FitTodaySpacing.lg)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func syncStatusItem(icon: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isActive ? FitTodayColor.success : FitTodayColor.textTertiary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(FitTodayColor.textPrimary)
        }
    }

    // MARK: - Apple Health Card

    private var appleHealthCard: some View {
        Button {
            router.push(.healthKitSettings, on: .profile)
        } label: {
            HStack(spacing: FitTodaySpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#FF2D55").opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "#FF2D55"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.pro.apple_health".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                    Text(entitlement.isPro ? "settings.pro.connected".localized : "settings.pro.connect_sync".localized)
                        .font(.system(size: 13))
                        .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                if entitlement.isPro {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(FitTodayColor.success)
                } else {
                    Text("PRO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FitTodayColor.brandPrimary)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(FitTodayColor.textTertiary)
            }
            .padding(FitTodaySpacing.md)
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("settings.profile".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FitTodayColor.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                SettingsRow(icon: "person.text.rectangle", title: "settings.edit_profile".localized) {
                    router.push(.editProfile, on: .profile)
                }

                Divider().padding(.leading, 56)

                SettingsRow(icon: "flame", title: "settings.redo_questionnaire".localized) {
                    redoDailyQuestionnaire()
                }

                Divider().padding(.leading, 56)

                SettingsRow(icon: "lock.shield", title: "settings.privacy_settings".localized) {
                    router.push(.privacySettings, on: .profile)
                }

                Divider().padding(.leading, 56)

                languageRow
            }
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Language Row

    @MainActor
    private var languageRow: some View {
        let manager = LocalizationManager.shared
        return HStack(spacing: FitTodaySpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(FitTodayColor.brandPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }

            Text("settings.language".localized)
                .font(.system(size: 15))
                .foregroundStyle(FitTodayColor.textPrimary)

            Spacer()

            Menu {
                ForEach(LocalizationManager.Language.allCases) { language in
                    Button {
                        manager.setLanguage(language)
                    } label: {
                        HStack {
                            Text(language.displayName)
                            if manager.selectedLanguage == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(manager.selectedLanguage.displayName)
                        .font(.system(size: 14))
                        .foregroundStyle(FitTodayColor.textSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
            }
        }
        .padding(.horizontal, FitTodaySpacing.md)
        .padding(.vertical, FitTodaySpacing.sm)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            Text("settings.account".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FitTodayColor.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                SettingsRow(icon: "arrow.counterclockwise", title: "settings.restore_purchases".localized) {
                    Task { await restorePurchases() }
                }

                Divider().padding(.leading, 56)

                SettingsRow(icon: "questionmark.circle", title: "settings.help_support".localized) {
                    openSupportURL()
                }

                Divider().padding(.leading, 56)

                SettingsRow(icon: "key", title: "settings.api_key".localized) {
                    router.push(.apiKeySettings, on: .profile)
                }
            }
            .background(FitTodayColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
            restoreMessage = "settings.restore_success".localized
        } else {
            restoreMessage = "settings.restore_not_found".localized
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

#Preview {
    NavigationStack {
        ProfileProView()
            .environment(\.dependencyResolver, Container())
            .environment(AppRouter())
    }
}
