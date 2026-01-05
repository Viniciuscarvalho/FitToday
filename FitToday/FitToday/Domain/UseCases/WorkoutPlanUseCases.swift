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
        let blocks = try await blocksRepository.loadBlocks()
        return try await composer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)
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

    init(historyRepository: WorkoutHistoryRepository) {
        self.historyRepository = historyRepository
    }

    func execute(session: WorkoutSession, status: WorkoutStatus) async throws {
        // Apenas salva no histórico se o treino foi concluído
        // Treinos pulados não são salvos no histórico
        guard status == .completed else {
            return
        }
        
        let entry = WorkoutHistoryEntry(
            planId: session.plan.id,
            title: session.plan.title,
            focus: session.plan.focus,
            status: status
        )
        try await historyRepository.saveEntry(entry)
    }
}

