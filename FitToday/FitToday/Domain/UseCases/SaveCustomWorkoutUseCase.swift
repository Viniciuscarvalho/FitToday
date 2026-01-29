//
//  SaveCustomWorkoutUseCase.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation

/// Use case for saving custom workout templates.
/// Validates the template before persisting.
struct SaveCustomWorkoutUseCase: Sendable {
    private let repository: CustomWorkoutRepository

    init(repository: CustomWorkoutRepository) {
        self.repository = repository
    }

    /// Saves or updates a custom workout template.
    /// - Parameter template: The template to save
    /// - Throws: CustomWorkoutError if validation fails
    func execute(template: CustomWorkoutTemplate) async throws {
        // Validate name is not empty
        guard !template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CustomWorkoutError.emptyName
        }

        // Validate at least one exercise
        guard !template.exercises.isEmpty else {
            throw CustomWorkoutError.noExercises
        }

        // Validate each exercise has at least one set
        for exercise in template.exercises {
            guard !exercise.sets.isEmpty else {
                throw CustomWorkoutError.invalidTemplate
            }
        }

        try await repository.saveTemplate(template)

        #if DEBUG
        print("[SaveCustomWorkoutUseCase] ✅ Saved template '\(template.name)' with \(template.exercises.count) exercises")
        #endif
    }

    /// Creates a new template from provided data
    /// - Parameters:
    ///   - name: The workout name
    ///   - exercises: Array of exercises with configured sets
    ///   - category: Optional category tag
    /// - Returns: The saved template
    func createAndSave(
        name: String,
        exercises: [CustomExerciseEntry],
        category: String? = nil
    ) async throws -> CustomWorkoutTemplate {
        let template = CustomWorkoutTemplate(
            name: name,
            exercises: exercises,
            category: category
        )

        try await execute(template: template)
        return template
    }
}
