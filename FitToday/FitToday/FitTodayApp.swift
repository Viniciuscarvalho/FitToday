//
//  FitTodayApp.swift
//  FitToday
//
//  Created by Vinicius Carvalho on 03/01/26.
//

import SwiftData
import SwiftUI
import Swinject

@main
struct FitTodayApp: App {
    private let appContainer: AppContainer
    // 💡 Learn: Com @Observable, use @State em vez de @StateObject
    @State private var sessionStore: WorkoutSessionStore

    init() {
        // Bootstrap de segredos (apenas Debug) - popula Keychain a partir de Secrets.plist
        KeychainBootstrap.runIfNeeded()

        let container = AppContainer.build()
        self.appContainer = container
        sessionStore = WorkoutSessionStore(resolver: container.container)
        
        // Configurar aparência global para tema escuro
        configureGlobalAppearance()
        
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
            TabRootView()
                // 💡 Learn: Com @Observable, use .environment() em vez de .environmentObject()
                .environment(appContainer.router)
                .environment(sessionStore)
                .environment(\.dependencyResolver, appContainer.container)
                .imageCacheService(appContainer.container.resolve(ImageCaching.self)!)
                .preferredColorScheme(.dark)  // Forçar tema escuro
                .onOpenURL { url in
                    appContainer.router.handle(url: url)
                }
        }
        .modelContainer(appContainer.modelContainer)
    }
    
    /// Configura a aparência global de UIKit components para tema escuro
    private func configureGlobalAppearance() {
        // Tab Bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(FitTodayColor.background)
        
        // Cores dos ícones
        let normalColor = UIColor(FitTodayColor.textSecondary)
        let selectedColor = UIColor(FitTodayColor.brandPrimary)
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Navigation Bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(FitTodayColor.background)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(FitTodayColor.brandPrimary)
        
        // Scroll View e TableView backgrounds
        UITableView.appearance().backgroundColor = UIColor(FitTodayColor.background)
        UICollectionView.appearance().backgroundColor = UIColor(FitTodayColor.background)
    }
}
