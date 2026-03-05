//
//  FitTodayApp.swift
//  FitToday
//
//  Created by Vinicius Carvalho on 03/01/26.
//

import FirebaseCore
import SwiftData
import SwiftUI
import Swinject

@main
struct FitTodayApp: App {
    private let appContainer: AppContainer
    // 💡 Learn: Com @Observable, use @State em vez de @StateObject
    @State private var sessionStore: WorkoutSessionStore
    @AppStorage(AppStorageKeys.hasSeenWelcome) private var hasSeenWelcome = false
    @AppStorage(AppStorageKeys.themePreference) private var themePreferenceRaw: String = ThemePreference.dark.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Bootstrap de segredos (apenas Debug) - popula Keychain a partir de Secrets.plist
        KeychainBootstrap.runIfNeeded()

        let container = AppContainer.build()
        self.appContainer = container
        sessionStore = WorkoutSessionStore(resolver: container.container)
        
        // Configurar aparência global para tema escuro
        configureGlobalAppearance()

        // Record first launch date (once)
        if UserDefaults.standard.object(forKey: AppStorageKeys.firstLaunchDate) == nil {
            UserDefaults.standard.set(Date(), forKey: AppStorageKeys.firstLaunchDate)
        }

        // Prune stale exercise image cache (background, no impact on cold start)
        Task.detached(priority: .background) {
            await ExerciseImageCache.shared.pruneOldCache()
        }
        
        #if DEBUG
        // Log de inicialização
        print("═══════════════════════════════════════════")
        print("[FitToday] 🚀 App inicializado")
        print("[FitToday] Debug mode: ativo")
        print("[FitToday] DebugEntitlementOverride enabled: \(DebugEntitlementOverride.shared.isEnabled)")
        print("[FitToday] DebugEntitlementOverride isPro: \(DebugEntitlementOverride.shared.isPro)")
        print("═══════════════════════════════════════════")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenWelcome {
                    TabRootView()
                } else {
                    WelcomeOnboardingView()
                }
            }
            // 💡 Learn: Com @Observable, use .environment() em vez de .environmentObject()
            .environment(appContainer.router)
            .environment(sessionStore)
            .environment(\.dependencyResolver, appContainer.container)
            .preferredColorScheme(ThemePreference(rawValue: themePreferenceRaw)?.colorScheme ?? .dark)
            .onOpenURL { url in
                appContainer.router.handle(url: url)
            }
            .onAppear {
                setupNetworkMonitor()
            }
        }
        .modelContainer(appContainer.modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await processPendingQueue()
                    await syncHealthKitWorkoutsIfAuthorized()
                }
            }
        }
    }

    // MARK: - Offline Sync Queue Processing

    /// Process pending sync queue when app becomes active or network is restored.
    private func processPendingQueue() async {
        guard let syncUseCase = appContainer.container.resolve(SyncWorkoutCompletionUseCase.self),
              let queue = appContainer.container.resolve(PendingSyncQueue.self) else {
            return
        }

        await queue.processQueue { entry in
            try await syncUseCase.performSync(entry: entry)
        }
    }

    /// Setup network monitor to process queue when connection is restored.
    private func setupNetworkMonitor() {
        guard let networkMonitor = appContainer.container.resolve(NetworkMonitor.self),
              let syncUseCase = appContainer.container.resolve(SyncWorkoutCompletionUseCase.self),
              let queue = appContainer.container.resolve(PendingSyncQueue.self) else {
            return
        }

        networkMonitor.onConnectionRestored = {
            await queue.processQueue { entry in
                try await syncUseCase.performSync(entry: entry)
            }
        }

        networkMonitor.startMonitoring()

        #if DEBUG
        print("[FitTodayApp] Network monitor configured for offline sync queue")
        #endif
    }
    
    // MARK: - HealthKit Auto-Sync

    /// Syncs HealthKit workouts on app launch if authorized.
    /// Imports external workouts and syncs existing app workouts.
    private func syncHealthKitWorkoutsIfAuthorized() async {
        guard let healthKitService = appContainer.container.resolve(HealthKitServicing.self),
              let syncService = appContainer.container.resolve(HealthKitHistorySyncService.self) else {
            #if DEBUG
            print("[FitTodayApp] HealthKit services not available for auto-sync")
            #endif
            return
        }

        // Check if HealthKit is authorized
        let authStatus = await healthKitService.authorizationState()
        guard authStatus == .authorized else {
            #if DEBUG
            print("[FitTodayApp] HealthKit not authorized (status: \(authStatus)), skipping auto-sync")
            #endif
            return
        }

        #if DEBUG
        print("[FitTodayApp] 🏃 Starting HealthKit auto-sync...")
        #endif

        do {
            // Import external workouts from last 7 days
            let importedCount = try await syncService.importExternalWorkouts(days: 7)
            #if DEBUG
            print("[FitTodayApp] ✅ Imported \(importedCount) external workouts from Apple Health")
            #endif

            // Sync existing app workouts with HealthKit data
            let syncedCount = try await syncService.syncLastDays(7)
            #if DEBUG
            print("[FitTodayApp] ✅ Synced \(syncedCount) app workouts with Apple Health")
            #endif
        } catch {
            #if DEBUG
            print("[FitTodayApp] ❌ HealthKit sync failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Configura a aparência global de UIKit components (adaptive para dark/light)
    private func configureGlobalAppearance() {
        let bgColor = UIColor(FitTodayColor.background)
        let textColor = UIColor(FitTodayColor.textPrimary)
        let normalColor = UIColor(FitTodayColor.textSecondary)
        let selectedColor = UIColor(FitTodayColor.brandPrimary)

        // Tab Bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = bgColor
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Navigation Bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = bgColor
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = selectedColor

        // Scroll View e TableView backgrounds
        UITableView.appearance().backgroundColor = bgColor
        UICollectionView.appearance().backgroundColor = bgColor
    }
}
