//
//  WorkoutCompletionView.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

struct WorkoutCompletionView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: WorkoutSessionStore
    @Environment(\.dependencyResolver) private var resolver
    
    @State private var isGeneratingNewPlan = false
    @State private var errorMessage: String?
    @State private var isProfileIncomplete = false
    @State private var showProfilePrompt = false
    
    @State private var canUseHealthKit = false
    @State private var healthKitState: HealthKitAuthorizationState = .notDetermined
    @State private var isExportingHealthKit = false
    @State private var healthKitExportMessage: String?

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
            
            // Prompt para completar perfil (se incompleto)
            if isProfileIncomplete && status == .completed {
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
            router.select(tab: .history)
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
}
