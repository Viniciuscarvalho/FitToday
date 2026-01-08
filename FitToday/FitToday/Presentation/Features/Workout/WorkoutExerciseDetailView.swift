//
//  WorkoutExerciseDetailView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI

struct WorkoutExerciseDetailView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @Environment(\.dependencyResolver) private var resolver
    @StateObject private var restTimerStore = RestTimerStore()
    @State private var errorMessage: String?
    @State private var showRestTimer = false
    @State private var showSubstitutionSheet = false

    var body: some View {
        Group {
            if let prescription = sessionStore.currentPrescription,
               let plan = sessionStore.plan {
                content(for: prescription, plan: plan)
            } else {
                EmptyStateView(
                    title: "Exercício não encontrado",
                    message: "Selecione um exercício válido na lista para continuar."
                )
                .padding()
            }
        }
        .navigationTitle("Execução")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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

    private func content(for prescription: ExercisePrescription, plan: WorkoutPlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FitTodaySpacing.lg) {
                // Progress bar geral
                WorkoutProgressBar(
                    completedExercises: sessionStore.completedExercisesCount,
                    totalExercises: sessionStore.exerciseCount,
                    overallProgress: sessionStore.overallProgress
                )
                
                StepperHeader(
                    title: prescription.exercise.name,
                    step: sessionStore.currentExerciseIndex + 1,
                    totalSteps: plan.exercises.count
                )

                ExerciseHeroImage(media: prescription.exercise.media)
                    .fitCardShadow()
                
                // Tracking de séries
                if let exerciseProgress = sessionStore.currentExerciseProgress {
                    setsTrackingSection(for: exerciseProgress, prescription: prescription)
                }
                
                // Timer de descanso
                if showRestTimer || restTimerStore.isActive {
                    RestTimerView(
                        timerStore: restTimerStore,
                        defaultDuration: prescription.restInterval,
                        onComplete: { showRestTimer = false },
                        onSkip: { showRestTimer = false }
                    )
                }

                VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                    infoRow(icon: "repeat", title: "\(prescription.sets)x séries", subtitle: "\(prescription.reps.lowerBound)-\(prescription.reps.upperBound) reps")
                    infoRow(icon: "timer", title: "Descanso", subtitle: "\(Int(prescription.restInterval))s entre séries")
                    infoRow(icon: "flame", title: sessionStore.plan?.intensity.displayTitle ?? "", subtitle: "Intensidade alvo")
                }

                if !prescription.exercise.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                        Text("Instruções rápidas")
                            .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                        ForEach(prescription.exercise.instructions, id: \.self) { instruction in
                            HStack(alignment: .top, spacing: FitTodaySpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(FitTodayColor.brandPrimary)
                                    .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))
                                Text(instruction)
                                    .font(FitTodayFont.ui(size: 17, weight: .medium))
                                    .foregroundStyle(FitTodayColor.textSecondary)
                            }
                        }
                    }
                }

                if let tip = prescription.tip {
                    FitCard {
                        VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                            Text("Dica do coach")
                                .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                            Text(tip)
                                .font(FitTodayFont.ui(size: 17, weight: .medium))
                                .foregroundStyle(FitTodayColor.textSecondary)
                        }
                    }
                }

                actionButtons(prescription: prescription)
            }
            .padding()
        }
        .background(
            ZStack {
                FitTodayColor.background
                RetroGridPattern(lineColor: FitTodayColor.gridLine.opacity(0.3), spacing: 40)
            }
            .ignoresSafeArea()
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Encerrar") {
                    finishSession(as: .completed)
                }
            }
        }
    }
    
    // MARK: - Sets Tracking Section
    
    @ViewBuilder
    private func setsTrackingSection(for progress: ExerciseProgress, prescription: ExercisePrescription) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack {
                Text("Séries")
                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                
                Spacer()
                
                Text("\(progress.completedSetsCount)/\(progress.totalSets)")
                    .font(FitTodayFont.ui(size: 15, weight: .semiBold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
            }
            
            ForEach(Array(progress.sets.enumerated()), id: \.element.id) { index, setProgress in
                SetCheckbox(
                    setNumber: setProgress.setNumber,
                    isCompleted: setProgress.isCompleted,
                    reps: "\(prescription.reps.display) reps"
                ) {
                    sessionStore.toggleCurrentExerciseSet(at: index)
                    
                    // Iniciar timer de descanso ao completar uma série (se não for a última)
                    if !setProgress.isCompleted && index < progress.sets.count - 1 {
                        showRestTimer = true
                        restTimerStore.start(duration: prescription.restInterval)
                    }
                }
            }
        }
        .padding(FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.surfaceElevated)
        )
    }

    // MARK: - Action Buttons
    
    private func actionButtons(prescription: ExercisePrescription) -> some View {
        VStack(spacing: FitTodaySpacing.sm) {
            // Badge de substituição se houver
            if sessionStore.currentExerciseHasSubstitution,
               let sub = sessionStore.substitution(for: prescription.exercise.id) {
                SubstitutionBadge(alternativeName: sub.name) {
                    sessionStore.removeCurrentSubstitution()
                }
            }
            
            // Botão principal baseado no estado
            if sessionStore.isCurrentExerciseComplete {
                Button("Próximo exercício") {
                    handleCompletion()
                }
                .fitPrimaryStyle()
            } else {
                Button("Marcar todas como concluídas") {
                    sessionStore.completeAllCurrentSets()
                }
                .fitPrimaryStyle()
            }
            
            // Botão de substituição (apenas se não tiver substituição já)
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
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: FitTodayRadius.md)
                            .stroke(FitTodayColor.brandSecondary.opacity(0.5), lineWidth: 1)
                    )
                }
            }

            Button("Pular exercício") {
                handleSkip()
            }
            .fitSecondaryStyle()

            Button("Encerrar treino") {
                finishSession(as: .completed)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.orange)
            .padding(.top, FitTodaySpacing.sm)
        }
    }

    // MARK: - Actions
    
    private func handleCompletion() {
        // Para o timer se estiver rodando
        restTimerStore.stop()
        showRestTimer = false
        
        let finished = sessionStore.advanceToNextExercise()
        if finished {
            finishSession(as: .completed)
        }
    }

    private func handleSkip() {
        restTimerStore.stop()
        showRestTimer = false
        
        let finished = sessionStore.skipCurrentExercise()
        if finished {
            finishSession(as: .completed)
        }
    }

    private func finishSession(as status: WorkoutStatus) {
        restTimerStore.stop()
        
        Task {
            do {
                try await sessionStore.finish(status: status)
                router.push(.workoutSummary, on: .home)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Helpers
    
    private func infoRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.sm) {
            Image(systemName: icon)
                .font(.system(.title3))
                .foregroundStyle(FitTodayColor.brandPrimary)
                .fitGlowEffect(color: FitTodayColor.brandPrimary.opacity(0.3))
            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text(title)
                    .font(FitTodayFont.ui(size: 17, weight: .semiBold))
                Text(subtitle)
                    .font(FitTodayFont.ui(size: 15, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
            }
        }
    }
}

// MARK: - Substitution Sheet Wrapper

/// Wrapper que busca o perfil do usuário e exibe o sheet de substituição
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

import Swinject

