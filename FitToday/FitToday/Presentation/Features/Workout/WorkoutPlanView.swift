//
//  WorkoutPlanView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
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

struct WorkoutPlanView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @Environment(\.dependencyResolver) private var resolver
    @StateObject private var timerStore = WorkoutTimerStore()
    @State private var errorMessage: String?
    @State private var isFinishing = false
    @State private var isRegenerating = false
    @State private var entitlement: ProEntitlement = .free
    @State private var animationTrigger = false
    
    /// Modo de exibição persistido
    @AppStorage(AppStorageKeys.workoutPhaseDisplayMode) private var displayModeRaw: String = PhaseDisplayMode.auto.rawValue
    
    private var displayMode: PhaseDisplayMode {
        get { PhaseDisplayMode(rawValue: displayModeRaw) ?? .auto }
    }
    
    private func setDisplayMode(_ mode: PhaseDisplayMode) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            displayModeRaw = mode.rawValue
            animationTrigger.toggle()
        }
    }
    
    /// Verifica se o usuário é PRO (considerando debug override)
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
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: FitTodaySpacing.lg) {
                            header(for: plan)
                            phaseModePicker
                            exerciseList(for: plan)
                            footerActions
                        }
                        .padding()
                        .padding(.bottom, timerStore.hasStarted ? 100 : 0) // Espaço para o timer flutuante
                    }
                    .background(FitTodayColor.background.ignoresSafeArea())
                    
                    // Timer flutuante quando o treino está em andamento
                    if timerStore.hasStarted {
                        floatingTimerBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerStore.hasStarted)
            } else {
                EmptyStateView(
                    title: "Nenhum treino ativo",
                    message: "Gere um novo treino na Home respondendo ao questionário diário."
                )
                .padding()
            }
        }
        .navigationTitle("Treino gerado")
        .alert("Ops!", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Algo inesperado aconteceu.")
        }
        .onAppear {
            loadEntitlement()
        }
        .onDisappear {
            // Não reseta o timer ao sair, mantém em background
        }
    }
    
    // MARK: - Entitlement
    
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
    
    // MARK: - Floating Timer Bar
    
    private var floatingTimerBar: some View {
        HStack(spacing: FitTodaySpacing.md) {
            // Tempo decorrido
            HStack(spacing: FitTodaySpacing.xs) {
                Image(systemName: "timer")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                
                Text(timerStore.formattedTime)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(FitTodayColor.textPrimary)
                    .contentTransition(.numericText())
            }
            
            Spacer()
            
            // Botão de pausar/retomar
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    timerStore.toggle()
                }
            } label: {
                Image(systemName: timerStore.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(timerStore.isRunning ? Color.orange : FitTodayColor.brandPrimary)
                    .clipShape(Circle())
            }
            .accessibilityLabel(timerStore.isRunning ? "Pausar treino" : "Retomar treino")
            
            // Botão de finalizar
            Button {
                finishSession(as: .completed)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Finalizar treino")
            .disabled(isFinishing)
        }
        .padding(.horizontal, FitTodaySpacing.lg)
        .padding(.vertical, FitTodaySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.lg)
                .fill(FitTodayColor.surface)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
        )
        .padding(.horizontal)
        .padding(.bottom, FitTodaySpacing.sm)
    }

    private func header(for plan: WorkoutPlan) -> some View {
        FitCard {
            VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
                Text(plan.title)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(FitTodayColor.textPrimary)

                Text(plan.focusDescription)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textSecondary)

                HStack(spacing: FitTodaySpacing.md) {
                    WorkoutMetaChip(
                        icon: "clock",
                        label: "\(plan.estimatedDurationMinutes) min"
                    )
                    WorkoutMetaChip(
                        icon: "bolt.fill",
                        label: plan.intensity.displayTitle
                    )
                    
                    // Exibe o tempo decorrido se o treino já começou
                    if timerStore.hasStarted {
                        WorkoutMetaChip(
                            icon: "timer",
                            label: timerStore.formattedTime
                        )
                    }
                }

                if !timerStore.hasStarted {
                    Button("Começar agora") {
                        startWorkoutWithTimer()
                    }
                    .fitPrimaryStyle()
                    .padding(.top, FitTodaySpacing.sm)
                } else {
                    HStack(spacing: FitTodaySpacing.sm) {
                        Button {
                            timerStore.toggle()
                        } label: {
                            Label(timerStore.isRunning ? "Pausar" : "Retomar", systemImage: timerStore.isRunning ? "pause.fill" : "play.fill")
                        }
                        .fitSecondaryStyle()
                        
                        Button("Ver exercício") {
                            startFromCurrentExercise()
                        }
                        .fitPrimaryStyle()
                    }
                    .padding(.top, FitTodaySpacing.sm)
                }
            }
        }
    }
    
    private func startWorkoutWithTimer() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            timerStore.start()
        }
    }

    // MARK: - Phase Mode Picker
    
    private var phaseModePicker: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.sm) {
            HStack {
                Text("Modo de treino")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textSecondary)
                
                Spacer()
                
                // Badge PRO/Free
                FitBadge(
                    text: isPro ? "PRO" : "Free",
                    style: isPro ? .pro : .info
                )
                
                Button {
                    showModeInfo()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(.body))
                        .foregroundStyle(FitTodayColor.textTertiary)
                }
                .accessibilityLabel("Informações sobre os modos")
            }
            
            Picker("Modo", selection: Binding(
                get: { displayMode },
                set: { setDisplayMode($0) }
            )) {
                ForEach(PhaseDisplayMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Escolha como exibir aquecimento e aeróbio")
            
            // Botão de regenerar treino
            regenerateButton
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .fitCardShadow()
    }
    
    @ViewBuilder
    private var regenerateButton: some View {
        Button {
            regenerateWorkoutPlan()
        } label: {
            HStack(spacing: FitTodaySpacing.sm) {
                if isRegenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isPro ? "sparkles" : "arrow.clockwise")
                        .font(.system(.body, weight: .semibold))
                }
                
                Text(regenerateButtonTitle)
                    .font(.system(.subheadline, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitTodaySpacing.sm)
            .foregroundStyle(isPro ? FitTodayColor.textInverse : FitTodayColor.brandPrimary)
            .background(isPro ? FitTodayColor.brandPrimary : FitTodayColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: FitTodayRadius.sm)
                    .stroke(FitTodayColor.brandPrimary, lineWidth: isPro ? 0 : 1.5)
            )
            .cornerRadius(FitTodayRadius.sm)
        }
        .disabled(isRegenerating || timerStore.hasStarted)
        .opacity(timerStore.hasStarted ? 0.5 : 1)
        .padding(.top, FitTodaySpacing.xs)
        .accessibilityHint(isPro ? "Regenera o treino usando IA" : "Regenera o treino localmente")
    }
    
    private var regenerateButtonTitle: String {
        if isRegenerating {
            return "Regenerando..."
        }
        return isPro ? "Regenerar com IA ✨" : "Regenerar treino"
    }
    
    private func showModeInfo() {
        // Mostra um alert com informações sobre os modos
        let proInfo = isPro ? "\n\n✨ PRO: Seu treino é otimizado com IA!" : "\n\n💡 Dica: Assine PRO para treinos personalizados com IA!"
        errorMessage = """
        Auto: Combina exercícios e atividades guiadas conforme seu perfil.
        
        Exercícios: Mostra apenas exercícios de aquecimento e cardio.
        
        Guiado: Mostra apenas atividades guiadas (ex: "Aeróbio Z2 12 min").\(proInfo)
        """
    }
    
    // MARK: - Regenerate Workout
    
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
        // Carrega perfil e check-in
        guard let profileRepo = resolver.resolve(UserProfileRepository.self) else {
            throw DomainError.repositoryFailure(reason: "Repositório de perfil não disponível.")
        }
        
        guard let profile = try await profileRepo.loadProfile() else {
            throw DomainError.profileNotFound
        }
        
        // Carrega o último check-in
        guard let checkInData = UserDefaults.standard.data(forKey: AppStorageKeys.lastDailyCheckInData),
              let checkIn = try? JSONDecoder().decode(DailyCheckIn.self, from: checkInData) else {
            throw DomainError.invalidInput(reason: "Responda o questionário diário primeiro.")
        }
        
        // Carrega blocos
        guard let blocksRepo = resolver.resolve(WorkoutBlocksRepository.self) else {
            throw DomainError.repositoryFailure(reason: "Repositório de blocos não disponível.")
        }
        
        let blocks = try await blocksRepo.loadBlocks()
        
        // Escolhe o compositor baseado no entitlement
        if isPro {
            // PRO: usa o compositor híbrido (OpenAI + fallback local)
            guard let composer = resolver.resolve(WorkoutPlanComposing.self) else {
                throw DomainError.repositoryFailure(reason: "Compositor não disponível.")
            }
            return try await composer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        } else {
            // Free: usa apenas o compositor local
            let localComposer = LocalWorkoutPlanComposer()
            return try await localComposer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        }
    }
    
    private func exerciseList(for plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            ForEach(plan.phases) { phase in
                PhaseSection(phase: phase, displayMode: displayMode)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: displayMode)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animationTrigger)
    }

    private struct PhaseSection: View {
        @EnvironmentObject private var router: AppRouter
        @EnvironmentObject private var sessionStore: WorkoutSessionStore

        let phase: WorkoutPlanPhase
        let displayMode: PhaseDisplayMode
        
        /// Fases que são afetadas pelo modo de exibição
        private var isFilterablePhase: Bool {
            phase.kind == .warmup || phase.kind == .aerobic || phase.kind == .finisher
        }
        
        /// Itens filtrados conforme o modo de exibição
        private var filteredItems: [WorkoutPlanItem] {
            guard isFilterablePhase else {
                // Força, Acessórios, etc. sempre mostram todos os itens
                return phase.items
            }
            
            switch displayMode {
            case .auto:
                // Mostra tudo (mesclado)
                return phase.items
            case .exercises:
                // Apenas exercícios
                return phase.items.filter { item in
                    if case .exercise = item { return true }
                    return false
                }
            case .guided:
                // Apenas atividades guiadas
                return phase.items.filter { item in
                    if case .activity = item { return true }
                    return false
                }
            }
        }

        var body: some View {
            // Não exibe a fase se não tiver itens após filtragem
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
                                let globalIndex = flattenedExerciseIndex(for: prescription.exercise.id)
                                WorkoutExerciseRow(
                                    index: globalIndex + 1,
                                    prescription: prescription,
                                    isCurrent: globalIndex == sessionStore.currentExerciseIndex
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    router.push(.workoutExercisePreview(prescription), on: .home)
                                }
                                .accessibilityHint("Toque para ver detalhes do exercício")
                            }
                        }
                    }
                }
                .padding(.top, FitTodaySpacing.md)
            }
        }

        private var phaseHeaderTitle: String {
            var title = phase.title
            
            // Adiciona indicador do modo quando aplicável
            if isFilterablePhase && displayMode != .auto {
                let modeIndicator = displayMode == .exercises ? "🏋️" : "🎯"
                title = "\(title) \(modeIndicator)"
            }
            
            if let rpe = phase.rpeTarget {
                return "\(title) · RPE \(rpe)"
            }
            return title
        }

        /// Mapeia o exercício atual para o índice global (plano "flat") para compatibilidade com o fluxo da sessão.
        private func flattenedExerciseIndex(for exerciseId: String) -> Int {
            sessionStore.exercises.firstIndex(where: { $0.exercise.id == exerciseId }) ?? 0
        }
    }

    private struct ActivityRow: View {
        let activity: ActivityPrescription

        var body: some View {
            HStack(alignment: .top, spacing: FitTodaySpacing.md) {
                Image(systemName: iconName)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                    Text(activity.title)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)

                    Text("\(activity.durationMinutes) min")
                        .font(.system(.footnote))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    if let notes = activity.notes {
                        Text(notes)
                            .font(.system(.caption))
                            .foregroundStyle(FitTodayColor.textTertiary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                FitBadge(text: "GUIADO", style: .info)
            }
            .padding()
            .background(FitTodayColor.surface)
            .cornerRadius(FitTodayRadius.md)
            .fitCardShadow()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(activity.title), \(activity.durationMinutes) minutos")
        }

        private var iconName: String {
            switch activity.kind {
            case .mobility: return "figure.cooldown"
            case .aerobicZone2: return "heart"
            case .aerobicIntervals: return "waveform.path.ecg"
            case .breathing: return "lungs"
            case .cooldown: return "leaf"
            }
        }
    }

    private var footerActions: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            Button("Retomar exercício atual") {
                startFromCurrentExercise()
            }
            .fitSecondaryStyle()

            Button("Pular treino de hoje") {
                finishSession(as: .skipped)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.orange)
            .padding(.top, FitTodaySpacing.sm)
            .disabled(isFinishing)
        }
    }

    private func startFromCurrentExercise() {
        guard sessionStore.plan != nil else {
            errorMessage = "Nenhum plano encontrado."
            return
        }
        router.push(.exerciseDetail, on: .home)
    }

    private func finishSession(as status: WorkoutStatus) {
        guard !isFinishing else { return }
        isFinishing = true
        timerStore.pause() // Pausa o timer ao finalizar
        
        Task {
            do {
                try await sessionStore.finish(status: status)
                timerStore.reset() // Reseta para próximo treino
                router.push(.workoutSummary, on: .home)
            } catch {
                errorMessage = error.localizedDescription
            }
            isFinishing = false
        }
    }
}

private struct WorkoutMetaChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: FitTodaySpacing.xs) {
            Image(systemName: icon)
                .font(.system(.footnote, weight: .semibold))
            Text(label)
                .font(.system(.footnote, weight: .medium))
        }
        .padding(.horizontal, FitTodaySpacing.sm)
        .padding(.vertical, FitTodaySpacing.xs)
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.pill)
    }
}

private struct WorkoutExerciseRow: View {
    let index: Int
    let prescription: ExercisePrescription
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: FitTodaySpacing.md) {
            ExerciseThumbnail(media: prescription.exercise.media, size: 64)

            VStack(alignment: .leading, spacing: FitTodaySpacing.xs) {
                Text("\(index). \(prescription.exercise.name)")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(FitTodayColor.textPrimary)
                Text("\(prescription.sets)x · \(prescription.reps.lowerBound)-\(prescription.reps.upperBound) reps")
                    .font(.system(.footnote))
                    .foregroundStyle(FitTodayColor.textSecondary)
                if let tip = prescription.tip {
                    Text(tip)
                        .font(.system(.caption))
                        .foregroundStyle(FitTodayColor.textTertiary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if isCurrent {
                FitBadge(text: "Atual", style: .info)
            }
        }
        .padding()
        .background(FitTodayColor.surface)
        .cornerRadius(FitTodayRadius.md)
        .fitCardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prescription.exercise.name), \(prescription.sets) séries de \(prescription.reps.display) repetições")
    }
}



