//
//  FeedbackAnalyzer.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

/// Analyzes user workout feedback to determine intensity adjustments for future workouts.
/// Implements the adaptive training system based on user-reported difficulty.
final class FeedbackAnalyzer: FeedbackAnalyzing, @unchecked Sendable {

    /// Minimum number of matching ratings to trigger an adjustment (PRD: 3+)
    private let minimumRatingsThreshold = 3

    /// Maximum age of ratings to consider (14 days)
    private let maxRatingAgeDays = 14

    init() {}

    func analyzeRecentFeedback(
        ratings: [WorkoutRating],
        currentIntensity: WorkoutIntensity
    ) -> IntensityAdjustment {
        // Empty or insufficient ratings = no change
        guard !ratings.isEmpty else {
            return .noChange
        }

        // Count occurrences of each rating type
        let tooEasyCount = ratings.filter { $0 == .tooEasy }.count
        let tooHardCount = ratings.filter { $0 == .tooHard }.count

        // PRD Rule: 3+ "too_easy" ratings = increase intensity
        if tooEasyCount >= minimumRatingsThreshold {
            return .increaseIntensity
        }

        // PRD Rule: 3+ "too_hard" ratings = decrease intensity
        if tooHardCount >= minimumRatingsThreshold {
            return .decreaseIntensity
        }

        // Mixed or "adequate" majority = no change
        return .noChange
    }

    /// Analyzes ratings with date filtering (only considers recent ratings)
    /// - Parameters:
    ///   - entries: Workout history entries with ratings
    ///   - currentIntensity: Current workout intensity
    ///   - referenceDate: Date to use as reference for filtering (defaults to now)
    /// - Returns: IntensityAdjustment with recommended changes
    func analyzeRecentFeedback(
        entries: [WorkoutHistoryEntry],
        currentIntensity: WorkoutIntensity,
        referenceDate: Date = Date()
    ) -> IntensityAdjustment {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxRatingAgeDays, to: referenceDate) ?? referenceDate

        // Filter to recent entries with ratings
        let recentRatings = entries
            .filter { $0.date >= cutoffDate && $0.userRating != nil }
            .sorted { $0.date > $1.date }  // Most recent first
            .prefix(5)  // Last 5 ratings
            .compactMap { $0.userRating }

        return analyzeRecentFeedback(
            ratings: Array(recentRatings),
            currentIntensity: currentIntensity
        )
    }
}
