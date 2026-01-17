//
//  HomeView.swift
//  FitToday
//
//  Created by AI on 05/01/26.
//  Refactored on 15/01/26 - Extracted components to separate files
//

import SwiftUI
import Swinject

// 💡 Learn: View refatorada com componentes extraídos para manutenibilidade
// Seguindo diretriz de < 100 linhas por view
struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore

    @State private var viewModel: HomeViewModel
    @State private var isGeneratingPlan = false
    @State private var heroErrorMessage: String?

    init(resolver: Resolver?) {
        guard let resolver = resolver else {
            fatalError("Resolver is required for HomeView")
        }
        self._viewModel = State(wrappedValue: HomeViewModel(resolver: resolver))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.md) {
                HomeHeader(
                    greeting: viewModel.greeting,
                    dateFormatted: viewModel.currentDateFormatted,
                    isPro: viewModel.entitlement.isPro,
                    goalBadgeText: viewModel.goalBadgeText
                )

                HomeHeroCard(
                    journeyState: viewModel.journeyState,
                    isGeneratingPlan: isGeneratingPlan,
                    heroErrorMessage: heroErrorMessage,
                    onCreateProfile: { router.push(.onboarding, on: .home) },
                    onStartDailyCheckIn: { router.push(.dailyQuestionnaire, on: .home) },
                    onViewTodayWorkout: { openTodayWorkout() },
                    onGeneratePlan: { generateTodayWorkout() }
                )

                if !viewModel.topPrograms.isEmpty {
                    TopForYouSection(
                        programs: viewModel.topPrograms,
                        onProgramTap: { program in
                            router.push(.programDetail(program.id), on: .home)
                        }
                    )
                }

                if !viewModel.weekWorkouts.isEmpty {
                    WeeksWorkoutSection(
                        workouts: viewModel.weekWorkouts,
                        onWorkoutTap: { workout in
                            router.push(.programWorkoutDetail(workout.id), on: .home)
                        }
                    )
                }

                Spacer(minLength: FitTodaySpacing.xl)
            }
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            viewModel.onAppear()
        }
    }

    // MARK: - Actions

    private func openTodayWorkout() {
        // Need to implement logic to get current workout plan
        // For now, just navigate to daily questionnaire
        router.push(.dailyQuestionnaire, on: .home)
    }

    private func generateTodayWorkout() {
        guard !isGeneratingPlan else { return }

        Task {
            isGeneratingPlan = true
            heroErrorMessage = nil

            do {
                _ = try await viewModel.regenerateDailyWorkoutPlan()
                await viewModel.refresh()
            } catch {
                heroErrorMessage = "Erro ao gerar treino"
            }

            isGeneratingPlan = false
        }
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    container.register(UserProfileRepository.self) { _ in MockUserProfileRepository() }
    container.register(EntitlementRepository.self) { _ in MockEntitlementRepository() }
    container.register(ProgramRepository.self) { _ in BundleProgramRepository() }
    container.register(LibraryWorkoutsRepository.self) { _ in
        BundleLibraryWorkoutsRepository(mediaResolver: ExerciseMediaResolver(service: nil))
    }

    return NavigationStack {
        HomeView(resolver: container)
            .environment(AppRouter())
            .environment(WorkoutSessionStore(resolver: container))
    }
}

// MARK: - Preview Mocks

private final class MockUserProfileRepository: UserProfileRepository, @unchecked Sendable {
    func loadProfile() async throws -> UserProfile? {
        UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: 4
        )
    }

    func saveProfile(_ profile: UserProfile) async throws {}
}

private final class MockEntitlementRepository: EntitlementRepository, @unchecked Sendable {
    func currentEntitlement() async throws -> ProEntitlement { .free }
    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { continuation in continuation.finish() }
    }
}
