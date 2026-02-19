//
//  WorkoutPlanView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//  Refactored on 14/01/26 - Extracted components to separate files
//

import SwiftUI
import Swinject

// MARK: - Phase Display Mode

/// Modo de exibição para fases de aquecimento e aeróbio
enum PhaseDisplayMode: String, CaseIterable, Identifiable {
    case auto = "auto"
    case exercises = "exercises"
    case guided = "guided"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .exercises: return "Exercícios"
        case .guided: return "Guiado"
        }
    }

    var iconName: String {
        switch self {
        case .auto: return "wand.and.stars"
        case .exercises: return "dumbbell.fill"
        case .guided: return "figure.run"
        }
    }

    var description: String {
        switch self {
        case .auto: return "Combina exercícios e atividades guiadas"
        case .exercises: return "Apenas exercícios de aquecimento/cardio"
        case .guided: return "Apenas atividades guiadas (ex: Aeróbio Z2)"
        }
    }
}

// MARK: - Main View

// 💡 Learn: View refatorada com componentes extraídos para manutenibilidade
// Seguindo diretriz de < 100 linhas por view
struct WorkoutPlanView: View {
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @Environment(\.dependencyResolver) private var resolver
    @Environment(\.imageCacheService) private var imageCacheService

    @State private var timerStore = WorkoutTimerStore()
    @State private var errorMessage: String?
    @State private var isFinishing = false
    @State private var isRegenerating = false
    @State private var entitlement: ProEntitlement = .free
    @State private var animationTrigger = false
    @State private var isPrefetchingImages = false

    @AppStorage(AppStorageKeys.workoutPhaseDisplayMode) private var displayModeRaw: String = PhaseDisplayMode.auto.rawValue

    private var displayMode: PhaseDisplayMode {
        get { PhaseDisplayMode(rawValue: displayModeRaw) ?? .auto }
        set { setDisplayMode(newValue) }
    }

    private var isPro: Bool {
        #if DEBUG
        if DebugEntitlementOverride.shared.isEnabled {
            return DebugEntitlementOverride.shared.isPro
        }
        #endif
        return entitlement.isPro
    }

    var body: some View {
        Group {
            if let plan = sessionStore.plan {
                workoutContent(plan: plan)
            } else {
                EmptyStateView(
                    title: "Nenhum treino ativo",
                    message: "Gere um novo treino na Home respondendo ao questionário diário."
                )
                .padding()
            }
        }
        .navigationTitle("Treino gerado")
        .toolbar(.hidden, for: .tabBar)
        .alert("Ops!", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Algo inesperado aconteceu.")
        }
        .onAppear { loadEntitlement() }
        .task(id: sessionStore.plan?.id) { await prefetchWorkoutImages() }
        .overlay {
            if isPrefetchingImages {
                PrefetchingOverlay()
                    .animation(.easeInOut(duration: 0.3), value: isPrefetchingImages)
            }
        }
    }

    // MARK: - Workout Content

    @ViewBuilder
    private func workoutContent(plan: WorkoutPlan) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: FitTodaySpacing.lg) {
                    WorkoutPlanHeader(
                        plan: plan,
                        timerStore: timerStore,
                        onStartWorkout: startWorkoutWithTimer,
                        onToggleTimer: { timerStore.toggle() },
                        onViewExercise: startFromCurrentExercise
                    )

                    PhaseModePicker(
                        displayMode: Binding(
                            get: { PhaseDisplayMode(rawValue: displayModeRaw) ?? .auto },
                            set: { setDisplayMode($0) }
                        ),
                        isPro: isPro,
                        isRegenerating: isRegenerating,
                        timerHasStarted: timerStore.hasStarted,
                        onShowModeInfo: showModeInfo,
                        onRegenerateWorkout: regenerateWorkoutPlan
                    )

                    exerciseList(for: plan)

                    WorkoutFooterActions(
                        isFinishing: isFinishing,
                        onResumeExercise: startFromCurrentExercise,
                        onSkipWorkout: { finishSession(as: .skipped) }
                    )
                }
                .padding()
                .padding(.bottom, timerStore.hasStarted ? 100 : 0)
            }
            .background(FitTodayColor.background.ignoresSafeArea())

            if timerStore.hasStarted {
                FloatingTimerBar(
                    timerStore: timerStore,
                    onToggleTimer: { timerStore.toggle() },
                    onFinish: { finishSession(as: .completed) },
                    isFinishing: isFinishing
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerStore.hasStarted)
    }

    // MARK: - Exercise List

    private func exerciseList(for plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            ForEach(Array(plan.phases.enumerated()), id: \.element.id) { index, phase in
                PhaseSectionView(phase: phase, phaseIndex: index, displayMode: displayMode)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: displayMode)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animationTrigger)
    }

    // MARK: - Actions

    private func setDisplayMode(_ mode: PhaseDisplayMode) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            displayModeRaw = mode.rawValue
            animationTrigger.toggle()
        }
    }

    private func startWorkoutWithTimer() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            timerStore.start()
        }
    }

    private func startFromCurrentExercise() {
        guard sessionStore.plan != nil else {
            errorMessage = "Nenhum plano encontrado."
            return
        }
        router.push(.workoutExecution, on: .home)
    }

    private func showModeInfo() {
        let proInfo = isPro ? "\n\n✨ PRO: Seu treino é otimizado com IA!" : "\n\n💡 Dica: Assine PRO para treinos personalizados com IA!"
        errorMessage = """
        Auto: Combina exercícios e atividades guiadas conforme seu perfil.

        Exercícios: Mostra apenas exercícios de aquecimento e cardio.

        Guiado: Mostra apenas atividades guiadas (ex: "Aeróbio Z2 12 min").\(proInfo)
        """
    }

    private func finishSession(as status: WorkoutStatus) {
        guard !isFinishing else { return }
        isFinishing = true
        timerStore.pause()
        sessionStore.recordElapsedTime(timerStore.elapsedSeconds)

        Task {
            do {
                try await sessionStore.finish(status: status)
                timerStore.reset()
                router.push(.workoutSummary, on: .home)
            } catch {
                errorMessage = error.localizedDescription
            }
            isFinishing = false
        }
    }

    // MARK: - Data Loading

    private func loadEntitlement() {
        Task {
            guard let repo = resolver.resolve(EntitlementRepository.self) else { return }
            do {
                entitlement = try await repo.currentEntitlement()
            } catch {
                entitlement = .free
            }
        }
    }

    private func prefetchWorkoutImages() async {
        guard let plan = sessionStore.plan,
              let cacheService = imageCacheService else {
            return
        }

        // OPTIMIZATION: Only prefetch first 3 images to save API requests
        // Remaining images load on-demand when user views each exercise
        let urls = Array(plan.imageURLs.prefix(3))
        guard !urls.isEmpty else { return }

        isPrefetchingImages = true
        await cacheService.prefetchImages(urls)
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        isPrefetchingImages = false
    }

    // MARK: - Workout Regeneration

    private func regenerateWorkoutPlan() {
        guard !isRegenerating else { return }

        isRegenerating = true

        Task {
            do {
                let newPlan = try await generateNewPlan()

                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        sessionStore.start(with: newPlan)
                        animationTrigger.toggle()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Não foi possível regenerar o treino: \(error.localizedDescription)"
                }
            }

            await MainActor.run {
                isRegenerating = false
            }
        }
    }

    private func generateNewPlan() async throws -> WorkoutPlan {
        guard let profileRepo = resolver.resolve(UserProfileRepository.self) else {
            throw DomainError.repositoryFailure(reason: "Repositório de perfil não disponível.")
        }

        guard let profile = try await profileRepo.loadProfile() else {
            throw DomainError.profileNotFound
        }

        guard let checkInData = UserDefaults.standard.data(forKey: AppStorageKeys.lastDailyCheckInData),
              let checkIn = try? JSONDecoder().decode(DailyCheckIn.self, from: checkInData) else {
            throw DomainError.invalidInput(reason: "Responda o questionário diário primeiro.")
        }

        guard let blocksRepo = resolver.resolve(WorkoutBlocksRepository.self) else {
            throw DomainError.repositoryFailure(reason: "Repositório de blocos não disponível.")
        }

        let blocks = try await blocksRepo.loadBlocks()

        if isPro {
            guard let composer = resolver.resolve(WorkoutPlanComposing.self) else {
                throw DomainError.repositoryFailure(reason: "Compositor não disponível.")
            }
            return try await composer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        } else {
            let localComposer = LocalWorkoutPlanComposer()
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        }
    }
}
