//
//  AppRouter.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case home
    case programs  // Renomeado de library
    case history
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .programs: return "Programas"
        case .history: return "Histórico"
        case .profile: return "Perfil"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .programs: return "rectangle.stack.fill"
        case .history: return "clock.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

enum AppRoute: Hashable {
    case onboarding
    case editProfile  // Rota separada para edição de perfil existente
    case setup
    case dailyQuestionnaire
    case workoutPlan(UUID)
    case exerciseDetail
    case workoutExercisePreview(ExercisePrescription)  // Preview de exercício (não altera índice)
    case workoutSummary
    case paywall
    case programDetail(String)  // Detalhe do programa
    case programWorkoutDetail(String)  // Detalhe de um treino dentro do programa
    case programExerciseDetail(ExercisePrescription)  // Detalhe de exercício na biblioteca/programa
    case apiKeySettings  // Configuração de chave de API do usuário
    case healthKitSettings // Integração Apple Health (PRO)
}

struct DeepLink {
    enum Destination {
        case home
        case onboarding
        case setup
        case dailyQuestionnaire
        case paywall
    }

    let destination: Destination

    init?(url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "fittoday" else {
            return nil
        }

        let path = url.host?.lowercased() ?? url.path.lowercased()
        switch path {
        case "home", "/home":
            destination = .home
        case "onboarding", "/onboarding":
            destination = .onboarding
        case "setup", "/setup":
            destination = .setup
        case "daily", "/daily":
            destination = .dailyQuestionnaire
        case "paywall", "/paywall":
            destination = .paywall
        default:
            return nil
        }
    }
}

@MainActor
protocol AppRouting: AnyObject {
    var selectedTab: AppTab { get set }
    var tabPaths: [AppTab: NavigationPath] { get set }

    func select(tab: AppTab)
    func push(_ route: AppRoute, on tab: AppTab?)
    func pop(on tab: AppTab?)
    func handle(deeplink: DeepLink)
}

// 💡 Learn: Navegação com @Observable permite melhor performance
@MainActor
@Observable final class AppRouter: AppRouting {
    var selectedTab: AppTab = .home
    var tabPaths: [AppTab: NavigationPath] = [:]

    init() {
        AppTab.allCases.forEach { tab in
            tabPaths[tab] = NavigationPath()
        }
    }

    func select(tab: AppTab) {
        selectedTab = tab
    }

    func push(_ route: AppRoute, on tab: AppTab? = nil) {
        let target = tab ?? selectedTab
        if tabPaths[target] == nil {
            tabPaths[target] = NavigationPath()
        }
        tabPaths[target]?.append(route)
    }

    func pop(on tab: AppTab? = nil) {
        let target = tab ?? selectedTab
        guard var path = tabPaths[target], !path.isEmpty else {
            return
        }
        path.removeLast()
        tabPaths[target] = path
    }

    func handle(deeplink: DeepLink) {
        switch deeplink.destination {
        case .home:
            select(tab: .home)
        case .onboarding:
            select(tab: .home)
            push(.onboarding, on: .home)
        case .setup:
            select(tab: .home)
            push(.setup, on: .home)
        case .dailyQuestionnaire:
            select(tab: .home)
            push(.dailyQuestionnaire, on: .home)
        case .paywall:
            select(tab: .home)
            push(.paywall, on: .home)
        }
    }

    func handle(url: URL) {
        guard let link = DeepLink(url: url) else { return }
        handle(deeplink: link)
    }
}

