//
//  CreateWorkoutViewModel.swift
//  FitToday
//
//  ViewModel for creating custom workout templates.
//

import Foundation
import Observation
import SwiftUI

// MARK: - Workout Icon

enum WorkoutIcon: String, CaseIterable, Codable {
    case dumbbell
    case figure
    case heart
    case bolt
    case flame
    case timer
    case trophy
    case star
    case moon
    case sun
    case leaf
    case mountain

    var systemName: String {
        switch self {
        case .dumbbell: return "dumbbell.fill"
        case .figure: return "figure.strengthtraining.traditional"
        case .heart: return "heart.fill"
        case .bolt: return "bolt.fill"
        case .flame: return "flame.fill"
        case .timer: return "timer"
        case .trophy: return "trophy.fill"
        case .star: return "star.fill"
        case .moon: return "moon.fill"
        case .sun: return "sun.max.fill"
        case .leaf: return "leaf.fill"
        case .mountain: return "mountain.2.fill"
        }
    }
}

// MARK: - Workout Color

enum WorkoutColor: String, CaseIterable, Codable {
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case teal

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        }
    }
}

/// ViewModel for creating and editing custom workout templates.
@Observable
@MainActor
final class CreateWorkoutViewModel {
    // MARK: - Properties

    var workoutName: String = ""
    var selectedCategory: String?
    var selectedIcon: WorkoutIcon = .dumbbell
    var selectedColor: WorkoutColor = .blue
    var exercises: [CustomExerciseEntry] = []
    var notes: String = ""

    var isSaving = false
    var errorMessage: String?

    // MARK: - Static Data

    static let categories = [
        "Push",
        "Pull",
        "Legs",
        "Upper",
        "Lower",
        "Full Body",
        "Core",
        "Cardio"
    ]

    // MARK: - Computed Properties

    var canSave: Bool {
        !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !exercises.isEmpty
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var estimatedDuration: Int {
        exercises.reduce(0) { $0 + $1.estimatedDurationMinutes }
    }

    // MARK: - Actions

    func addExercise(_ exercise: CustomExerciseEntry) {
        var newExercise = exercise
        newExercise.orderIndex = exercises.count
        exercises.append(newExercise)
    }

    func removeExercise(_ exercise: CustomExerciseEntry) {
        exercises.removeAll { $0.id == exercise.id }
        reorderExercises()
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        reorderExercises()
    }

    func saveWorkout() async {
        guard canSave else { return }

        isSaving = true
        errorMessage = nil

        do {
            let template = CustomWorkoutTemplate(
                name: workoutName.trimmingCharacters(in: .whitespacesAndNewlines),
                exercises: exercises,
                workoutDescription: notes.isEmpty ? nil : notes,
                category: selectedCategory
            )

            // TODO: Save to repository
            #if DEBUG
            print("[CreateWorkout] Saving template: \(template.name) with \(template.exerciseCount) exercises")
            #endif

            try await Task.sleep(for: .milliseconds(500))

            isSaving = false
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        workoutName = ""
        selectedCategory = nil
        exercises = []
        notes = ""
        errorMessage = nil
    }

    // MARK: - Private

    private func reorderExercises() {
        for i in exercises.indices {
            exercises[i].orderIndex = i
        }
    }
}
