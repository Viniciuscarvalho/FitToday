//
//  HomeView.swift
//  FitToday
//
//  Created by AI on 05/01/26.
//

import SwiftUI
import Swinject

struct HomeView: View {
    @Environment(AppRouter.self) private var router

    @State private var viewModel: HomeViewModel

    init(resolver: Resolver?) {
        guard let resolver = resolver else {
            fatalError("Resolver is required for HomeView")
        }
        self._viewModel = State(wrappedValue: HomeViewModel(resolver: resolver))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Header with greeting
                HomeHeader(
                    greeting: viewModel.greeting,
                    dateFormatted: viewModel.currentDateFormatted,
                    isPro: viewModel.entitlement.isPro,
                    goalBadgeText: viewModel.goalBadgeText,
                    userName: viewModel.userName,
                    userPhotoURL: viewModel.userPhotoURL,
                    onNotificationTap: { router.push(.notifications, on: .home) }
                )

                // Week streak circles
                WeekStreakRow(
                    completedDays: viewModel.weekCompletedDays,
                    currentStreak: viewModel.streakDays
                )
                .padding(.horizontal)

                // Daily stats summary
                DailyStatsCard(
                    workoutsThisWeek: viewModel.workoutsThisWeek,
                    weeklyTarget: viewModel.weeklyTarget,
                    caloriesBurned: viewModel.caloriesBurnedFormatted,
                    streakDays: viewModel.streakDays,
                    totalSets: viewModel.totalSetsThisWeek,
                    avgDuration: viewModel.avgDurationMinutes
                )

                // Today's workout section
                if let todayWorkout = viewModel.todayWorkout,
                   case .workoutReady = viewModel.journeyState {
                    TodayWorkoutSection(
                        workout: todayWorkout,
                        programName: viewModel.todayProgramName,
                        onStartWorkout: {
                            router.push(.workoutPreview(todayWorkout), on: .home)
                        }
                    )
                }

                // Content based on journey state
                contentForState
            }
            .padding(.bottom, FitTodaySpacing.xl)
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            viewModel.onAppear()
        }
    }

    // MARK: - Content for State

    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.journeyState {
        case .loading:
            loadingView

        case .noProfile:
            setupProfileCard

        case .workoutReady:
            EmptyView()

        case .workoutCompleted:
            workoutCompletedCard

        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.md) {
            ProgressView()
                .tint(FitTodayColor.brandPrimary)
            Text("common.loading".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    // MARK: - Setup Profile Card

    private var setupProfileCard: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.brandPrimary)

            Text("home.setup_profile.title".localized)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("home.setup_profile.subtitle".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            Button("home.setup_profile.cta".localized) {
                router.push(.onboarding, on: .home)
            }
            .fitPrimaryStyle()
        }
        .padding(FitTodaySpacing.lg)
        .frame(maxWidth: .infinity)
        .background(FitTodayColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .padding(.horizontal)
    }

    // MARK: - Workout Completed Card

    private var workoutCompletedCard: some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.success)

            Text("home.completed.title".localized)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("home.completed.subtitle".localized)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(FitTodaySpacing.lg)
        .frame(maxWidth: .infinity)
        .background(FitTodayColor.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .stroke(FitTodayColor.success.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.error)

            Text("home.error.title".localized)
                .font(FitTodayFont.ui(size: 18, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text(message)
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)

            Button("common.retry".localized) {
                Task { await viewModel.refresh() }
            }
            .fitSecondaryStyle()
        }
        .padding(FitTodaySpacing.lg)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    let container = Container()
    container.register(UserProfileRepository.self) { _ in MockUserProfileRepository() }
    container.register(EntitlementRepository.self) { _ in MockEntitlementRepository() }
    container.register(ProgramRepository.self) { _ in BundleProgramRepository() }
    container.register(LibraryWorkoutsRepository.self) { _ in
        BundleLibraryWorkoutsRepository()
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
