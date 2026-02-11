//
//  WorkoutVariationValidator.swift
//  FitToday
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 1.0)
//

import Foundation

// MARK: - Type Dependencies
// WorkoutPlan is in Domain/Entities/WorkoutModels.swift

/// Validates that generated workouts have sufficient diversity compared to recent workouts.
///
/// This validator ensures that at least 60% of exercises in a newly generated workout
/// are different from exercises in the last 3 workouts, preventing repetitive workout generation.
///
/// - Note: Part of FR-002 (Variação Obrigatória de Treinos) from PRD
struct WorkoutVariationValidator: Sendable {

    /// Validates diversity of a generated workout plan against previous workouts
    ///
    /// Convenience method for validating WorkoutPlan directly (e.g., from local fallback generator)
    ///
    /// - Parameters:
    ///   - generated: The workout plan to validate
    ///   - previousWorkouts: Array of previous workout plans (most recent first)
    ///   - minimumDiversityPercent: Minimum percentage of new exercises required (default: 0.6)
    /// - Returns: true if workout meets diversity threshold, false otherwise
    static func validateDiversity(
        generated: WorkoutPlan,
        previousWorkouts: [WorkoutPlan],
        minimumDiversityPercent: Double = 0.6
    ) -> Bool {
        // Extract exercises from last 3 workouts (excluding the one being validated)
        let previousExercises = Set(
            previousWorkouts.prefix(3)
                .flatMap { $0.exercises }
                .map { $0.exercise.name.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        )

        // Extract exercises from generated workout
        let generatedExercises = generated.exercises.map {
            $0.exercise.name.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        guard !generatedExercises.isEmpty else {
            // Empty workout is invalid
            return false
        }

        // Count new exercises (not in previous workouts)
        let newExercises = generatedExercises.filter { !previousExercises.contains($0) }
        let diversityRatio = Double(newExercises.count) / Double(generatedExercises.count)

        return diversityRatio >= minimumDiversityPercent
    }

    /// Calculates the diversity percentage between two workout plans
    ///
    /// - Parameters:
    ///   - generated: The generated workout plan
    ///   - previousWorkouts: Array of previous workout plans
    /// - Returns: Diversity ratio as a value between 0.0 and 1.0
    static func calculateDiversityRatio(
        generated: WorkoutPlan,
        previousWorkouts: [WorkoutPlan]
    ) -> Double {
        let previousExercises = Set(
            previousWorkouts.prefix(3)
                .flatMap { $0.exercises }
                .map { $0.exercise.name.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        )

        let generatedExercises = generated.exercises.map {
            $0.exercise.name.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        guard !generatedExercises.isEmpty else { return 0.0 }

        let newExercises = generatedExercises.filter { !previousExercises.contains($0) }
        return Double(newExercises.count) / Double(generatedExercises.count)
    }
}
