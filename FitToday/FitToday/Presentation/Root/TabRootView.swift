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

    @State private var isMaintenanceMode = false
    @State private var isForceUpdateRequired = false

    var body: some View {
        @Bindable var routerBinding = router
        TabView(selection: $routerBinding.selectedTab) {
            tabView(for: .home) {
                HomeView(resolver: resolver)
            }

            tabView(for: .workout) {
                WorkoutTabView(resolver: resolver)
            }

            tabView(for: .fitpal) {
                AIChatView(resolver: resolver)
            }

            tabView(for: .activity) {
                ActivityTabView(resolver: resolver)
            }

            tabView(for: .profile) {
                ProfileProView()
            }
        }
        .task {
            await checkOperationalFlags()
        }
        .overlay {
            if isMaintenanceMode {
                MaintenanceOverlayView()
            }
        }
        .fullScreenCover(isPresented: $isForceUpdateRequired) {
            ForceUpdateView()
        }
    }

    private func checkOperationalFlags() async {
        guard let featureFlags = resolver.resolve(FeatureFlagChecking.self) else { return }
        try? await featureFlags.refreshFlags()
        isMaintenanceMode = await featureFlags.isFeatureEnabled(.maintenanceModeEnabled)
        isForceUpdateRequired = await featureFlags.isFeatureEnabled(.forceUpdateEnabled)
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
        case .workoutPlan:
            WorkoutPlanView()
        case .exerciseDetail:
            WorkoutExerciseDetailView()
        case .workoutExecution:
            WorkoutExecutionView()
        case .workoutExercisePreview(let prescription):
            WorkoutExercisePreviewView(prescription: prescription)
        case .workoutSummary:
            WorkoutCompletionView()
        case .paywall:
            if let repo = resolver.resolve(EntitlementRepository.self) as? StoreKitEntitlementRepository {
                OptimizedPaywallView(storeService: repo.service) {
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
        case .programWorkoutDetail(let workout):
            ProgramWorkoutDetailView(workout: workout, resolver: resolver)
        case .workoutPreview(let workout):
            WorkoutPreviewView(workout: workout, resolver: resolver)
        case .libraryWorkoutDetail(let workoutId):
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
            if let saveUseCase = resolver.resolve(SaveCustomWorkoutUseCase.self) {
                let exerciseService = resolver.resolve((any ExerciseServiceProtocol).self)
                let viewModel = CustomWorkoutBuilderViewModel(
                    saveUseCase: saveUseCase,
                    existingTemplateId: templateId,
                    exerciseService: exerciseService
                )
                CustomWorkoutBuilderView(viewModel: viewModel)
            } else {
                PlaceholderView(
                    title: "Custom Workout",
                    message: "Unable to load workout builder."
                )
            }
        case .personalTrainer:
            PersonalTrainerView(resolver: resolver)
        case .trainerSearch:
            let viewModel = PersonalTrainerViewModel(resolver: resolver)
            TrainerSearchView(viewModel: viewModel)
        case .cmsWorkoutDetail(let workoutId):
            CMSWorkoutDetailView(workoutId: workoutId, resolver: resolver)
        case .cmsWorkoutFeedback(let workoutId):
            CMSWorkoutFeedbackView(workoutId: workoutId, resolver: resolver)
        case .aiChat:
            AIChatView(resolver: resolver)
        }
    }
}

// MARK: - Maintenance Overlay

private struct MaintenanceOverlayView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: FitTodaySpacing.lg) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 56))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text("operational.maintenance.title".localized)
                    .font(FitTodayFont.ui(size: 24, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text("operational.maintenance.message".localized)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Force Update View

private struct ForceUpdateView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: FitTodaySpacing.lg) {
                Image(systemName: "arrow.down.app")
                    .font(.system(size: 56))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text("operational.force_update.title".localized)
                    .font(FitTodayFont.ui(size: 24, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text("operational.force_update.message".localized)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button {
                    if let url = URL(string: "https://apps.apple.com/app/fittoday") {
                        openURL(url)
                    }
                } label: {
                    Text("operational.force_update.button".localized)
                        .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(FitTodayColor.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
            }
        }
        .interactiveDismissDisabled()
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

    func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry] {
        let filtered = entries
            .filter { $0.source == .app && $0.workoutPlan != nil }
            .sorted { $0.date > $1.date }
        return Array(filtered.prefix(limit))
    }
}
