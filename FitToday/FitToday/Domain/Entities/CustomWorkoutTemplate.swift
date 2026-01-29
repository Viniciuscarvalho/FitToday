//
//  CustomWorkoutTemplate.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation

/// Represents a user-created workout template that can be saved and reused.
/// Users can create custom workouts by selecting exercises and configuring sets.
struct CustomWorkoutTemplate: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var name: String
    var exercises: [CustomExerciseEntry]
    var createdAt: Date
    var lastUsedAt: Date?

    /// Optional description or notes for the workout
    var workoutDescription: String?

    /// Optional category/tag (e.g., "Push", "Pull", "Legs")
    var category: String?

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        exercises: [CustomExerciseEntry] = [],
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        workoutDescription: String? = nil,
        category: String? = nil
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.workoutDescription = workoutDescription
        self.category = category
    }

    // MARK: - Computed Properties

    /// Total number of exercises in the workout
    var exerciseCount: Int {
        exercises.count
    }

    /// Total number of sets across all exercises
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    /// Estimated duration in minutes (assumes ~2 min per set)
    var estimatedDurationMinutes: Int {
        exercises.reduce(0) { $0 + $1.estimatedDurationMinutes }
    }

    /// Whether this template is valid for saving
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !exercises.isEmpty
    }

    /// Summary string for display (e.g., "5 exercises • ~30 min")
    var summaryString: String {
        let exerciseText = exerciseCount == 1 ? "1 exercise" : "\(exerciseCount) exercises"
        return "\(exerciseText) • ~\(estimatedDurationMinutes) min"
    }

    /// Unique body parts targeted in this workout
    var targetedBodyParts: [String] {
        let parts = exercises.compactMap { $0.bodyPart }
        return Array(Set(parts)).sorted()
    }

    // MARK: - Methods

    /// Creates a working copy for a new session (resets all completion states)
    func startNewSession() -> CustomWorkoutTemplate {
        var copy = self
        copy.exercises = exercises.enumerated().map { index, exercise in
            exercise.copyForNewSession(orderIndex: index)
        }
        return copy
    }

    /// Updates the lastUsedAt timestamp
    mutating func markAsUsed() {
        lastUsedAt = Date()
    }

    /// Adds an exercise to the template
    mutating func addExercise(_ exercise: CustomExerciseEntry) {
        var newExercise = exercise
        newExercise.orderIndex = exercises.count
        exercises.append(newExercise)
    }

    /// Removes an exercise at the given index and reorders remaining
    mutating func removeExercise(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        exercises.remove(at: index)
        reorderExercises()
    }

    /// Moves an exercise from one position to another
    mutating func moveExercise(from source: Int, to destination: Int) {
        guard exercises.indices.contains(source) else { return }
        let exercise = exercises.remove(at: source)
        let insertIndex = min(destination, exercises.count)
        exercises.insert(exercise, at: insertIndex)
        reorderExercises()
    }

    /// Updates orderIndex for all exercises to match array position
    private mutating func reorderExercises() {
        for i in exercises.indices {
            exercises[i].orderIndex = i
        }
    }
}

// MARK: - Validation Errors

enum CustomWorkoutError: LocalizedError {
    case emptyName
    case noExercises
    case invalidTemplate

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Please enter a name for your workout"
        case .noExercises:
            return "Please add at least one exercise"
        case .invalidTemplate:
            return "This workout template is invalid"
        }
    }
}
