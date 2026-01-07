//
//  HomeViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Combine
import SwiftUI
import Swinject

/// Estado da jornada do usuário na Home.
enum HomeJourneyState: Equatable {
    /// Carregando dados iniciais.
    case loading
    /// Usuário não possui perfil → deve ir para onboarding/setup.
    case noProfile
    /// Usuário possui perfil mas não respondeu questionário de hoje → ir para questionário diário.
    case needsDailyCheckIn(profile: UserProfile)
    /// Questionário respondido, treino gerado disponível.
    case workoutReady(profile: UserProfile)
    /// Treino concluído/pulado hoje - aguardar próximo dia.
    case workoutCompleted(profile: UserProfile)
    /// Erro ao carregar dados.
    case error(message: String)
}

@MainActor
final class HomeViewModel: ObservableObject, ErrorPresenting {
    @Published private(set) var journeyState: HomeJourneyState = .loading
    @Published private(set) var entitlement: ProEntitlement = .free
    @Published private(set) var topPrograms: [Program] = []
    @Published private(set) var weekWorkouts: [LibraryWorkout] = []
    @Published private(set) var dailyWorkoutState: DailyWorkoutState = DailyWorkoutState()
    @Published var errorMessage: ErrorMessage? // ErrorPresenting protocol

    private let resolver: Resolver
    private let dailyStateManager = DailyWorkoutStateManager.shared

    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    /// Indica se o usuário pode trocar a sugestão do treino
    var canSwapSuggestion: Bool {
        dailyWorkoutState.canSwap
    }

    // MARK: - Computed Properties

    var userProfile: UserProfile? {
        switch journeyState {
        case .needsDailyCheckIn(let profile), .workoutReady(let profile), .workoutCompleted(let profile):
            return profile
        default:
            return nil
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Bom dia"
        case 12..<18:
            return "Boa tarde"
        default:
            return "Boa noite"
        }
    }

    var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: Date()).capitalized
    }

    var goalBadgeText: String? {
        guard let profile = userProfile else { return nil }
        switch profile.mainGoal {
        case .hypertrophy: return "💪 Hipertrofia"
        case .conditioning: return "🔥 Condicionamento"
        case .endurance: return "🏃 Resistência"
        case .weightLoss: return "⚖️ Emagrecimento"
        case .performance: return "🎯 Performance"
        }
    }

    var ctaTitle: String {
        switch journeyState {
        case .loading:
            return "Carregando..."
        case .noProfile:
            return "Configurar Perfil"
        case .needsDailyCheckIn:
            return "Responder Questionário"
        case .workoutReady:
            return "Ver Treino de Hoje"
        case .workoutCompleted:
            return "Próximo treino em breve"
        case .error:
            return "Tentar Novamente"
        }
    }

    var ctaSubtitle: String? {
        switch journeyState {
        case .needsDailyCheckIn:
            return "2 perguntas rápidas antes de começar"
        case .workoutReady:
            if canSwapSuggestion {
                return "Não gostou? Toque em trocar para nova sugestão"
            }
            return "Treino personalizado pronto para você"
        case .workoutCompleted:
            return "Você já treinou hoje! Descanse e volte amanhã"
        default:
            return nil
        }
    }

    // MARK: - Actions

    func onAppear() {
        Task {
            await loadUserData()
        }
    }

    func refresh() async {
        await loadUserData()
    }

    private func loadUserData() async {
        journeyState = .loading

        guard let profileRepo = resolver.resolve(UserProfileRepository.self),
              let entitlementRepo = resolver.resolve(EntitlementRepository.self) else {
            journeyState = .error(message: "Erro de configuração do app.")
            handleError(DomainError.repositoryFailure(reason: "Serviços não configurados"))
            return
        }

        do {
            // Carregar entitlement (respeitar debug override se ativo)
            #if DEBUG
            if DebugEntitlementOverride.shared.isEnabled {
                entitlement = DebugEntitlementOverride.shared.entitlement
            } else {
                entitlement = try await entitlementRepo.currentEntitlement()
            }
            #else
            entitlement = try await entitlementRepo.currentEntitlement()
            #endif
            
            let loadedProfile = try await profileRepo.loadProfile()

            guard let profile = loadedProfile else {
                journeyState = .noProfile
                // Carregar programas mesmo sem perfil
                await loadProgramsAndWorkouts(profile: nil)
                return
            }

            // Atualizar estado do treino diário
            dailyWorkoutState = dailyStateManager.loadTodayState()
            
            // Verificar se já concluiu/pulou o treino hoje
            if dailyWorkoutState.isFinished {
                journeyState = .workoutCompleted(profile: profile)
                await loadProgramsAndWorkouts(profile: profile)
                return
            }

            // Verificar se já respondeu hoje
            let hasAnsweredToday = await checkIfAnsweredToday()

            if hasAnsweredToday {
                journeyState = .workoutReady(profile: profile)
            } else {
                journeyState = .needsDailyCheckIn(profile: profile)
            }

            // Carregar programas e treinos recomendados
            await loadProgramsAndWorkouts(profile: profile)

        } catch {
            journeyState = .error(message: "Não foi possível carregar seus dados.")
            handleError(error) // ErrorPresenting protocol
        }
    }

    private func loadProgramsAndWorkouts(profile: UserProfile?) async {
        let recommender = ProgramRecommender()
        var history: [WorkoutHistoryEntry] = []
        
        // Carregar histórico para recomendação
        if let historyRepo = resolver.resolve(WorkoutHistoryRepository.self) {
            do {
                history = try await historyRepo.listEntries()
            } catch {
                #if DEBUG
                print("[Home] Erro ao carregar histórico: \(error)")
                #endif
            }
        }
        
        // Carregar programas "Top for You" (até 4) usando o recomendador
        if let programRepo = resolver.resolve(ProgramRepository.self) {
            do {
                let allPrograms = try await programRepo.listPrograms()
                topPrograms = recommender.recommend(
                    programs: allPrograms,
                    profile: profile,
                    history: history,
                    limit: 4
                )
            } catch {
                #if DEBUG
                print("[Home] Erro ao carregar programas: \(error)")
                #endif
            }
        }

        // Carregar treinos da semana (até 3) usando o recomendador
        if let workoutRepo = resolver.resolve(LibraryWorkoutsRepository.self) {
            do {
                let allWorkouts = try await workoutRepo.loadWorkouts()
                weekWorkouts = recommender.recommendWorkouts(
                    workouts: allWorkouts,
                    profile: profile,
                    history: history,
                    limit: 3
                )
            } catch {
                #if DEBUG
                print("[Home] Erro ao carregar treinos: \(error)")
                #endif
            }
        }
    }

    private func checkIfAnsweredToday() async -> Bool {
        // Por enquanto, verificar via UserDefaults a data da última resposta
        // Futuramente, isso pode vir de um repositório de DailyCheckIn
        guard let lastCheckIn = UserDefaults.standard.object(forKey: AppStorageKeys.lastDailyCheckInDate) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(lastCheckIn)
    }

    /// Marca que o usuário respondeu o questionário hoje.
    func markDailyCheckInCompleted() {
        UserDefaults.standard.set(Date(), forKey: AppStorageKeys.lastDailyCheckInDate)
        Task {
            await loadUserData()
        }
    }
    
    /// Tenta trocar a sugestão do treino diário (1x por dia)
    func swapDailySuggestion() {
        guard dailyStateManager.trySwap() else {
            #if DEBUG
            print("[Home] Não foi possível trocar - limite atingido")
            #endif
            return
        }
        
        // Atualizar estado local
        dailyWorkoutState = dailyStateManager.loadTodayState()
        
        // Recarregar para gerar nova sugestão
        Task {
            await loadUserData()
        }
    }
    
    /// Marca que o treino foi concluído
    func markWorkoutCompleted() {
        dailyStateManager.markCompleted()
        dailyWorkoutState = dailyStateManager.loadTodayState()
        
        Task {
            await loadUserData()
        }
    }
    
    /// Marca que o treino foi pulado
    func markWorkoutSkipped() {
        dailyStateManager.markSkipped()
        dailyWorkoutState = dailyStateManager.loadTodayState()
        
        Task {
            await loadUserData()
        }
    }
    
    /// Regera o plano diário baseado no último questionário salvo.
    func regenerateDailyWorkoutPlan() async throws -> WorkoutPlan {
        guard
            let profileRepo = resolver.resolve(UserProfileRepository.self),
            let blocksRepo = resolver.resolve(WorkoutBlocksRepository.self),
            let composer = resolver.resolve(WorkoutPlanComposing.self)
        else {
            throw DomainError.repositoryFailure(reason: "Dependências para gerar o treino não estão configuradas.")
        }
        
        guard let profile = try await profileRepo.loadProfile() else {
            throw DomainError.profileNotFound
        }
        
        guard let checkIn = loadStoredCheckIn() else {
            throw DomainError.invalidInput(reason: "Precisamos que você responda o questionário de hoje novamente.")
        }
        
        let generator = GenerateWorkoutPlanUseCase(
            blocksRepository: blocksRepo,
            composer: composer
        )
        return try await generator.execute(profile: profile, checkIn: checkIn)
    }
    
    private func loadStoredCheckIn() -> DailyCheckIn? {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.lastDailyCheckInData) else {
            return nil
        }
        return try? JSONDecoder().decode(DailyCheckIn.self, from: data)
    }

    /// Observar mudanças no entitlement em background.
    func startObservingEntitlement() {
        Task {
            guard let repo = resolver.resolve(EntitlementRepository.self) else { return }
            for await newEntitlement in repo.entitlementStream() {
                self.entitlement = newEntitlement
            }
        }
    }
}

