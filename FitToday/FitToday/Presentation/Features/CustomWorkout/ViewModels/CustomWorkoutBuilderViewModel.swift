//
//  CustomWorkoutBuilderViewModel.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation
import SwiftUI

/// ViewModel for building and editing custom workout templates
@Observable
@MainActor
final class CustomWorkoutBuilderViewModel {
    // MARK: - State

    var name: String = ""
    var exercises: [CustomExerciseEntry] = []
    var category: String?

    var isLoading = false
    var error: Error?
    var showExercisePicker = false
    var showSaveConfirmation = false

    // MARK: - Dependencies

    private let saveUseCase: SaveCustomWorkoutUseCase
    private let existingTemplate: CustomWorkoutTemplate?
    let exerciseService: (any ExerciseServiceProtocol)?

    // MARK: - Computed Properties

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !exercises.isEmpty
    }

    var estimatedDuration: Int {
        exercises.reduce(0) { $0 + $1.estimatedDurationMinutes }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var isEditing: Bool {
        existingTemplate != nil
    }

    // MARK: - Initialization

    init(
        saveUseCase: SaveCustomWorkoutUseCase,
        existingTemplate: CustomWorkoutTemplate? = nil,
        existingTemplateId: UUID? = nil,
        exerciseService: (any ExerciseServiceProtocol)? = nil
    ) {
        self.saveUseCase = saveUseCase
        self.existingTemplate = existingTemplate
        self.exerciseService = exerciseService

        // Populate from existing template if editing
        if let template = existingTemplate {
            self.name = template.name
            self.exercises = template.exercises
            self.category = template.category
        }
        // Note: existingTemplateId would be used to load template async if needed
    }

    // MARK: - Actions

    func addExercise(from exercise: WgerExercise, imageURL: String? = nil) {
        let entry = CustomExerciseEntry(from: exercise, orderIndex: exercises.count, imageURL: imageURL)
        exercises.append(entry)
    }

    func addExercise(_ entry: CustomExerciseEntry) {
        var newEntry = entry
        newEntry.orderIndex = exercises.count
        exercises.append(newEntry)
    }

    func removeExercise(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        exercises.remove(at: index)
        reorderExercises()
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        reorderExercises()
    }

    func addSet(to exerciseIndex: Int) {
        guard exercises.indices.contains(exerciseIndex) else { return }

        // Copy last set's target values if available
        let newSet: WorkoutSet
        if let lastSet = exercises[exerciseIndex].sets.last {
            newSet = WorkoutSet(
                targetReps: lastSet.targetReps,
                targetWeight: lastSet.targetWeight,
                targetDuration: lastSet.targetDuration
            )
        } else {
            newSet = WorkoutSet()
        }

        exercises[exerciseIndex].sets.append(newSet)
    }

    func removeSet(from exerciseIndex: Int, at setIndex: Int) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        guard exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }

        // Don't allow removing the last set
        guard exercises[exerciseIndex].sets.count > 1 else { return }

        exercises[exerciseIndex].sets.remove(at: setIndex)
    }

    func updateSet(exerciseIndex: Int, setIndex: Int, reps: Int?, weight: Double?) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        guard exercises[exerciseIndex].sets.indices.contains(setIndex) else { return }

        exercises[exerciseIndex].sets[setIndex].targetReps = reps
        exercises[exerciseIndex].sets[setIndex].targetWeight = weight
    }

    func updateNotes(for exerciseIndex: Int, notes: String?) {
        guard exercises.indices.contains(exerciseIndex) else { return }
        exercises[exerciseIndex].notes = notes?.isEmpty == true ? nil : notes
    }

    func save() async throws -> CustomWorkoutTemplate {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let template = CustomWorkoutTemplate(
            id: existingTemplate?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            exercises: exercises,
            createdAt: existingTemplate?.createdAt ?? Date(),
            lastUsedAt: existingTemplate?.lastUsedAt,
            category: category
        )

        do {
            try await saveUseCase.execute(template: template)
            showSaveConfirmation = true
            return template
        } catch {
            self.error = error
            throw error
        }
    }

    func reset() {
        name = ""
        exercises = []
        category = nil
        error = nil
    }

    // MARK: - Private

    private func reorderExercises() {
        for i in exercises.indices {
            exercises[i].orderIndex = i
        }
    }
}
