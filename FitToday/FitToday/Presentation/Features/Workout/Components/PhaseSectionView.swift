//
//  PhaseSectionView.swift
//  FitToday
//
//  Created by AI on 14/01/26.
//

import SwiftUI

struct PhaseSectionView: View {
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore

    let phase: WorkoutPlanPhase
    let phaseIndex: Int
    let displayMode: PhaseDisplayMode
    var isExecuting: Bool = false
    var restTimerStore: RestTimerStore?
    var onSetCompleted: ((Int, ExercisePrescription) -> Void)?

    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: Int?

    var body: some View {
        if !filteredItems.isEmpty {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                SectionHeader(
                    title: phaseHeaderTitle,
                    actionTitle: nil,
                    action: nil
                )
                .padding(.horizontal, -FitTodaySpacing.md)

                LazyVStack(spacing: FitTodaySpacing.sm) {
                    ForEach(filteredItems.indices, id: \.self) { idx in
                        let item = filteredItems[idx]
                        switch item {
                        case .activity(let activity):
                            ActivityRow(activity: activity)

                        case .exercise(let prescription):
                            let localIndex = idx + 1
                            let globalIndex = globalExerciseIndex(for: prescription)

                            if isExecuting, let globalIndex {
                                exerciseExecutionCard(
                                    prescription: prescription,
                                    exerciseIndex: globalIndex,
                                    localIndex: localIndex
                                )
                            } else {
                                Button {
                                    router.push(.workoutExercisePreview(prescription), on: .home)
                                } label: {
                                    WorkoutExerciseRow(
                                        index: localIndex,
                                        prescription: prescription,
                                        isCurrent: sessionStore.currentExerciseIndex == localIndex
                                    )
                                }
                                .buttonStyle(ExerciseRowButtonStyle())
                                .contextMenu {
                                    Button {
                                        router.push(.workoutExercisePreview(prescription), on: .home)
                                    } label: {
                                        Label("Ver detalhes", systemImage: "info.circle")
                                    }

                                    Button(role: .destructive) {
                                        itemToDelete = idx
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Remover exercício", systemImage: "trash")
                                    }
                                }
                                .accessibilityHint("Toque para ver detalhes. Segure para mais opções.")
                            }
                        }
                    }
                }
            }
            .padding(.top, FitTodaySpacing.md)
            .confirmationDialog(
                "Remover exercício?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remover", role: .destructive) {
                    if let idx = itemToDelete {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            sessionStore.removeExercise(fromPhase: phaseIndex, at: idx)
                        }
                    }
                    itemToDelete = nil
                }
                Button("Cancelar", role: .cancel) {
                    itemToDelete = nil
                }
            } message: {
                Text("Este exercício será removido do treino atual.")
            }
        }
    }

    // MARK: - Execution Card

    @ViewBuilder
    private func exerciseExecutionCard(prescription: ExercisePrescription, exerciseIndex: Int, localIndex: Int) -> some View {
        let progress = sessionStore.progress?.exercises[safe: exerciseIndex]
        let isCurrentExercise = sessionStore.currentExerciseIndex == exerciseIndex

        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            // Exercise header
            HStack(alignment: .top, spacing: FitTodaySpacing.md) {
                ExerciseThumbnail(media: prescription.exercise.media, size: 56)

                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text("\(localIndex). \(prescription.exercise.name)")
                        .font(FitTodayFont.ui(size: 16, weight: .bold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    HStack(spacing: FitTodaySpacing.sm) {
                        Text("\(prescription.sets) " + "execution.sets".localized)
                        Text("·").foregroundStyle(FitTodayColor.textTertiary)
                        Text("\(prescription.reps.display) reps")
                        Text("·").foregroundStyle(FitTodayColor.textTertiary)
                        Text("\(Int(prescription.restInterval))s " + "execution.rest".localized)
                    }
                    .font(FitTodayFont.ui(size: 12, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                }

                Spacer()

                if let progress {
                    MiniProgressRing(progress: progress.progressPercentage, size: 28)
                }
            }

            // Set tracking rows
            if let progress {
                // Column headers
                HStack(spacing: FitTodaySpacing.sm) {
                    Spacer().frame(width: 28)
                    Text("execution.set".localized)
                        .frame(width: 52, alignment: .leading)
                    Spacer()
                    Text("Reps")
                        .frame(width: 60, alignment: .center)
                    Text("execution.weight".localized)
                        .frame(width: 68, alignment: .center)
                }
                .font(FitTodayFont.ui(size: 11, weight: .medium))
                .foregroundStyle(FitTodayColor.textTertiary)
                .padding(.horizontal, FitTodaySpacing.md)

                VStack(spacing: FitTodaySpacing.xs) {
                    ForEach(Array(progress.sets.enumerated()), id: \.element.id) { setIdx, setProgress in
                        SetCheckbox(
                            setNumber: setProgress.setNumber,
                            isCompleted: setProgress.isCompleted,
                            reps: prescription.reps.display,
                            actualReps: setProgress.actualReps,
                            weight: setProgress.weight,
                            onToggle: {
                                sessionStore.toggleSet(exerciseIndex: exerciseIndex, setIndex: setIdx)
                                if !setProgress.isCompleted && setIdx < progress.sets.count - 1 {
                                    onSetCompleted?(exerciseIndex, prescription)
                                }
                            },
                            onRepsChanged: { reps in
                                sessionStore.updateSetReps(exerciseIndex: exerciseIndex, setIndex: setIdx, reps: reps)
                            },
                            onWeightChanged: { weight in
                                sessionStore.updateSetWeight(exerciseIndex: exerciseIndex, setIndex: setIdx, weight: weight)
                            }
                        )
                    }
                }

                // Inline rest timer
                if isCurrentExercise, let restTimerStore, restTimerStore.isActive {
                    InlineRestTimerBar(timerStore: restTimerStore)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(isCurrentExercise ? FitTodayColor.surfaceElevated : FitTodayColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .stroke(isCurrentExercise ? FitTodayColor.brandPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Computed Properties

    private var isFilterablePhase: Bool {
        phase.kind == .warmup || phase.kind == .aerobic || phase.kind == .finisher
    }

    private var filteredItems: [WorkoutPlanItem] {
        guard isFilterablePhase else {
            return phase.items
        }

        switch displayMode {
        case .auto:
            return phase.items
        case .exercises:
            return phase.items.filter { item in
                if case .exercise = item { return true }
                return false
            }
        case .guided:
            return phase.items.filter { item in
                if case .activity = item { return true }
                return false
            }
        }
    }

    private var phaseHeaderTitle: String {
        var title = phase.title

        if isFilterablePhase && displayMode != .auto {
            let modeIndicator = displayMode == .exercises ? "🏋️" : "🎯"
            title = "\(title) \(modeIndicator)"
        }

        if let rpe = phase.rpeTarget {
            return "\(title) · RPE \(rpe)"
        }
        return title
    }

    private func globalExerciseIndex(for prescription: ExercisePrescription) -> Int? {
        sessionStore.exercises.firstIndex(where: { $0.exercise.id == prescription.exercise.id })
    }
}

// MARK: - Safe Collection Index

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Button Style for Exercise Row

struct ExerciseRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
