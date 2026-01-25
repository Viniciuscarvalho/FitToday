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
    case programs
    case history
    case settings

    var title: String {
        switch self {
        case .home: return "tab.home".localized
        case .programs: return "tab.programs".localized
        case .history: return "tab.history".localized
        case .settings: return "tab.settings".localized
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .programs: return "square.grid.2x2.fill"
        case .history: return "calendar"
        case .settings: return "gearshape.fill"
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
    case privacySettings  // Privacy settings for social features
    case authentication(inviteContext: String?)  // Authentication flow
    case groupInvite(groupId: String)  // Group invitation deep link
}

struct DeepLink {
    enum Destination {
        case home
        case onboarding
        case setup
        case dailyQuestionnaire
        case paywall
        case groupInvite(groupId: String)
    }

    let destination: Destination

    init?(url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "fittoday" else {
            return nil
        }

        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()

        // Handle group invite: fittoday://group/invite/{groupId}
        if host == "group", path.hasPrefix("/invite/") {
            let groupId = String(path.dropFirst("/invite/".count))
            destination = .groupInvite(groupId: groupId)
            return
        }

        // Handle other routes
        let pathOrHost = !host.isEmpty ? host : path
        switch pathOrHost {
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
        case .groupInvite(let groupId):
            select(tab: .home)
            push(.groupInvite(groupId: groupId), on: .home)
        }
    }

    func handle(url: URL) {
        guard let link = DeepLink(url: url) else { return }
        handle(deeplink: link)
    }
}

