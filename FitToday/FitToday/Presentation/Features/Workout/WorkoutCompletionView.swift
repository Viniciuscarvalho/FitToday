//
//  WorkoutCompletionView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject
import UIKit

struct WorkoutCompletionView: View {
    @Environment(AppRouter.self) private var router
    @Environment(WorkoutSessionStore.self) private var sessionStore
    @Environment(WorkoutTimerStore.self) private var workoutTimer
    @Environment(\.dependencyResolver) private var resolver

    @State private var isGeneratingNewPlan = false
    @State private var errorMessage: String?
    @State private var isProfileIncomplete = false
    @State private var showProfilePrompt = false

    @State private var canUseHealthKit = false
    @State private var healthKitState: HealthKitAuthorizationState = .notDetermined
    @State private var isExportingHealthKit = false
    @State private var healthKitExportMessage: String?

    // Rating state
    @State private var selectedRating: WorkoutRating?
    @State private var hasRated = false
    @State private var isSavingRating = false

    // Check-in state
    @State private var showCheckInSheet = false
    @State private var showCelebration = false
    @State private var isInGroup = false
    @State private var currentEntry: WorkoutHistoryEntry?

    // Success feedback
    @State private var didPlayHaptic = false

    var body: some View {
        VStack(spacing: FitTodaySpacing.lg) {
            Image(systemName: statusIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundStyle(statusColor)

            VStack(spacing: FitTodaySpacing.sm) {
                Text(titleText)
                    .font(.system(.title2, weight: .bold))
                Text(descriptionText)
                    .font(.system(.body))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Workout summary statistics for completed workouts
            if status == .completed {
                workoutSummaryCard
            }

            // Rating prompt for completed workouts
            if status == .completed && !hasRated {
                WorkoutRatingView(
                    selectedRating: $selectedRating,
                    onRatingSelected: { rating in
                        Task { await saveRating(rating) }
                    },
                    onSkip: {
                        hasRated = true
                    }
                )
                .padding(.horizontal)
            }

            // Check-in button (only for users in a group after rating)
            if status == .completed && hasRated && isInGroup {
                Button {
                    showCheckInSheet = true
                } label: {
                    Label("Fazer Check-in com Foto", systemImage: "camera.fill")
                }
                .fitPrimaryStyle()
                .padding(.horizontal)
            }

            // Prompt para completar perfil (se incompleto)
            if isProfileIncomplete && status == .completed && hasRated {
                profileCompletionPrompt
            }

            VStack(spacing: FitTodaySpacing.sm) {
                // Se foi pulado, oferece opção de gerar novo treino
                if status == .skipped {
                    Button("Gerar Novo Treino") {
                        generateNewWorkout()
                    }
                    .fitPrimaryStyle()
                    .disabled(isGeneratingNewPlan)
                    
                    if isGeneratingNewPlan {
                        ProgressView()
                            .padding()
                    }
                }
                
                Button(primaryCTATitle) {
                    finalizeFlow(goToHistory: false)
                }
                .fitPrimaryStyle()
                .disabled(isGeneratingNewPlan)

                if status == .completed {
                    if canUseHealthKit {
                        Button(isExportingHealthKit ? "Exportando..." : "Exportar para Apple Health") {
                            Task { await exportToHealthKitIfPossible() }
                        }
                        .fitSecondaryStyle()
                        .disabled(isExportingHealthKit || healthKitState != .authorized)
                    }
                    
                    Button("Ver histórico") {
                        finalizeFlow(goToHistory: true)
                    }
                    .fitSecondaryStyle()
                }
            }
            
            if let msg = healthKitExportMessage {
                Text(msg)
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(FitTodayColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Resumo")
        .navigationBarBackButtonHidden(true)
        .task {
            await checkProfileCompletion()
            await loadHealthKitAvailability()
            await checkGroupMembership()
            loadCurrentEntry()
            playSuccessHapticIfNeeded()
        }
        .sheet(isPresented: $showProfilePrompt) {
            if let resolver = resolver as? Resolver {
                OnboardingFlowView(resolver: resolver, isEditing: true) {
                    showProfilePrompt = false
                    isProfileIncomplete = false
                }
            }
        }
        .alert("Erro", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Ocorreu um erro ao gerar novo treino.")
        }
        .sheet(isPresented: $showCheckInSheet) {
            if let entry = currentEntry,
               let checkInUseCase = resolver.resolve(CheckInUseCase.self),
               let networkMonitor = resolver.resolve(NetworkMonitor.self) {
                CheckInPhotoView(
                    viewModel: CheckInViewModel(
                        checkInUseCase: checkInUseCase,
                        workoutEntry: entry,
                        networkMonitor: networkMonitor
                    ),
                    workoutEntry: entry,
                    onSuccess: { _ in
                        showCelebration = true
                    }
                )
            }
        }
        .overlay {
            if showCelebration {
                CelebrationOverlay(type: .checkInComplete)
                    .onTapGesture {
                        showCelebration = false
                    }
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        showCelebration = false
                    }
            }
        }
    }
    
    /// Prompt para completar o perfil após primeiro treino
    private var profileCompletionPrompt: some View {
        VStack(spacing: FitTodaySpacing.sm) {
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(FitTodayColor.brandPrimary)
                Text("Personalize seu perfil")
                    .font(.headline)
                    .foregroundStyle(FitTodayColor.textPrimary)
            }
            
            Text("Complete seu perfil para treinos ainda mais personalizados")
                .font(.footnote)
                .foregroundStyle(FitTodayColor.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Completar agora") {
                showProfilePrompt = true
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(FitTodayColor.brandPrimary)
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.brandPrimary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(FitTodayColor.brandPrimary.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    /// Verifica se o perfil está incompleto
    private func checkProfileCompletion() async {
        guard let profileRepo = resolver.resolve(UserProfileRepository.self) else { return }
        do {
            if let profile = try await profileRepo.loadProfile() {
                isProfileIncomplete = !profile.isProfileComplete
            }
        } catch {
            // Silently fail - não é crítico
        }
    }

    /// Checks if user is in a group to enable check-in feature
    private func checkGroupMembership() async {
        guard let authRepo = resolver.resolve(AuthenticationRepository.self) else {
            isInGroup = false
            return
        }

        do {
            if let user = try await authRepo.currentUser() {
                isInGroup = user.currentGroupId != nil
            }
        } catch {
            isInGroup = false
        }
    }

    /// Loads the current workout entry for check-in
    private func loadCurrentEntry() {
        guard let planId = sessionStore.plan?.id,
              let historyRepo = resolver.resolve(WorkoutHistoryRepository.self) else {
            return
        }

        Task {
            do {
                let entries = try await historyRepo.listEntries(limit: 1, offset: 0)
                if let entry = entries.first, entry.planId == planId {
                    currentEntry = entry
                }
            } catch {
                #if DEBUG
                print("[WorkoutCompletion] Failed to load current entry: \(error)")
                #endif
            }
        }
    }

    private func loadHealthKitAvailability() async {
        guard status == .completed else { return }
        
        guard
            let entitlementRepo = resolver.resolve(EntitlementRepository.self),
            let healthKit = resolver.resolve(HealthKitServicing.self)
        else {
            canUseHealthKit = false
            return
        }
        
        do {
            let entitlement = try await entitlementRepo.currentEntitlement()
            guard entitlement.isPro else {
                canUseHealthKit = false
                return
            }
            
            canUseHealthKit = true
            healthKitState = await healthKit.authorizationState()
        } catch {
            // Não bloquear o fluxo por HealthKit
            canUseHealthKit = false
        }
    }
    
    private func exportToHealthKitIfPossible() async {
        guard status == .completed else { return }
        guard canUseHealthKit, healthKitState == .authorized else {
            healthKitExportMessage = "Conecte o Apple Health antes de exportar."
            return
        }
        guard let plan = sessionStore.plan else { return }
        guard
            let healthKit = resolver.resolve(HealthKitServicing.self),
            let historyRepo = resolver.resolve(WorkoutHistoryRepository.self)
        else { return }
        
        do {
            isExportingHealthKit = true
            defer { isExportingHealthKit = false }
            
            let receipt = try await healthKit.exportWorkout(plan: plan, completedAt: Date())
            
            // Vincular UUID ao último item do histórico com este planId (melhor esforço)
            let recent = try await historyRepo.listEntries(limit: 20, offset: 0)
            if let idx = recent.firstIndex(where: { $0.planId == plan.id }) {
                var updated = recent[idx]
                updated.healthKitWorkoutUUID = receipt.workoutUUID
                try await historyRepo.saveEntry(updated)
            }
            
            healthKitExportMessage = "Exportado para Apple Health."
        } catch {
            healthKitExportMessage = "Falha ao exportar para Apple Health: \(error.localizedDescription)"
        }
    }

    private func generateNewWorkout() {
        guard let profileRepo = resolver.resolve(UserProfileRepository.self),
              let blocksRepo = resolver.resolve(WorkoutBlocksRepository.self),
              let composer = resolver.resolve(WorkoutPlanComposing.self) else {
            errorMessage = "Não foi possível carregar as configurações necessárias."
            return
        }
        
        isGeneratingNewPlan = true
        
        Task {
            do {
                // Busca o último checkIn usado (pode ser armazenado em UserDefaults ou no sessionStore)
                // Por enquanto, vamos usar o checkIn padrão baseado no perfil
                let profileUseCase = GetUserProfileUseCase(repository: profileRepo)
                guard let profile = try await profileUseCase.execute() else {
                    errorMessage = "Perfil não encontrado. Configure seu perfil primeiro."
                    isGeneratingNewPlan = false
                    return
                }
                
                // Gera um novo checkIn baseado no último foco usado (ou padrão)
                // Para simplificar, vamos usar o mesmo foco do plano atual
                let currentFocus = sessionStore.plan?.focus ?? .fullBody
                let checkIn = DailyCheckIn(
                    focus: currentFocus,
                    sorenessLevel: .none, // Novo treino sem considerar dor anterior
                    sorenessAreas: [],
                    energyLevel: 5
                )
                
                let generator = GenerateWorkoutPlanUseCase(
                    blocksRepository: blocksRepo,
                    composer: composer
                )
                let newPlan = try await generator.execute(profile: profile, checkIn: checkIn)
                
                await MainActor.run {
                    sessionStore.reset()
                    sessionStore.start(with: newPlan)
                    isGeneratingNewPlan = false
                    
                    // Navega para o novo treino
                    router.pop(on: .home) // summary
                    router.push(.workoutPlan(newPlan.id), on: .home)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGeneratingNewPlan = false
                }
            }
        }
    }

    private func finalizeFlow(goToHistory: Bool) {
        sessionStore.reset()
        router.pop(on: .home) // summary
        router.pop(on: .home) // detail
        router.pop(on: .home) // workout list

        if goToHistory {
            router.select(tab: .activity)
        }
    }

    private func saveRating(_ rating: WorkoutRating?) async {
        guard let planId = sessionStore.plan?.id else {
            hasRated = true
            return
        }

        guard let historyRepo = resolver.resolve(WorkoutHistoryRepository.self) else {
            hasRated = true
            return
        }

        isSavingRating = true
        defer { isSavingRating = false }

        let useCase = SaveWorkoutRatingUseCase(historyRepository: historyRepo)

        do {
            try await useCase.execute(rating: rating, planId: planId)
            hasRated = true
        } catch {
            // Still mark as rated to allow user to continue
            hasRated = true
            #if DEBUG
            print("[WorkoutCompletion] Failed to save rating: \(error)")
            #endif
        }
    }

    private var statusIcon: String {
        switch status {
        case .completed: return "checkmark.seal.fill"
        case .skipped: return "figure.walk"
        }
    }

    private var statusColor: Color {
        switch status {
        case .completed: return .green
        case .skipped: return .orange
        }
    }

    private var titleText: String {
        switch status {
        case .completed: return "Treino concluído!"
        case .skipped: return "Treino pulado"
        }
    }

    private var descriptionText: String {
        switch status {
        case .completed:
            return "Registramos sua sessão de hoje no histórico. Mantenha a consistência!"
        case .skipped:
            return "Tudo bem! Você pode gerar um novo treino agora mesmo ou tentar novamente depois."
        }
    }

    private var primaryCTATitle: String {
        status == .completed ? "Voltar para Home" : "Voltar para Home"
    }

    private var status: WorkoutStatus {
        sessionStore.lastCompletionStatus ?? .completed
    }

    // MARK: - Workout Summary Card

    private var workoutSummaryCard: some View {
        VStack(spacing: FitTodaySpacing.md) {
            // Total workout time
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tempo Total")
                        .font(.footnote)
                        .foregroundStyle(FitTodayColor.textSecondary)
                    Text(workoutTimer.formattedTime)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }

                Spacer()
            }

            Divider()

            // Exercises completed
            HStack(spacing: FitTodaySpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(FitTodayColor.brandPrimary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Exercícios")
                        .font(.footnote)
                        .foregroundStyle(FitTodayColor.textSecondary)
                    Text("\(sessionStore.completedExercisesCount) de \(sessionStore.exerciseCount)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(FitTodayColor.textPrimary)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: FitTodayRadius.md)
                .fill(FitTodayColor.brandPrimary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: FitTodayRadius.md)
                        .stroke(FitTodayColor.brandPrimary.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Success Feedback

    private func playSuccessHapticIfNeeded() {
        guard status == .completed, !didPlayHaptic else { return }
        didPlayHaptic = true

        // Play success haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
