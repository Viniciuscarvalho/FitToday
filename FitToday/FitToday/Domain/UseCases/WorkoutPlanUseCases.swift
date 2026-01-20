//
//  WorkoutPlanUseCases.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

struct GenerateWorkoutPlanUseCase {
    private let blocksRepository: WorkoutBlocksRepository
    private let composer: WorkoutPlanComposing

    init(
        blocksRepository: WorkoutBlocksRepository,
        composer: WorkoutPlanComposing = LocalWorkoutPlanComposer()
    ) {
        self.blocksRepository = blocksRepository
        self.composer = composer
    }

    func execute(profile: UserProfile, checkIn: DailyCheckIn) async throws -> WorkoutPlan {
        #if DEBUG
        print("[GenerateWorkoutPlan] Carregando blocos...")
        #endif
        
        let blocks = try await blocksRepository.loadBlocks()
        
        #if DEBUG
        print("[GenerateWorkoutPlan] ✅ Blocos carregados: \(blocks.count)")
        print("[GenerateWorkoutPlan] Chamando compositor...")
        #endif
        
        let plan = try await composer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
        
        #if DEBUG
        print("[GenerateWorkoutPlan] ✅ Plano gerado: \(plan.id)")
        #endif
        
        return plan
    }
    
    /// Gera múltiplos planos alternativos para o mesmo checkIn
    /// Útil para oferecer opções quando o usuário pula um treino
    func generateAlternativePlans(
        count: Int = 3,
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> [WorkoutPlan] {
        let blocks = try await blocksRepository.loadBlocks()
        var plans: [WorkoutPlan] = []
        
        // Gera planos variando ligeiramente os parâmetros
        // Cada plano será diferente devido à aleatoriedade interna do composer
        for i in 0..<count {
            let plan = try await composer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
            plans.append(plan)
            
            // Adiciona pequeno delay para garantir variação
            if i < count - 1 {
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }
        }
        
        return plans
    }
}

struct StartWorkoutSessionUseCase {
    func execute(plan: WorkoutPlan) -> WorkoutSession {
        WorkoutSession(plan: plan)
    }
}

struct CompleteWorkoutSessionUseCase {
    private let historyRepository: WorkoutHistoryRepository
    private let healthKitSyncUseCase: SyncWorkoutWithHealthKitUseCase?
    private let updateStatsUseCase: UpdateUserStatsUseCase?
    private let isHealthKitSyncEnabled: () -> Bool

    init(
        historyRepository: WorkoutHistoryRepository,
        healthKitSyncUseCase: SyncWorkoutWithHealthKitUseCase? = nil,
        updateStatsUseCase: UpdateUserStatsUseCase? = nil,
        isHealthKitSyncEnabled: @escaping () -> Bool = { UserDefaults.standard.bool(forKey: "healthKitSyncEnabled") }
    ) {
        self.historyRepository = historyRepository
        self.healthKitSyncUseCase = healthKitSyncUseCase
        self.updateStatsUseCase = updateStatsUseCase
        self.isHealthKitSyncEnabled = isHealthKitSyncEnabled
    }

    func execute(session: WorkoutSession, status: WorkoutStatus) async throws {
        // Apenas salva no histórico se o treino foi concluído
        // Treinos pulados não são salvos no histórico
        guard status == .completed else {
            return
        }

        let completedAt = Date()
        let entry = WorkoutHistoryEntry(
            planId: session.plan.id,
            title: session.plan.title,
            focus: session.plan.focus,
            status: status,
            workoutPlan: session.plan // ← Salvar o plano completo para histórico de variação
        )
        try await historyRepository.saveEntry(entry)

        // Update user stats in background (streak, weekly/monthly totals)
        if let statsUseCase = updateStatsUseCase {
            Task.detached {
                do {
                    try await statsUseCase.execute()
                } catch {
                    #if DEBUG
                    print("[WorkoutComplete] Failed to update stats: \(error)")
                    #endif
                }
            }
        }

        // Sync with HealthKit in background (don't block completion)
        if isHealthKitSyncEnabled(), let syncUseCase = healthKitSyncUseCase {
            Task.detached {
                let result = await syncUseCase.execute(
                    entry: entry,
                    plan: session.plan,
                    completedAt: completedAt
                )

                #if DEBUG
                switch result.status {
                case .success:
                    print("[WorkoutComplete] HealthKit sync succeeded: \(result.caloriesBurned ?? 0) kcal")
                case .partialSuccess(let reason):
                    print("[WorkoutComplete] HealthKit partial sync: \(reason)")
                case .skipped(let reason):
                    print("[WorkoutComplete] HealthKit sync skipped: \(reason)")
                case .failed(let reason):
                    print("[WorkoutComplete] HealthKit sync failed: \(reason)")
                }
                #endif
            }
        }
    }
}

