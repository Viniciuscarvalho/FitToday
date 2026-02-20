//
//  WorkoutExecutionView.swift
//  FitToday
//
//  Main workout execution screen displaying current exercise with media, sets, and timers.
//  Uses WorkoutSessionStore for state management (migrated from WorkoutExecutionViewModel).
//

import SwiftUI
import Swinject

struct WorkoutExecutionView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var restTimerStore = RestTimerStore()
    @State private var workoutTimerStore = WorkoutTimerStore()
    @State private var translationService = ExerciseTranslationService()
    @State private var exerciseDescription: String = ""
    @State private var isPaused = false
    @State private var showRestTimer = false
    @State private var showSubstitutionSheet = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if sessionStore.plan != nil {
                workoutContent
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Executando Treino")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            workoutTimerStore.start()
        }
        .onDisappear {
            workoutTimerStore.pause()
            restTimerStore.stop()
        }
        .overlay {
            if showRestTimer || restTimerStore.isActive {
                restTimerOverlay
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .scale(scale: 0.95))
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showRestTimer || restTimerStore.isActive)
        .alert("Ops!", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Algo inesperado aconteceu.")
        }
        .sheet(isPresented: $showSubstitutionSheet) {
            if let prescription = sessionStore.currentPrescription {
                SubstitutionSheetWrapper(
                    exercise: prescription.exercise,
                    resolver: resolver,
                    onSelect: { alternative in
                        sessionStore.substituteCurrentExercise(with: alternative)
                        showSubstitutionSheet = false
                    },
                    onDismiss: {
                        showSubstitutionSheet = false
                    }
                )
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(FitTodayColor.textSecondary)

            Text("Nenhum treino ativo")
                .font(FitTodayFont.ui(size: 18, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            Text("Volte e inicie um treino primeiro.")
                .font(FitTodayFont.ui(size: 14, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FitTodayColor.background)
    }

    // MARK: - Workout Content

    private var workoutContent: some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Progress Header
                progressHeader

                // Current Exercise Card
                if let prescription = sessionStore.currentPrescription {
                    exerciseCard(prescription: prescription)
                }

                // Set Completion UI
                if let progress = sessionStore.currentExerciseProgress,
                   let prescription = sessionStore.currentPrescription {
                    setCompletionSection(progress: progress, prescription: prescription)
                }

                // Navigation Controls
                navigationControls
            }
            .padding()
            .padding(.bottom, 100)
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            bottomControlBar
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sessionStore.currentExerciseIndex)
    }

    // MARK: - Exercise Card

    @ViewBuilder
    private func exerciseCard(prescription: ExercisePrescription) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            // Exercise Name
            Text(sessionStore.effectiveCurrentExerciseName)
                .font(FitTodayFont.display(size: 22, weight: .bold))
                .foregroundStyle(FitTodayColor.textPrimary)

            // Exercise Image
            ExerciseHeroImage(media: prescription.exercise.media)
                .fitCardShadow()

            // Exercise Info
            HStack(spacing: FitTodaySpacing.lg) {
                infoTag(icon: "repeat", text: "\(prescription.sets) séries")
                infoTag(icon: "number", text: "\(prescription.reps.display) reps")
                infoTag(icon: "timer", text: "\(Int(prescription.restInterval))s descanso")
            }

            // Instructions
            if !exerciseDescription.isEmpty {
                Text(exerciseDescription)
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .lineLimit(3)
            }

            // Substitution Badge
            if sessionStore.currentExerciseHasSubstitution,
               let sub = sessionStore.substitution(for: prescription.exercise.id) {
                SubstitutionBadge(alternativeName: sub.name) {
                    sessionStore.removeCurrentSubstitution()
                }
            }

            // Substitution Button
            if !sessionStore.currentExerciseHasSubstitution {
                Button {
                    showSubstitutionSheet = true
                } label: {
                    HStack(spacing: FitTodaySpacing.xs) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Não consigo fazer")
                    }
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.brandSecondary)
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .task(id: prescription.exercise.id) {
            await loadExerciseDescription(prescription.exercise)
        }
    }

    private func infoTag(icon: String, text: String) -> some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(FitTodayColor.brandPrimary)
            Text(text)
                .font(FitTodayFont.ui(size: 12, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
    }

    // MARK: - Set Completion Section

    private func setCompletionSection(progress: ExerciseProgress, prescription: ExercisePrescription) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            HStack {
                Text("Séries")
                    .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                Text("\(progress.completedSetsCount)/\(progress.totalSets)")
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }

            VStack(spacing: FitTodaySpacing.sm) {
                ForEach(Array(progress.sets.enumerated()), id: \.element.id) { index, setProgress in
                    SetCheckbox(
                        setNumber: setProgress.setNumber,
                        isCompleted: setProgress.isCompleted,
                        reps: "\(prescription.reps.display) reps"
                    ) {
                        sessionStore.toggleCurrentExerciseSet(at: index)

                        // Start rest timer when completing a set (if not the last)
                        if !setProgress.isCompleted && index < progress.sets.count - 1 {
                            showRestTimer = true
                            restTimerStore.start(duration: prescription.restInterval)
                        }
                    }
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Workout Timer
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 16))
                    .foregroundStyle(FitTodayColor.brandPrimary)

                Text(workoutTimerStore.formattedTime)
                    .font(FitTodayFont.ui(size: 20, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                // Exercise Counter
                Text("\(sessionStore.completedExercisesCount)/\(sessionStore.exerciseCount) exercícios")
                    .font(FitTodayFont.ui(size: 14, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .fill(FitTodayColor.surface)

                    // Progress
                    RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * sessionStore.overallProgress)
                }
            }
            .frame(height: 8)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sessionStore.overallProgress)
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Skip Exercise
            Button {
                restTimerStore.stop()
                showRestTimer = false
                let finished = sessionStore.skipCurrentExercise()
                if finished {
                    navigateToCompletion()
                }
            } label: {
                HStack(spacing: FitTodaySpacing.xs) {
                    Image(systemName: "forward.fill")
                    Text("Pular")
                }
                .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FitTodaySpacing.md)
                .background(FitTodayColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }

            // Next Exercise
            Button {
                restTimerStore.stop()
                showRestTimer = false
                let finished = sessionStore.advanceToNextExercise()
                if finished {
                    navigateToCompletion()
                }
            } label: {
                HStack(spacing: FitTodaySpacing.xs) {
                    Text("Próximo")
                    Image(systemName: "arrow.right")
                }
                .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FitTodaySpacing.md)
                .background(FitTodayColor.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
            }
            .disabled(!sessionStore.isCurrentExerciseComplete)
            .opacity(sessionStore.isCurrentExerciseComplete ? 1.0 : 0.5)
        }
    }

    // MARK: - Bottom Control Bar

    private var bottomControlBar: some View {
        HStack(spacing: FitTodaySpacing.lg) {
            // Pause/Play Button
            Button {
                isPaused.toggle()
                if isPaused {
                    workoutTimerStore.pause()
                } else {
                    workoutTimerStore.start()
                }
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(FitTodayColor.surface)
                    .clipShape(Circle())
            }

            Spacer()

            // Finish Workout Button
            Button {
                finishWorkout()
            } label: {
                HStack(spacing: FitTodaySpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Finalizar Treino")
                }
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(.white)
                .padding(.horizontal, FitTodaySpacing.lg)
                .padding(.vertical, FitTodaySpacing.md)
                .background(FitTodayColor.success)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            FitTodayColor.surfaceElevated
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Rest Timer Overlay

    private var restTimerOverlay: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Rest Timer Content
            VStack(spacing: FitTodaySpacing.xl) {
                Text("Descanso")
                    .font(FitTodayFont.display(size: 24, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                // Timer Display
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(FitTodayColor.surface, lineWidth: 12)
                        .frame(width: 200, height: 200)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: restTimerStore.progressPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [FitTodayColor.brandPrimary, FitTodayColor.brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: restTimerStore.progressPercentage)

                    // Time display
                    Text(restTimerStore.formattedTime)
                        .font(FitTodayFont.display(size: 60, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .monospacedDigit()
                }
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))

                // Controls
                HStack(spacing: FitTodaySpacing.lg) {
                    // +30s Button
                    Button {
                        restTimerStore.addTime(30)
                    } label: {
                        Text("+30s")
                            .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                            .foregroundStyle(FitTodayColor.textPrimary)
                            .frame(width: 80, height: 48)
                            .background(FitTodayColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
                    }

                    // Skip Rest Button
                    Button {
                        restTimerStore.stop()
                        showRestTimer = false
                    } label: {
                        HStack(spacing: FitTodaySpacing.xs) {
                            Text("Pular Descanso")
                            Image(systemName: "forward.fill")
                        }
                        .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, FitTodaySpacing.lg)
                        .padding(.vertical, FitTodaySpacing.md)
                        .background(FitTodayColor.brandPrimary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(FitTodaySpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                    .fill(FitTodayColor.surfaceElevated)
                    .retroGridOverlay(spacing: 20)
            )
            .techCornerBorders(length: 16, thickness: 2)
            .padding(FitTodaySpacing.xl)
        }
    }

    // MARK: - Helper Methods

    private func loadExerciseDescription(_ exercise: WorkoutExercise) async {
        let instructions = exercise.instructions.joined(separator: "\n")
        let localized = await translationService.ensureLocalizedDescription(instructions)
        await MainActor.run {
            exerciseDescription = localized
        }
    }

    private func finishWorkout() {
        restTimerStore.stop()
        sessionStore.recordElapsedTime(workoutTimerStore.elapsedSeconds)
        workoutTimerStore.reset()

        Task {
            do {
                try await sessionStore.finish(status: .completed)
                navigateToCompletion()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func navigateToCompletion() {
        router.push(.workoutSummary, on: .home)
    }
}

// MARK: - Substitution Sheet Wrapper

private struct SubstitutionSheetWrapper: View {
    let exercise: WorkoutExercise
    let resolver: Resolver
    let onSelect: (AlternativeExercise) -> Void
    let onDismiss: () -> Void

    @State private var userProfile: UserProfile?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let profile = userProfile {
                ExerciseSubstitutionSheet(
                    exercise: exercise,
                    userProfile: profile,
                    onSelect: onSelect,
                    onDismiss: onDismiss
                )
            } else if isLoading {
                VStack {
                    ProgressView()
                    Text("Carregando...")
                        .font(.caption)
                        .foregroundStyle(FitTodayColor.textSecondary)
                }
            } else {
                VStack(spacing: FitTodaySpacing.md) {
                    Text("Perfil não encontrado")
                        .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                    Button("Fechar", action: onDismiss)
                }
            }
        }
        .task {
            await loadProfile()
        }
    }

    private func loadProfile() async {
        isLoading = true
        if let repo = resolver.resolve(UserProfileRepository.self) {
            userProfile = try? await repo.loadProfile()
        }
        isLoading = false
    }
}

#Preview {
    let container = Container()
    let sessionStore = WorkoutSessionStore(resolver: container)

    // Create a sample plan for preview
    let samplePlan = WorkoutPlan(
        id: UUID(),
        title: "Treino Push",
        focus: .upper,
        estimatedDurationMinutes: 45,
        intensity: .moderate,
        exercises: [
            ExercisePrescription(
                exercise: WorkoutExercise(
                    id: "1",
                    name: "Supino Reto",
                    mainMuscle: .chest,
                    equipment: .barbell,
                    instructions: ["Deite no banco com os pés apoiados.", "Desça a barra até o peito."],
                    media: nil
                ),
                sets: 4,
                reps: IntRange(8, 12),
                restInterval: 90,
                tip: nil
            )
        ],
        createdAt: Date()
    )

    // Start session with sample plan
    sessionStore.start(with: samplePlan)

    return NavigationStack {
        WorkoutExecutionView()
            .environment(AppRouter())
            .environment(sessionStore)
            .environment(\.dependencyResolver, container)
    }
}
