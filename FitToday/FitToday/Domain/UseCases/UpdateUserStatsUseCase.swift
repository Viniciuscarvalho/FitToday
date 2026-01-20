//
//  UpdateUserStatsUseCase.swift
//  FitToday
//
//  Created by Claude on 20/01/26.
//

import Foundation

/// Use case for updating user statistics after workout completion.
struct UpdateUserStatsUseCase: Sendable {
    private let historyRepository: WorkoutHistoryRepository
    private let statsRepository: UserStatsRepository
    private let calculator: UserStatsCalculating

    init(
        historyRepository: WorkoutHistoryRepository,
        statsRepository: UserStatsRepository,
        calculator: UserStatsCalculating = UserStatsCalculator()
    ) {
        self.historyRepository = historyRepository
        self.statsRepository = statsRepository
        self.calculator = calculator
    }

    /// Updates user statistics based on workout history.
    /// - Returns: The updated UserStats.
    @discardableResult
    func execute() async throws -> UserStats {
        // Fetch workout history (limit to recent entries for performance)
        let history = try await historyRepository.listEntries()

        // Get current stats (for longest streak tracking)
        let currentStats = try await statsRepository.getCurrentStats()

        // Calculate new stats
        let newStats = calculator.computeStats(from: history, currentStats: currentStats)

        // Persist updated stats
        try await statsRepository.saveStats(newStats)

        #if DEBUG
        print("[UserStats] Updated: streak=\(newStats.currentStreak), week=\(newStats.weekWorkoutsCount), month=\(newStats.monthWorkoutsCount)")
        #endif

        return newStats
    }
}
