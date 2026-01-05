//
//  AppRouter.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation
import Combine
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case home
    case library
    case history
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .library: return "Biblioteca"
        case .history: return "Histórico"
        case .profile: return "Perfil"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .library: return "books.vertical"
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
    case libraryDetail(String)
    case libraryExerciseDetail(ExercisePrescription)  // Detalhe de exercício na biblioteca
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

@MainActor
final class AppRouter: ObservableObject, AppRouting {
    @Published var selectedTab: AppTab = .home
    @Published var tabPaths: [AppTab: NavigationPath] = [:]

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

