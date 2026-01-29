//
//  TabRootView.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import SwiftUI
import Swinject

struct TabRootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @Environment(\.dependencyResolver) private var resolver

    @State private var showCreateWorkout = false

    var body: some View {
        // 💡 Learn: @Bindable wrapper permite binding de @Observable objects
        @Bindable var routerBinding = router
        TabView(selection: $routerBinding.selectedTab) {
            tabView(for: .home) {
                HomeView(resolver: resolver)
            }

            tabView(for: .workout) {
                WorkoutTabView(resolver: resolver)
            }

            // Create tab - center button that shows sheet
            tabView(for: .create) {
                Color.clear
                    .onAppear {
                        showCreateWorkout = true
                        // Switch back to workout tab
                        router.select(tab: .workout)
                    }
            }

            tabView(for: .activity) {
                ActivityTabView()
            }

            tabView(for: .profile) {
                ProfileProView()
            }
        }
        .sheet(isPresented: $showCreateWorkout) {
            CreateWorkoutView(resolver: resolver) {
                showCreateWorkout = false
            }
        }
    }

    private func tabView(for tab: AppTab, @ViewBuilder content: () -> some View) -> some View {
        NavigationStack(path: pathBinding(for: tab)) {
            content()
                .navigationDestination(for: AppRoute.self) { route in
                    routeDestination(for: route)
                }
        }
        .tabItem {
            // Icon-only tab items (no labels)
            Image(systemName: tab.systemImage)
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
                    #if DEBUG
                    print("[TabRoot] planReady recebido")
                    print("[TabRoot] sessionStore.plan?.id = \(sessionStore.plan?.id.uuidString ?? "nil")")
                    #endif
                    UserDefaults.standard.set(Date(), forKey: AppStorageKeys.lastDailyCheckInDate)
                    // Primeiro pop o questionário, depois navega para o workout
                    router.pop(on: .home)
                    if let planId = sessionStore.plan?.id {
                        #if DEBUG
                        print("[TabRoot] Navegando para workoutPlan: \(planId)")
                        #endif
                        router.push(.workoutPlan(planId), on: .home)
                    } else {
                        #if DEBUG
                        print("[TabRoot] ⚠️ sessionStore.plan é nil - não navegou!")
                        #endif
                    }
                case .paywallRequired:
                    #if DEBUG
                    print("[TabRoot] paywallRequired - mostrando paywall")
                    #endif
                    // Pop do questionário antes de mostrar o paywall para evitar
                    // "Unbalanced calls to begin/end appearance transitions"
                    router.pop(on: .home)
                    // Pequeno delay para permitir que a animação de pop complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        router.push(.paywall, on: .home)
                    }
                }
            }
        case .workoutPlan:
            WorkoutPlanView()
        case .exerciseDetail:
            WorkoutExerciseDetailView()
        case .workoutExercisePreview(let prescription):
            WorkoutExercisePreviewView(prescription: prescription)
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
        case .programDetail(let programId):
            ProgramDetailView(programId: programId, resolver: resolver)
        case .programWorkoutDetail(let workoutId):
            LibraryDetailView(workoutId: workoutId, resolver: resolver)
        case .programExerciseDetail(let prescription):
            LibraryExerciseDetailView(prescription: prescription)
        case .apiKeySettings:
            APIKeySettingsView()
        case .healthKitSettings:
            HealthKitConnectionView(resolver: resolver)
        case .privacySettings:
            PrivacySettingsView(resolver: resolver)
        case .authentication(let inviteContext):
            AuthenticationView(resolver: resolver, inviteContext: inviteContext) {
                // After authentication, pop back and stay on current tab
                router.pop(on: router.selectedTab)
            }
        case .groupInvite(let groupId):
            JoinGroupView(groupId: groupId, resolver: resolver) {
                // After joining, refresh activity tab (where challenges are shown)
                router.select(tab: .activity)
            }
        case .notifications:
            NotificationsView(resolver: resolver)
        case .customWorkouts:
            CustomWorkoutTemplatesView(resolver: resolver)
        case .customWorkoutBuilder(let templateId):
            if let saveUseCase = resolver.resolve(SaveCustomWorkoutUseCase.self),
               let exerciseService = resolver.resolve(ExerciseDBServicing.self) {
                let viewModel = CustomWorkoutBuilderViewModel(
                    saveUseCase: saveUseCase,
                    existingTemplateId: templateId
                )
                CustomWorkoutBuilderView(viewModel: viewModel)
            } else {
                PlaceholderView(
                    title: "Custom Workout",
                    message: "Unable to load workout builder."
                )
            }
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
        .environment(AppRouter())
        .environment(sessionStore)
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
        entries.sorted { $0.date > $1.date }
    }
    
    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        let sorted = entries.sorted { $0.date > $1.date }
        let start = min(offset, sorted.count)
        let end = min(offset + limit, sorted.count)
        return Array(sorted[start..<end])
    }
    
    func count() async throws -> Int {
        entries.count
    }

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        entries.append(entry)
    }
}
