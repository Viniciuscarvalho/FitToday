//
//  FetchRecentRatingsUseCase.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

/// Use case for fetching recent workout ratings from history.
/// Retrieves the last N workout entries that have user ratings.
final class FetchRecentRatingsUseCase: @unchecked Sendable {
    private let historyRepository: WorkoutHistoryRepository

    /// Maximum number of recent ratings to fetch
    private let maxRatings = 5

    /// Maximum age of ratings to consider (14 days)
    private let maxAgeDays = 14

    init(historyRepository: WorkoutHistoryRepository) {
        self.historyRepository = historyRepository
    }

    /// Fetches recent workout ratings (last 5 within 14 days)
    /// - Returns: Array of WorkoutRating from recent workouts
    func execute() async throws -> [WorkoutRating] {
        let entries = try await historyRepository.listEntries()

        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxAgeDays, to: Date()) ?? Date()

        // Filter to entries with ratings within the time window
        let recentRatings = entries
            .filter { $0.date >= cutoffDate && $0.userRating != nil }
            .sorted { $0.date > $1.date }  // Most recent first
            .prefix(maxRatings)
            .compactMap { $0.userRating }

        return Array(recentRatings)
    }

    /// Fetches recent workout entries with ratings (for more detailed analysis)
    /// - Returns: Array of WorkoutHistoryEntry that have ratings
    func executeWithEntries() async throws -> [WorkoutHistoryEntry] {
        let entries = try await historyRepository.listEntries()

        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxAgeDays, to: Date()) ?? Date()

        let recentEntries = entries
            .filter { $0.date >= cutoffDate && $0.userRating != nil }
            .sorted { $0.date > $1.date }
            .prefix(maxRatings)

        return Array(recentEntries)
    }
}
