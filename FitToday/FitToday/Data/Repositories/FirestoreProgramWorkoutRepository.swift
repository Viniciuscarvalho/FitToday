//
//  FirestoreProgramWorkoutRepository.swift
//  FitToday
//
//  Loads catalog exercises for program workouts via ExerciseServiceProtocol.
//  Replaces DefaultWgerProgramWorkoutRepository.
//

import Foundation

/// Repository that loads exercises from the Firestore catalog for program workouts.
actor FirestoreProgramWorkoutRepository: ProgramWorkoutRepository {
    private let exerciseService: ExerciseServiceProtocol
    private let storage: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Cache: [categoryId: [CatalogExercise]]
    private var exerciseCache: [Int: [CatalogExercise]] = [:]
    private var exerciseByIdCache: [String: CatalogExercise] = [:]

    init(exerciseService: ExerciseServiceProtocol, storage: UserDefaults = .standard) {
        self.exerciseService = exerciseService
        self.storage = storage
    }

    // MARK: - ProgramWorkoutRepository

    func loadWorkoutExercises(templateId: String, exerciseCount: Int = 8) async throws -> [CatalogExercise] {
        guard let templateType = WorkoutTemplateType.from(templateId: templateId) else {
            return try await loadExercisesForCategories([11, 12, 9, 10], count: exerciseCount)
        }

        let categoryIds = templateType.wgerCategoryIds
        guard !categoryIds.isEmpty else {
            throw ProgramWorkoutError.noCategories
        }

        return try await loadExercisesForCategories(categoryIds, count: exerciseCount)
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

    private func loadExercisesForCategories(_ categoryIds: [Int], count: Int) async throws -> [CatalogExercise] {
        var allExercises: [CatalogExercise] = []
        let exercisesPerCategory = max(1, count / categoryIds.count)

        for categoryId in categoryIds {
            let exercises = try await loadExercisesForCategory(categoryId)
            let selected = exercises.shuffled().prefix(exercisesPerCategory + 2)
            allExercises.append(contentsOf: selected)
        }

        let result = Array(allExercises.shuffled().prefix(count))

        if result.isEmpty {
            throw ProgramWorkoutError.exercisesNotFound
        }

        return result
    }

    private func loadExercisesForCategory(_ categoryId: Int) async throws -> [CatalogExercise] {
        if let cached = exerciseCache[categoryId], !cached.isEmpty {
            return cached
        }

        do {
            let exercises = try await exerciseService.fetchExercises(
                language: .portuguese,
                category: categoryId,
                equipment: nil,
                limit: 50
            )

            exerciseCache[categoryId] = exercises
            for exercise in exercises {
                exerciseByIdCache[exercise.id] = exercise
            }

            return exercises
        } catch {
            throw ProgramWorkoutError.serviceError(error)
        }
    }
}
