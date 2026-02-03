//
//  HomeView.swift
//  FitToday
//
//  Created by AI on 05/01/26.
//  Redesigned on 29/01/26 - New AI workout generator card design
//

import SwiftUI
import Swinject

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore

    @State private var viewModel: HomeViewModel
    @State private var isGeneratingPlan = false

    // AI Workout Generator State
    @State private var selectedBodyParts: Set<BodyPart> = []
    @State private var fatigueValue: Double = 0.5
    @State private var selectedTime: Int = 45

    // Generated Workout Preview State
    @State private var generatedWorkout: GeneratedWorkout?
    @State private var showWorkoutPreview = false

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

                // User Stats Section (show if has any workout history)
                if viewModel.workoutsThisWeek > 0 || viewModel.streakDays > 0 {
                    UserStatsSection(
                        workoutsThisWeek: viewModel.workoutsThisWeek,
                        caloriesBurnedFormatted: viewModel.caloriesBurnedFormatted,
                        streakDays: viewModel.streakDays
                    )
                }

                // Content based on journey state
                contentForState

                // Streak Banner (if streak > 0)
                if viewModel.streakDays > 0 {
                    StreakBanner(streakDays: viewModel.streakDays)
                }
            }
            .padding(.bottom, FitTodaySpacing.xl)
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            viewModel.onAppear()
        }
        .sheet(isPresented: $showWorkoutPreview) {
            if let workout = generatedWorkout {
                GeneratedWorkoutPreview(
                    workout: workout,
                    onStartWorkout: {
                        showWorkoutPreview = false
                        startGeneratedWorkout(workout)
                    },
                    onSaveAsTemplate: {
                        // TODO: Save as custom workout template
                        showWorkoutPreview = false
                    },
                    onRegenerate: {
                        showWorkoutPreview = false
                        generateWorkout()
                    },
                    onDismiss: {
                        showWorkoutPreview = false
                    }
                )
            }
        }
    }

    // MARK: - Content for State

    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.journeyState {
        case .loading:
            loadingView

        case .noProfile:
            // Show AI generator card even without profile (guides to onboarding)
            AIWorkoutGeneratorCard(
                selectedBodyParts: $selectedBodyParts,
                fatigueValue: $fatigueValue,
                selectedTime: $selectedTime,
                isGenerating: isGeneratingPlan,
                onGenerate: { router.push(.onboarding, on: .home) }
            )

        case .needsDailyCheckIn:
            // Show AI generator card
            AIWorkoutGeneratorCard(
                selectedBodyParts: $selectedBodyParts,
                fatigueValue: $fatigueValue,
                selectedTime: $selectedTime,
                isGenerating: isGeneratingPlan,
                onGenerate: generateWorkout
            )

        case .workoutReady:
            // Show continue workout card and AI generator
            VStack(spacing: FitTodaySpacing.lg) {
                ContinueWorkoutCard(
                    workoutName: "home.continue.workout_name".localized,
                    lastSessionInfo: "home.continue.last_session".localized,
                    onContinue: { router.push(.dailyQuestionnaire, on: .home) }
                )

                AIWorkoutGeneratorCard(
                    selectedBodyParts: $selectedBodyParts,
                    fatigueValue: $fatigueValue,
                    selectedTime: $selectedTime,
                    isGenerating: isGeneratingPlan,
                    onGenerate: generateWorkout
                )
            }

        case .workoutCompleted:
            // Show completed state with option to generate new
            VStack(spacing: FitTodaySpacing.lg) {
                workoutCompletedCard

                AIWorkoutGeneratorCard(
                    selectedBodyParts: $selectedBodyParts,
                    fatigueValue: $fatigueValue,
                    selectedTime: $selectedTime,
                    isGenerating: isGeneratingPlan,
                    onGenerate: generateWorkout
                )
            }

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

    // MARK: - Actions

    private func generateWorkout() {
        guard !isGeneratingPlan else { return }
        guard !selectedBodyParts.isEmpty else { return }

        Task {
            isGeneratingPlan = true

            do {
                let workoutPlan = try await viewModel.regenerateDailyWorkoutPlan()

                // Convert WorkoutPlan to GeneratedWorkout for preview
                let generatedExercises = workoutPlan.exercises.map { prescription in
                    GeneratedExercise(
                        exerciseId: prescription.exercise.id.hashValue,
                        name: prescription.exercise.name,
                        targetMuscle: prescription.exercise.mainMuscle.displayName,
                        equipment: prescription.exercise.equipment.displayName,
                        sets: prescription.sets,
                        repsRange: prescription.reps.display,
                        restSeconds: Int(prescription.restInterval),
                        notes: prescription.tip,
                        imageURL: prescription.exercise.media?.imageURL?.absoluteString
                    )
                }

                // Determine target muscles from selected body parts
                let targetMuscles = selectedBodyParts.map { $0.rawValue }

                generatedWorkout = GeneratedWorkout(
                    name: workoutPlan.title,
                    exercises: generatedExercises,
                    estimatedDuration: selectedTime,
                    targetMuscles: targetMuscles,
                    fatigueAdjusted: fatigueValue < 0.5,
                    warmupIncluded: true
                )

                showWorkoutPreview = true
                await viewModel.refresh()
            } catch {
                // Show error through viewModel
                #if DEBUG
                print("[HomeView] Error generating workout: \(error)")
                #endif
            }

            isGeneratingPlan = false
        }
    }

    private func startGeneratedWorkout(_ workout: GeneratedWorkout) {
        // Convert GeneratedWorkout to WorkoutPlan and start session
        let exercises = workout.exercises.map { exercise in
            let workoutExercise = WorkoutExercise(
                id: "\(exercise.exerciseId)",
                name: exercise.name,
                mainMuscle: MuscleGroup.allCases.first { $0.displayName == exercise.targetMuscle } ?? .chest,
                equipment: EquipmentType.allCases.first { $0.displayName == exercise.equipment } ?? .bodyweight,
                instructions: [],
                media: exercise.imageURL.flatMap { URL(string: $0) }.map { ExerciseMedia(imageURL: $0, gifURL: nil) }
            )

            // Parse reps range
            let repsComponents = exercise.repsRange.components(separatedBy: "-")
            let repsLower = Int(repsComponents.first ?? "8") ?? 8
            let repsUpper = Int(repsComponents.last ?? "12") ?? 12

            return ExercisePrescription(
                exercise: workoutExercise,
                sets: exercise.sets,
                reps: IntRange(repsLower, repsUpper),
                restInterval: TimeInterval(exercise.restSeconds),
                tip: exercise.notes
            )
        }

        let workoutPlan = WorkoutPlan(
            id: workout.id,
            title: workout.name,
            focus: .fullBody,
            estimatedDurationMinutes: workout.estimatedDuration,
            intensity: .moderate,
            exercises: exercises
        )

        sessionStore.start(with: workoutPlan)
        router.push(.workoutPlan(workoutPlan.id), on: .home)
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
