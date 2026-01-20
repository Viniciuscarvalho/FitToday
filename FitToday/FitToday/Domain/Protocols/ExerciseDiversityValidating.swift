//
//  ExerciseDiversityValidating.swift
//  FitToday
//
//  Created by Claude on 20/01/26.
//

import Foundation

/// Protocol for validating exercise diversity against previous workouts.
/// Ensures at least 80% of exercises are unique compared to recent workouts.
protocol ExerciseDiversityValidating: Sendable {
    /// Calculates the diversity score for a new set of exercises against previous workouts.
    /// - Parameters:
    ///   - newExercises: Array of exercise names from the new workout
    ///   - previousExercises: Array of exercise name arrays from previous workouts (typically last 3)
    /// - Returns: DiversityResult with score and validation status
    func calculateDiversityScore(
        newExercises: [String],
        previousExercises: [[String]]
    ) -> DiversityResult
}
