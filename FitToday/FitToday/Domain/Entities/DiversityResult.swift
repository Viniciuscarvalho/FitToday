//
//  DiversityResult.swift
//  FitToday
//
//  Created by Claude on 20/01/26.
//

import Foundation

/// Result of exercise diversity calculation.
/// Used to determine if a workout has enough unique exercises compared to recent history.
struct DiversityResult: Sendable, Equatable {
    /// Diversity score from 0.0 (all repeated) to 1.0 (all unique)
    let score: Double

    /// Number of unique exercises (not found in previous workouts)
    let uniqueCount: Int

    /// Total number of exercises in the new workout
    let totalCount: Int

    /// List of exercise names that were repeated from previous workouts
    let repeatedExercises: [String]

    /// Minimum required diversity score (80%)
    static let requiredScore: Double = 0.80

    /// Whether the diversity score meets the required threshold
    var isValid: Bool {
        score >= Self.requiredScore
    }

    /// Human-readable description of the diversity result
    var description: String {
        let percentage = Int(score * 100)
        if isValid {
            return "Diversidade adequada: \(percentage)% (\(uniqueCount)/\(totalCount) exercícios únicos)"
        } else {
            return "Diversidade insuficiente: \(percentage)% (mínimo: \(Int(Self.requiredScore * 100))%)"
        }
    }
}
