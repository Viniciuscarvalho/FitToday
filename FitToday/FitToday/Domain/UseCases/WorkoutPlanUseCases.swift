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
        let entry = WorkoutHistoryEntry(
            planId: session.plan.id,
            title: session.plan.title,
            focus: session.plan.focus,
            status: status
        )
        try await historyRepository.saveEntry(entry)
    }
}

