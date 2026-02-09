//
//  WorkoutExecutionView.swift
//  FitToday
//
//  Main workout execution screen displaying current exercise with media, sets, and timers.
//  Integrates WorkoutExecutionViewModel for state management.
//

import SwiftUI
import Swinject

struct WorkoutExecutionView: View {
    @Environment(\.dependencyResolver) private var resolver
    @Environment(AppRouter.self) private var router

    @State private var viewModel: WorkoutExecutionViewModel?
    @State private var translationService: ExerciseTranslationService = ExerciseTranslationService()
    @State private var exerciseDescription: String = ""

    let workoutPlan: WorkoutPlan

    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                workoutContent(viewModel: viewModel)
            } else {
                loadingView
            }

            // Rest Timer Overlay
            if let viewModel = viewModel, viewModel.isResting {
                restTimerOverlay(viewModel: viewModel)
            }
        }
        .navigationTitle("Executando Treino")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            setupViewModel()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Preparando treino...")
                .font(FitTodayFont.ui(size: 16, weight: .medium))
                .foregroundStyle(FitTodayColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FitTodayColor.background)
    }

    // MARK: - Workout Content

    @ViewBuilder
    private func workoutContent(viewModel: WorkoutExecutionViewModel) -> some View {
        ScrollView {
            VStack(spacing: FitTodaySpacing.lg) {
                // Progress Header
                progressHeader(viewModel: viewModel)

                // Current Exercise Card
                if let prescription = viewModel.currentPrescription {
                    ExerciseExecutionCard(
                        prescription: prescription,
                        description: exerciseDescription,
                        viewModel: viewModel,
                        onSubstitute: { viewModel.showSubstitution() }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .task(id: prescription.exercise.id) {
                        await loadExerciseDescription(prescription.exercise)
                    }
                }

                // Set Completion UI
                if let progress = viewModel.currentExerciseProgress,
                   let prescription = viewModel.currentPrescription {
                    SetCompletionView(
                        progress: progress,
                        prescription: prescription,
                        onToggleSet: { index in
                            viewModel.toggleSet(at: index)
                        }
                    )
                }

                // Navigation Controls
                navigationControls(viewModel: viewModel)
            }
            .padding()
            .padding(.bottom, 100)
        }
        .background(FitTodayColor.background.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            bottomControlBar(viewModel: viewModel)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentExerciseIndex)
    }

    // MARK: - Progress Header

    private func progressHeader(viewModel: WorkoutExecutionViewModel) -> some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Workout Timer
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 16))
                    .foregroundStyle(FitTodayColor.brandPrimary)

                Text(viewModel.formattedWorkoutTime)
                    .font(FitTodayFont.ui(size: 20, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(FitTodayColor.textPrimary)

                Spacer()

                // Exercise Counter
                Text("\(viewModel.completedExercisesCount)/\(viewModel.totalExercisesCount) exercícios")
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
                        .frame(width: geometry.size.width * viewModel.overallProgress)
                }
            }
            .frame(height: 8)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.overallProgress)
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }

    // MARK: - Navigation Controls

    private func navigationControls(viewModel: WorkoutExecutionViewModel) -> some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Skip Exercise
            Button {
                let isComplete = viewModel.skipExercise()
                if isComplete {
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
                let isComplete = viewModel.nextExercise()
                if isComplete {
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
            .disabled(!viewModel.isCurrentExerciseComplete)
            .opacity(viewModel.isCurrentExerciseComplete ? 1.0 : 0.5)
        }
    }

    // MARK: - Bottom Control Bar

    private func bottomControlBar(viewModel: WorkoutExecutionViewModel) -> some View {
        HStack(spacing: FitTodaySpacing.lg) {
            // Pause/Play Button
            Button {
                viewModel.togglePause()
            } label: {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(FitTodayColor.surface)
                    .clipShape(Circle())
            }

            Spacer()

            // Finish Workout Button
            Button {
                Task {
                    await viewModel.finishWorkout(status: .completed)
                    navigateToCompletion()
                }
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

    private func restTimerOverlay(viewModel: WorkoutExecutionViewModel) -> some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss on tap outside
                }

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
                        .trim(from: 0, to: viewModel.restProgressPercentage)
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
                        .animation(.linear(duration: 0.1), value: viewModel.restProgressPercentage)

                    // Time display
                    Text(viewModel.formattedRestTime)
                        .font(FitTodayFont.display(size: 60, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                        .monospacedDigit()
                }
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))

                // Controls
                HStack(spacing: FitTodaySpacing.lg) {
                    // +30s Button
                    Button {
                        viewModel.addRestTime(30)
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
                        viewModel.skipRest()
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
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isResting)
    }

    // MARK: - Helper Methods

    private func setupViewModel() {
        guard viewModel == nil else { return }
        let vm = WorkoutExecutionViewModel(resolver: resolver)
        vm.startWorkout(with: workoutPlan)
        viewModel = vm
    }

    private func loadExerciseDescription(_ exercise: WorkoutExercise) async {
        let instructions = exercise.instructions.joined(separator: "\n")
        let localized = await translationService.ensureLocalizedDescription(instructions)
        await MainActor.run {
            exerciseDescription = localized
        }
    }

    private func navigateToCompletion() {
        router.push(.workoutSummary, on: router.selectedTab)
    }
}

// MARK: - Set Completion View

private struct SetCompletionView: View {
    let progress: ExerciseProgress
    let prescription: ExercisePrescription
    let onToggleSet: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            Text("Séries")
                .font(FitTodayFont.ui(size: 16, weight: .semiBold))
                .foregroundStyle(FitTodayColor.textPrimary)

            VStack(spacing: FitTodaySpacing.sm) {
                ForEach(Array(progress.sets.enumerated()), id: \.offset) { index, set in
                    SetCheckbox(
                        setNumber: index + 1,
                        isCompleted: set.isCompleted,
                        reps: prescription.reps.display,
                        onToggle: { onToggleSet(index) }
                    )
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(FitTodayColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: FitTodayRadius.md))
    }
}


#Preview {
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

    let container = Container()

    NavigationStack {
        WorkoutExecutionView(workoutPlan: samplePlan)
            .environment(AppRouter())
            .environment(\.dependencyResolver, container)
    }
}
