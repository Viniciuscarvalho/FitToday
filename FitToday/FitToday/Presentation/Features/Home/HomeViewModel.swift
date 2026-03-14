//
//  HomeViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import SwiftUI
import Swinject

/// Estado do card de personal trainer na Home.
enum PersonalTrainerHomeCardState: Equatable {
    /// Carregando dados do personal trainer.
    case loading
    /// Usuário não tem personal conectado.
    case noTrainer
    /// Usuário tem personal conectado (com ou sem treino hoje).
    case hasTrainer(trainer: PersonalTrainer, todayWorkout: TrainerWorkout?)
}

/// Estado da jornada do usuário na Home.
enum HomeJourneyState: Equatable {
    /// Carregando dados iniciais.
    case loading
    /// Usuário não possui perfil → deve ir para onboarding/setup.
    case noProfile
    /// Perfil carregado, treino pronto para gerar via IA.
    case workoutReady(profile: UserProfile)
    /// Treino concluído/pulado hoje - aguardar próximo dia.
    case workoutCompleted(profile: UserProfile)
    /// Erro ao carregar dados.
    case error(message: String)
}

// 💡 Learn: @Observable substitui ObservableObject + @Published
// Benefícios: observação granular, melhor performance, menos boilerplate
@MainActor
@Observable final class HomeViewModel: ErrorPresenting {
    private(set) var journeyState: HomeJourneyState = .loading
    private(set) var entitlement: ProEntitlement = .free
    private(set) var topPrograms: [Program] = []
    private(set) var dailyWorkoutState: DailyWorkoutState = DailyWorkoutState()
    private(set) var historyEntries: [WorkoutHistoryEntry] = []
    private(set) var isAiWorkoutEnabled = true
    private(set) var isPersonalTrainerEnabled = false
    private(set) var isGamificationEnabled = false
    private(set) var userXP: UserXP?
    private(set) var isLoadingXP = false
    private(set) var personalTrainerCardState: PersonalTrainerHomeCardState = .loading
    private(set) var todayWorkoutId: String?
    private(set) var todayWorkout: ProgramWorkout?
    private(set) var todayProgramName: String?
    private(set) var isLoadingWorkout: Bool = false
    var errorMessage: ErrorMessage? // ErrorPresenting protocol

    // User info - stored properties for proper @Observable tracking
    private(set) var userName: String?
    private(set) var userPhotoURL: URL?

    private let resolver: Resolver
    private let dailyStateManager = DailyWorkoutStateManager.shared
    private var trainerObservationTask: Task<Void, Never>?

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
        case .workoutReady(let profile), .workoutCompleted(let profile):
            return profile
        default:
            return nil
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "home.greeting.morning".localized
        case 12..<18:
            return "home.greeting.afternoon".localized
        default:
            return "home.greeting.evening".localized
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
        case .hypertrophy: return "goal.badge.hypertrophy".localized
        case .conditioning: return "goal.badge.conditioning".localized
        case .endurance: return "goal.badge.endurance".localized
        case .weightLoss: return "goal.badge.weight_loss".localized
        case .performance: return "goal.badge.performance".localized
        }
    }

    // MARK: - Quick Stats

    var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        return historyEntries.filter { $0.date >= weekStart }.count
    }

    var caloriesBurnedFormatted: String {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return "0"
        }
        let weekCalories = historyEntries
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + ($1.caloriesBurned ?? 0) }

        if weekCalories >= 1000 {
            return String(format: "%.1fk", Double(weekCalories) / 1000.0)
        }
        return "\(weekCalories)"
    }

    var streakDays: Int {
        guard !historyEntries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDates = historyEntries
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)

        guard let mostRecent = sortedDates.first else { return 0 }

        // Check if streak is still active (workout today or yesterday)
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard mostRecent >= yesterday else { return 0 }

        var streak = 1
        var currentDate = mostRecent

        for date in sortedDates.dropFirst() {
            let expectedPrevious = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            if date == expectedPrevious {
                streak += 1
                currentDate = date
            } else if date == currentDate {
                // Same day, skip
                continue
            } else {
                break
            }
        }

        return streak
    }

    /// Days of the week with completed workouts (0=Sunday, 6=Saturday)
    var weekCompletedDays: Set<Int> {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }
        var days = Set<Int>()
        for entry in historyEntries where entry.date >= weekStart {
            let weekday = calendar.component(.weekday, from: entry.date) - 1 // 0=Sunday
            days.insert(weekday)
        }
        return days
    }

    var weeklyTarget: Int {
        userProfile?.weeklyFrequency ?? 4
    }

    var totalSetsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        return historyEntries
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + ($1.completedExercises?.count ?? 0) }
    }

    var avgDurationMinutes: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        let weekEntries = historyEntries.filter { $0.date >= weekStart }
        guard !weekEntries.isEmpty else { return 0 }
        let totalMinutes = weekEntries.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
        return totalMinutes / weekEntries.count
    }

    var ctaTitle: String {
        switch journeyState {
        case .loading:
            return "home.cta.loading".localized
        case .noProfile:
            return "home.cta.setup_profile".localized
        case .workoutReady:
            return "home.cta.view_today_workout".localized
        case .workoutCompleted:
            return "home.cta.next_workout_soon".localized
        case .error:
            return "home.cta.retry".localized
        }
    }

    var ctaSubtitle: String? {
        switch journeyState {
        case .workoutReady:
            if canSwapSuggestion {
                return "home.cta.subtitle.swap".localized
            }
            return "home.cta.subtitle.workout_ready".localized
        case .workoutCompleted:
            return "home.cta.subtitle.completed".localized
        default:
            return nil
        }
    }

    // MARK: - Actions

    func onAppear() {
        Task {
            await loadUserData()
            if isPersonalTrainerEnabled {
                startObservingTrainerRelationship()
            }
        }
    }

    func refresh() async {
        await loadUserData()
    }

    private func loadUserData() async {
        journeyState = .loading

        // Check feature flags
        if let featureFlags = resolver.resolve(FeatureFlagChecking.self) {
            isAiWorkoutEnabled = await featureFlags.isFeatureEnabled(.aiWorkoutGenerationEnabled)
            isPersonalTrainerEnabled = await featureFlags.isFeatureEnabled(.personalTrainerEnabled)
            isGamificationEnabled = await featureFlags.isFeatureEnabled(.gamificationEnabled)
        }

        // Load user info from UserDefaults or Firebase Auth
        await loadUserInfo()

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
                // Carregar programas e personal trainer mesmo sem perfil
                async let programsTask: Void = loadProgramsAndWorkouts(profile: nil)
                async let ptTask: Void = loadPersonalTrainerState()
                _ = await (programsTask, ptTask)
                return
            }

            // Atualizar estado do treino diário
            dailyWorkoutState = dailyStateManager.loadTodayState()

            // Verificar se já concluiu/pulou o treino hoje
            if dailyWorkoutState.isFinished {
                journeyState = .workoutCompleted(profile: profile)
                async let programsTask: Void = loadProgramsAndWorkouts(profile: profile)
                async let ptTask: Void = loadPersonalTrainerState()
                async let xpTask: Void = loadUserXP()
                _ = await (programsTask, ptTask, xpTask)
                return
            }

            journeyState = .workoutReady(profile: profile)

            // Carregar programas, personal trainer e XP em paralelo
            async let programsTask: Void = loadProgramsAndWorkouts(profile: profile)
            async let personalTrainerTask: Void = loadPersonalTrainerState()
            async let xpTask: Void = loadUserXP()
            _ = await (programsTask, personalTrainerTask, xpTask)

        } catch {
            journeyState = .error(message: "Não foi possível carregar seus dados.")
            handleError(error) // ErrorPresenting protocol
        }
    }

    private func loadProgramsAndWorkouts(profile: UserProfile?) async {
        let recommender = ProgramRecommender()

        // Carregar histórico para recomendação e stats
        if let historyRepo = resolver.resolve(WorkoutHistoryRepository.self) {
            do {
                historyEntries = try await historyRepo.listEntries()
            } catch {
                historyEntries = []
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
                    history: historyEntries,
                    limit: 4
                )
            } catch {
                #if DEBUG
                print("[Home] Erro ao carregar programas: \(error)")
                #endif
            }
        }

        // Load today's workout from the best recommended program
        await loadTodayWorkout()
    }

    private func loadTodayWorkout() async {
        guard let bestProgram = topPrograms.first else { return }

        todayProgramName = bestProgram.shortName

        guard let programRepo = resolver.resolve(ProgramRepository.self),
              let workoutRepo = resolver.resolve(ProgramWorkoutRepository.self) else {
            return
        }

        let useCase = LoadProgramWorkoutsUseCase(
            programRepository: programRepo,
            workoutRepository: workoutRepo
        )

        isLoadingWorkout = true
        defer { isLoadingWorkout = false }

        do {
            let workouts = try await useCase.execute(programId: bestProgram.id)
            if !workouts.isEmpty {
                let index = workoutsThisWeek % workouts.count
                todayWorkout = workouts[index]
            }
        } catch {
            #if DEBUG
            print("[Home] Erro ao carregar treino do dia: \(error)")
            #endif
        }
    }

    // MARK: - Gamification

    private func loadUserXP() async {
        guard isGamificationEnabled,
              let xpRepo = resolver.resolve(XPRepository.self) else {
            userXP = nil
            return
        }

        isLoadingXP = true
        defer { isLoadingXP = false }

        do {
            userXP = try await xpRepo.getUserXP()
        } catch {
            userXP = nil
            #if DEBUG
            print("[Home] Failed to load user XP: \(error)")
            #endif
        }
    }

    // MARK: - Personal Trainer

    private func loadPersonalTrainerState() async {
        guard isPersonalTrainerEnabled else {
            personalTrainerCardState = .noTrainer
            return
        }

        guard let getCurrentTrainerUseCase = resolver.resolve(GetCurrentTrainerUseCaseProtocol.self) else {
            personalTrainerCardState = .noTrainer
            return
        }

        do {
            guard let result = try await getCurrentTrainerUseCase.execute() else {
                personalTrainerCardState = .noTrainer
                return
            }

            let trainer = result.trainer

            // Buscar treino do dia se conectado
            var todayTrainerWorkout: TrainerWorkout?
            if result.relationship.status == .active,
               let fetchWorkoutsUseCase = resolver.resolve(FetchAssignedWorkoutsUseCaseProtocol.self) {
                let workouts = try await fetchWorkoutsUseCase.execute()
                todayTrainerWorkout = workouts.first { workout in
                    guard let scheduledDate = workout.schedule.scheduledDate else { return false }
                    return Calendar.current.isDateInToday(scheduledDate)
                }
                todayWorkoutId = todayTrainerWorkout?.id
            }

            personalTrainerCardState = .hasTrainer(trainer: trainer, todayWorkout: todayTrainerWorkout)

        } catch {
            personalTrainerCardState = .noTrainer
            #if DEBUG
            print("[Home] Personal trainer state load failed: \(error)")
            #endif
        }
    }

    func startObservingTrainerRelationship() {
        trainerObservationTask?.cancel()
        trainerObservationTask = Task {
            guard let useCase = resolver.resolve(GetCurrentTrainerUseCaseProtocol.self) else { return }
            for await _ in useCase.observeRelationship() {
                guard !Task.isCancelled else { break }
                await loadPersonalTrainerState()
            }
        }
    }

    /// Loads user display name and photo from UserDefaults or Firebase Auth.
    /// On app launch, syncs Firebase Auth user data to UserDefaults if not already cached.
    /// Always refreshes from Firebase to ensure fresh data.
    private func loadUserInfo() async {
        // First, try to load from UserDefaults (fast path for immediate display)
        let cachedName = UserDefaults.standard.string(forKey: "socialUserDisplayName")
        let cachedPhotoURLString = UserDefaults.standard.string(forKey: "socialUserPhotoURL")

        // Set cached values immediately for fast UI update
        if let name = cachedName, !name.isEmpty {
            userName = name
            #if DEBUG
            print("[Home] 👤 Loaded cached name: \(name)")
            #endif
        }
        if let urlString = cachedPhotoURLString, let url = URL(string: urlString) {
            userPhotoURL = url
            #if DEBUG
            print("[Home] 🖼️ Loaded cached photo URL: \(urlString)")
            #endif
        }

        // Always try to refresh from Firebase to get latest data (photo might be updated)
        guard let authRepo = resolver.resolve(AuthenticationRepository.self) else {
            #if DEBUG
            print("[Home] ⚠️ AuthenticationRepository not available")
            #endif
            return
        }

        do {
            if let currentUser = try await authRepo.currentUser() {
                // Update local state with fresh data from Firebase
                let newName = currentUser.displayName
                let newPhotoURL = currentUser.photoURL

                // Only update if we got valid data (displayName is never empty from Firebase)
                if !newName.isEmpty && newName != "User" {
                    userName = newName
                    UserDefaults.standard.set(newName, forKey: "socialUserDisplayName")
                } else if userName == nil || userName?.isEmpty == true {
                    // Fallback: use Firebase displayName even if "User"
                    userName = newName
                    UserDefaults.standard.set(newName, forKey: "socialUserDisplayName")
                }

                if let photoURL = newPhotoURL {
                    userPhotoURL = photoURL
                    UserDefaults.standard.set(photoURL.absoluteString, forKey: "socialUserPhotoURL")
                }

                #if DEBUG
                print("[Home] ✅ User session loaded from Firebase:")
                print("[Home]    Name: \(newName)")
                print("[Home]    Photo: \(newPhotoURL?.absoluteString ?? "nil")")
                print("[Home]    GroupId: \(currentUser.currentGroupId ?? "nil")")
                #endif
            } else {
                #if DEBUG
                print("[Home] ℹ️ No authenticated user found in Firebase")
                #endif
            }
        } catch {
            #if DEBUG
            print("[Home] ❌ Failed to fetch current user from Firebase: \(error)")
            #endif
            // Keep using cached values if available
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
    
    /// Generates a workout plan using the provided DailyCheckIn (live inputs from Home).
    /// This is the PRIMARY method for workout generation - uses inputs directly from the UI.
    func generateWorkoutWithCheckIn(_ checkIn: DailyCheckIn) async throws -> WorkoutPlan {
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

        #if DEBUG
        print("[HomeViewModel] 🎯 Generating workout with LIVE checkIn:")
        print("[HomeViewModel]    Focus: \(checkIn.focus.rawValue)")
        print("[HomeViewModel]    Soreness: \(checkIn.sorenessLevel.rawValue)")
        print("[HomeViewModel]    Energy: \(checkIn.energyLevel)/10")
        #endif

        let generator = GenerateWorkoutPlanUseCase(
            blocksRepository: blocksRepo,
            composer: composer
        )
        return try await generator.execute(profile: profile, checkIn: checkIn)
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

