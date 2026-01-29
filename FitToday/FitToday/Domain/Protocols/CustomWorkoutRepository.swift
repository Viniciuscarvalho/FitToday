//
//  CustomWorkoutRepository.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation

/// Repository protocol for managing custom workout templates.
/// Provides CRUD operations and session completion tracking.
protocol CustomWorkoutRepository: Sendable {
    /// Fetches all saved workout templates, ordered by lastUsedAt descending
    func listTemplates() async throws -> [CustomWorkoutTemplate]

    /// Fetches a single template by ID
    /// - Parameter id: The template's unique identifier
    /// - Returns: The template if found, nil otherwise
    func getTemplate(id: UUID) async throws -> CustomWorkoutTemplate?

    /// Saves or updates a template
    /// - Parameter template: The template to save
    func saveTemplate(_ template: CustomWorkoutTemplate) async throws

    /// Deletes a template by ID
    /// - Parameter id: The template's unique identifier
    func deleteTemplate(id: UUID) async throws

    /// Records a completed workout session
    /// - Parameters:
    ///   - templateId: The template that was used
    ///   - actualExercises: The exercises with actual performed values
    ///   - duration: Total workout duration in minutes
    ///   - completedAt: When the workout was completed
    func recordCompletion(
        templateId: UUID,
        actualExercises: [CustomExerciseEntry],
        duration: Int,
        completedAt: Date
    ) async throws

    /// Fetches workout history for a specific template
    /// - Parameter templateId: The template to get history for
    /// - Returns: Array of completion records
    func getCompletionHistory(templateId: UUID) async throws -> [CustomWorkoutCompletion]

    /// Updates the lastUsedAt timestamp for a template
    /// - Parameter id: The template's unique identifier
    func updateLastUsed(id: UUID) async throws
}

// MARK: - Completion Record

/// Represents a single completed workout session from a template
struct CustomWorkoutCompletion: Identifiable, Codable, Sendable {
    let id: UUID
    let templateId: UUID
    let completedAt: Date
    let durationMinutes: Int
    let exercises: [CustomExerciseEntry]

    init(
        id: UUID = UUID(),
        templateId: UUID,
        completedAt: Date,
        durationMinutes: Int,
        exercises: [CustomExerciseEntry]
    ) {
        self.id = id
        self.templateId = templateId
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
        self.exercises = exercises
    }

    /// Total sets completed in this session
    var totalSetsCompleted: Int {
        exercises.reduce(0) { $0 + $1.completedSets }
    }
}
