//
//  FeedbackAnalyzing.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

/// Protocol for analyzing user workout feedback and determining intensity adjustments.
protocol FeedbackAnalyzing: Sendable {
    /// Analyzes recent workout ratings to determine if intensity adjustments are needed.
    /// - Parameters:
    ///   - ratings: Array of recent workout ratings (ideally last 5)
    ///   - currentIntensity: The current workout intensity level
    /// - Returns: IntensityAdjustment with recommended changes
    func analyzeRecentFeedback(
        ratings: [WorkoutRating],
        currentIntensity: WorkoutIntensity
    ) -> IntensityAdjustment
}
