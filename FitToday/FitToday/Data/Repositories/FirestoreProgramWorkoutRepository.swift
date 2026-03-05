//
//  FirestoreProgramWorkoutRepository.swift
//  FitToday
//
//  Loads catalog exercises for program workouts via ExerciseServiceProtocol.
//  Primary implementation for loading program workout exercises.
//

import Foundation

/// Repository that loads exercises from the Firestore catalog for program workouts.
actor FirestoreProgramWorkoutRepository: ProgramWorkoutRepository {
    private let exerciseService: ExerciseServiceProtocol
    private let storage: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Cache: [categoryName: [CatalogExercise]]
    private var exerciseCache: [String: [CatalogExercise]] = [:]
    private var exerciseByIdCache: [String: CatalogExercise] = [:]

    init(exerciseService: ExerciseServiceProtocol, storage: UserDefaults = .standard) {
        self.exerciseService = exerciseService
        self.storage = storage
    }

    // MARK: - ProgramWorkoutRepository

    func loadWorkoutExercises(templateId: String, exerciseCount: Int = 8) async throws -> [CatalogExercise] {
        guard let templateType = WorkoutTemplateType.from(templateId: templateId) else {
            return try await loadExercisesForCategories(["chest", "back", "legs", "core"], count: exerciseCount)
        }

        let categoryNames = templateType.categoryNames
        guard !categoryNames.isEmpty else {
            throw ProgramWorkoutError.noCategories
        }

        return try await loadExercisesForCategories(categoryNames, count: exerciseCount)
    }

    func saveCustomization(programId: String, workoutId: String, exerciseIds: [String], order: [Int]) async throws {
        let customization = WorkoutCustomization(
            programId: programId,
            workoutId: workoutId,
            exerciseIds: exerciseIds,
            order: order,
            updatedAt: Date()
        )

        let data = try encoder.encode(customization)
        storage.set(data, forKey: customization.storageKey)
    }

    func loadCustomization(programId: String, workoutId: String) async throws -> WorkoutCustomization? {
        let key = "workout_customization_\(programId)_\(workoutId)"
        guard let data = storage.data(forKey: key) else { return nil }

        do {
            return try decoder.decode(WorkoutCustomization.self, from: data)
        } catch {
            return nil
        }
    }

    func fetchExercisesByIds(_ ids: [String]) async throws -> [CatalogExercise] {
        var exercises: [CatalogExercise] = []

        for id in ids {
            if let cached = exerciseByIdCache[id] {
                exercises.append(cached)
            } else if let exercise = try await exerciseService.fetchExercise(id: id) {
                exerciseByIdCache[id] = exercise
                exercises.append(exercise)
            }
        }

        return exercises
    }

    // MARK: - Private Helpers

    private func loadExercisesForCategories(_ categoryNames: [String], count: Int) async throws -> [CatalogExercise] {
        var allExercises: [CatalogExercise] = []
        let exercisesPerCategory = max(1, count / categoryNames.count)

        for categoryName in categoryNames {
            let exercises = try await loadExercisesForCategory(categoryName)
            let selected = exercises.shuffled().prefix(exercisesPerCategory + 2)
            allExercises.append(contentsOf: selected)
        }

        let result = Array(allExercises.shuffled().prefix(count))

        if result.isEmpty {
            throw ProgramWorkoutError.exercisesNotFound
        }

        return result
    }

    private func loadExercisesForCategory(_ categoryName: String) async throws -> [CatalogExercise] {
        if let cached = exerciseCache[categoryName], !cached.isEmpty {
            return cached
        }

        do {
            let exercises = try await exerciseService.fetchExercises(
                language: .portuguese,
                category: categoryName,
                equipment: nil,
                limit: 50
            )

            exerciseCache[categoryName] = exercises
            for exercise in exercises {
                exerciseByIdCache[exercise.id] = exercise
            }

            return exercises
        } catch {
            throw ProgramWorkoutError.serviceError(error)
        }
    }
}
