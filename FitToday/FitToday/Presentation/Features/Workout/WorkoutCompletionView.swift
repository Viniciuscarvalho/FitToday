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
                    Button("Ver histórico") {
                        finalizeFlow(goToHistory: true)
                    }
                    .fitSecondaryStyle()
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Resumo")
        .navigationBarBackButtonHidden(true)
        .alert("Erro", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Ocorreu um erro ao gerar novo treino.")
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
                    sorenessAreas: []
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
