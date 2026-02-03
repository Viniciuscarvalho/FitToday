//
//  DefaultWgerProgramWorkoutRepository.swift
//  FitToday
//
//  Implementação do repositório que carrega exercícios da API Wger para programas.
//

import Foundation

/// Implementação do repositório de exercícios para programas usando a API Wger.
actor DefaultWgerProgramWorkoutRepository: WgerProgramWorkoutRepository {
    private let wgerService: ExerciseServiceProtocol
    private let storage: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Cache em memória de exercícios por categoria: [categoryId: [WgerExercise]]
    private var exerciseCache: [Int: [WgerExercise]] = [:]

    /// Cache de exercícios individuais por ID
    private var exerciseByIdCache: [Int: WgerExercise] = [:]

    init(wgerService: ExerciseServiceProtocol, storage: UserDefaults = .standard) {
        self.wgerService = wgerService
        self.storage = storage
    }

    // MARK: - WgerProgramWorkoutRepository

    func loadWorkoutExercises(templateId: String, exerciseCount: Int = 8) async throws -> [WgerExercise] {
        guard let templateType = WorkoutTemplateType.from(templateId: templateId) else {
            #if DEBUG
            print("[WgerProgramRepo] ⚠️ Unknown template: \(templateId), using fullbody")
            #endif
            // Fallback para fullbody se não reconhecer o template
            return try await loadExercisesForCategories([11, 12, 9, 10], count: exerciseCount)
        }

        let categoryIds = templateType.wgerCategoryIds
        guard !categoryIds.isEmpty else {
            throw WgerProgramError.noCategories
        }

        #if DEBUG
        print("[WgerProgramRepo] 📋 Loading exercises for \(templateType.rawValue)")
        print("[WgerProgramRepo] 📋 Categories: \(categoryIds)")
        #endif

        return try await loadExercisesForCategories(categoryIds, count: exerciseCount)
    }

    func saveCustomization(programId: String, workoutId: String, exerciseIds: [Int], order: [Int]) async throws {
        let customization = WorkoutCustomization(
            programId: programId,
            workoutId: workoutId,
            exerciseIds: exerciseIds,
            order: order,
            updatedAt: Date()
        )

        let data = try encoder.encode(customization)
        storage.set(data, forKey: customization.storageKey)

        #if DEBUG
        print("[WgerProgramRepo] 💾 Saved customization for \(programId)/\(workoutId)")
        #endif
    }

    func loadCustomization(programId: String, workoutId: String) async throws -> WorkoutCustomization? {
        let key = "workout_customization_\(programId)_\(workoutId)"
        guard let data = storage.data(forKey: key) else {
            return nil
        }

        do {
            let customization = try decoder.decode(WorkoutCustomization.self, from: data)
            #if DEBUG
            print("[WgerProgramRepo] 📖 Loaded customization for \(programId)/\(workoutId)")
            #endif
            return customization
        } catch {
            #if DEBUG
            print("[WgerProgramRepo] ⚠️ Failed to decode customization: \(error)")
            #endif
            return nil
        }
    }

    func fetchExercisesByIds(_ ids: [Int]) async throws -> [WgerExercise] {
        var exercises: [WgerExercise] = []

        for id in ids {
            if let cached = exerciseByIdCache[id] {
                exercises.append(cached)
            } else if let exercise = try await wgerService.fetchExercise(id: id) {
                exerciseByIdCache[id] = exercise
                exercises.append(exercise)
            }
        }

        return exercises
    }

    // MARK: - Private Helpers

    private func loadExercisesForCategories(_ categoryIds: [Int], count: Int) async throws -> [WgerExercise] {
        var allExercises: [WgerExercise] = []

        // Calcular quantos exercícios por categoria para distribuir
        let exercisesPerCategory = max(1, count / categoryIds.count)

        for categoryId in categoryIds {
            let exercises = try await loadExercisesForCategory(categoryId)
            let selected = exercises.shuffled().prefix(exercisesPerCategory + 2)
            allExercises.append(contentsOf: selected)
        }

        // Shuffle final e limitar ao count desejado
        let result = Array(allExercises.shuffled().prefix(count))

        #if DEBUG
        print("[WgerProgramRepo] ✅ Loaded \(result.count) exercises from \(categoryIds.count) categories")
        for exercise in result.prefix(3) {
            print("[WgerProgramRepo]   - \(exercise.name)")
        }
        if result.count > 3 {
            print("[WgerProgramRepo]   ... and \(result.count - 3) more")
        }
        #endif

        if result.isEmpty {
            throw WgerProgramError.exercisesNotFound
        }

        return result
    }

    private func loadExercisesForCategory(_ categoryId: Int) async throws -> [WgerExercise] {
        // Check cache first
        if let cached = exerciseCache[categoryId], !cached.isEmpty {
            #if DEBUG
            print("[WgerProgramRepo] 📦 Cache hit for category \(categoryId): \(cached.count) exercises")
            #endif
            return cached
        }

        #if DEBUG
        print("[WgerProgramRepo] 🌐 Fetching exercises for category \(categoryId)...")
        #endif

        do {
            let exercises = try await wgerService.fetchExercises(
                language: .portuguese,
                category: categoryId,
                equipment: nil,
                limit: 50
            )

            // Cache the results
            exerciseCache[categoryId] = exercises

            // Also cache individual exercises by ID
            for exercise in exercises {
                exerciseByIdCache[exercise.id] = exercise
            }

            #if DEBUG
            print("[WgerProgramRepo] ✅ Fetched \(exercises.count) exercises for category \(categoryId)")
            #endif

            return exercises
        } catch {
            #if DEBUG
            print("[WgerProgramRepo] ❌ Error fetching category \(categoryId): \(error)")
            #endif
            throw WgerProgramError.apiError(error)
        }
    }

    // MARK: - Cache Management

    /// Limpa o cache de exercícios.
    func clearCache() {
        exerciseCache.removeAll()
        exerciseByIdCache.removeAll()
        #if DEBUG
        print("[WgerProgramRepo] 🗑️ Cache cleared")
        #endif
    }
}
