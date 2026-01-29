//
//  BundleWorkoutBlocksRepository.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//  Simplified on 29/01/26 - Removed ExerciseDB dependencies
//

import Foundation

/// Repository for loading workout blocks from bundle.
/// Note: Exercise enrichment is now handled by Wger API service separately.
actor BundleWorkoutBlocksRepository: WorkoutBlocksRepository {
    private let loader: WorkoutBlocksLoader
    private var cachedBlocks: [WorkoutBlock]?

    init(loader: WorkoutBlocksLoader = WorkoutBlocksLoader()) {
        self.loader = loader
    }

    func loadBlocks() async throws -> [WorkoutBlock] {
        if let cached = cachedBlocks {
            return cached
        }
        let blocks = try loader.loadBlocks()
        cachedBlocks = blocks
        return blocks
    }

    /// Carrega blocos específicos para um objetivo.
    /// Note: Dynamic block creation was removed with ExerciseDB.
    func loadBlocks(
        for goal: FitnessGoal,
        level: TrainingLevel,
        structure: TrainingStructure
    ) async throws -> [WorkoutBlock] {
        // Simply return all blocks - filtering can be done by caller
        return try await loadBlocks()
    }

    /// Limpa cache (útil para forçar reload)
    func clearCache() {
        cachedBlocks = nil
    }
}
