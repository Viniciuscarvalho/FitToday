//
//  TabRootView.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import SwiftUI
import Swinject

struct TabRootView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @Environment(\.dependencyResolver) private var resolver

    var body: some View {
        TabView(selection: $router.selectedTab) {
            tabView(for: .home) {
                HomeView(resolver: resolver)
            }

            tabView(for: .library) {
                LibraryView(resolver: resolver)
            }

            tabView(for: .history) {
                HistoryView(resolver: resolver)
            }

            tabView(for: .profile) {
                ProfileProView()
            }
        }
    }

    private func tabView(for tab: AppTab, @ViewBuilder content: () -> some View) -> some View {
        NavigationStack(path: pathBinding(for: tab)) {
            content()
                .navigationTitle(tab.title)
                .navigationDestination(for: AppRoute.self) { route in
                    routeDestination(for: route)
                }
        }
        .tabItem {
            Label(tab.title, systemImage: tab.systemImage)
        }
        .tag(tab)
    }

    private func pathBinding(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { router.tabPaths[tab] ?? NavigationPath() },
            set: { router.tabPaths[tab] = $0 }
        )
    }

    @ViewBuilder
    private func routeDestination(for route: AppRoute) -> some View {
        switch route {
        case .onboarding:
            OnboardingFlowView(resolver: resolver, isEditing: false) {
                // Pop da tab atual (pode ser home ou profile)
                router.pop(on: router.selectedTab)
            }
        case .editProfile:
            OnboardingFlowView(resolver: resolver, isEditing: true) {
                // Pop da tab atual
                router.pop(on: router.selectedTab)
            }
        case .setup:
            PlaceholderView(
                title: "Setup Inicial",
                message: "Stepper com 6 perguntas será implementado aqui."
            )
        case .dailyQuestionnaire:
            DailyQuestionnaireFlowView(resolver: resolver) { result in
                switch result {
                case .planReady:
                    UserDefaults.standard.set(Date(), forKey: AppStorageKeys.lastDailyCheckInDate)
                    // Primeiro pop o questionário, depois navega para o workout
                    router.pop(on: .home)
                    if let planId = sessionStore.plan?.id {
                        router.push(.workoutPlan(planId), on: .home)
                    }
                case .paywallRequired:
                    router.push(.paywall, on: .home)
                }
            }
        case .workoutPlan:
            WorkoutPlanView()
        case .exerciseDetail:
            WorkoutExerciseDetailView()
        case .workoutSummary:
            WorkoutCompletionView()
        case .paywall:
            if let repo = resolver.resolve(EntitlementRepository.self) as? StoreKitEntitlementRepository {
                PaywallView(storeService: repo.service) {
                    // On purchase success, generate workout
                    if let planId = sessionStore.plan?.id {
                        router.pop(on: .home) // Pop paywall
                        router.push(.workoutPlan(planId), on: .home)
                    } else {
                        router.pop(on: .home)
                    }
                } onDismiss: {
                    router.pop(on: .home)
                }
            } else {
                PlaceholderView(
                    title: "Paywall Pro",
                    message: "Erro ao carregar paywall."
                )
            }
        case .libraryDetail(let workoutId):
            LibraryDetailView(workoutId: workoutId, resolver: resolver)
        case .libraryExerciseDetail(let prescription):
            LibraryExerciseDetailView(prescription: prescription)
        }
    }
}

private struct PlaceholderView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    let container = Container()
    container.register(UserProfileRepository.self) { _ in InMemoryProfileRepository() }
    container.register(EntitlementRepository.self) { _ in InMemoryEntitlementRepository() }
    container.register(WorkoutHistoryRepository.self) { _ in InMemoryHistoryRepository() }
    let sessionStore = WorkoutSessionStore(resolver: container)
    return TabRootView()
        .environmentObject(AppRouter())
        .environmentObject(sessionStore)
        .environment(\.dependencyResolver, container)
}

private final class InMemoryProfileRepository: UserProfileRepository, @unchecked Sendable {
    private var profile: UserProfile?
    func loadProfile() async throws -> UserProfile? { profile }
    func saveProfile(_ profile: UserProfile) async throws { self.profile = profile }
}

private final class InMemoryEntitlementRepository: EntitlementRepository, @unchecked Sendable {
    func currentEntitlement() async throws -> ProEntitlement { .free }
    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { continuation in continuation.finish() }
    }
}

private final class InMemoryHistoryRepository: WorkoutHistoryRepository {
    private var entries: [WorkoutHistoryEntry] = []

    func listEntries() async throws -> [WorkoutHistoryEntry] {
        entries
    }

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        entries.append(entry)
    }
}
