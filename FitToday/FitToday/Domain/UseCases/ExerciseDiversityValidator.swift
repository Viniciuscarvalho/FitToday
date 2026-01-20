//
//  ExerciseDiversityValidator.swift
//  FitToday
//
//  Created by Claude on 20/01/26.
//

import Foundation

/// Default implementation of ExerciseDiversityValidating.
/// Validates that at least 80% of exercises in a new workout are unique
/// compared to the last 3 workouts.
struct ExerciseDiversityValidator: ExerciseDiversityValidating {

    /// Calculates the diversity score for new exercises against previous workouts.
    /// - Parameters:
    ///   - newExercises: Exercise names from the new workout
    ///   - previousExercises: Arrays of exercise names from previous workouts
    /// - Returns: DiversityResult with score, counts, and repeated exercise list
    func calculateDiversityScore(
        newExercises: [String],
        previousExercises: [[String]]
    ) -> DiversityResult {
        // Handle edge cases
        guard !newExercises.isEmpty else {
            return DiversityResult(
                score: 1.0,
                uniqueCount: 0,
                totalCount: 0,
                repeatedExercises: []
            )
        }

        guard !previousExercises.isEmpty else {
            // No history means all exercises are unique
            return DiversityResult(
                score: 1.0,
                uniqueCount: newExercises.count,
                totalCount: newExercises.count,
                repeatedExercises: []
            )
        }

        // Build set of all previous exercise names (case-insensitive)
        let previousExerciseSet = Set(
            previousExercises
                .flatMap { $0 }
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        )

        // Normalize new exercise names for comparison
        let normalizedNewExercises = newExercises.map {
            $0.lowercased().trimmingCharacters(in: .whitespaces)
        }

        // Find repeated exercises
        var repeatedExercises: [String] = []
        var uniqueCount = 0

        for (index, normalizedName) in normalizedNewExercises.enumerated() {
            if previousExerciseSet.contains(normalizedName) ||
               fuzzyMatchExists(name: normalizedName, in: previousExerciseSet) {
                repeatedExercises.append(newExercises[index])
            } else {
                uniqueCount += 1
            }
        }

        let totalCount = newExercises.count
        let score = totalCount > 0 ? Double(uniqueCount) / Double(totalCount) : 1.0

        #if DEBUG
        print("[DiversityValidator] Score: \(String(format: "%.2f", score)) (\(uniqueCount)/\(totalCount) unique)")
        if !repeatedExercises.isEmpty {
            print("[DiversityValidator] Repeated: \(repeatedExercises.joined(separator: ", "))")
        }
        #endif

        return DiversityResult(
            score: score,
            uniqueCount: uniqueCount,
            totalCount: totalCount,
            repeatedExercises: repeatedExercises
        )
    }

    // MARK: - Private Helpers

    /// Checks for fuzzy matches to catch similar exercise names
    /// (e.g., "Bench Press" vs "Barbell Bench Press")
    private func fuzzyMatchExists(name: String, in previousSet: Set<String>) -> Bool {
        // Check for partial matches
        for previous in previousSet {
            // One contains the other
            if name.contains(previous) || previous.contains(name) {
                // Only consider match if the shorter string is at least 4 characters
                // to avoid false positives like "row" matching "throw"
                let shorter = min(name.count, previous.count)
                if shorter >= 4 {
                    return true
                }
            }

            // Check word overlap for multi-word exercise names
            let nameWords = Set(name.components(separatedBy: .whitespaces).filter { $0.count > 2 })
            let previousWords = Set(previous.components(separatedBy: .whitespaces).filter { $0.count > 2 })

            // If at least 2 significant words match, consider it a match
            if nameWords.intersection(previousWords).count >= 2 {
                return true
            }
        }

        return false
    }
}
