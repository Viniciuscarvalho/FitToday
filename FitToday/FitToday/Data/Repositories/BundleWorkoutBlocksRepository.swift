//
//  BundleWorkoutBlocksRepository.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

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
}

