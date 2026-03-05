//
//  ProgramWorkoutRepository.swift
//  FitToday
//
//  Protocol for loading exercises for program workouts from the catalog.
//

import Foundation

/// Repository for loading catalog exercises for program workouts.
protocol ProgramWorkoutRepository: Sendable {
    /// Loads exercises for a specific workout template.
    func loadWorkoutExercises(templateId: String, exerciseCount: Int) async throws -> [CatalogExercise]

    /// Saves user customization for a workout.
    func saveCustomization(programId: String, workoutId: String, exerciseIds: [String], order: [Int]) async throws

    /// Loads user customization if it exists.
    func loadCustomization(programId: String, workoutId: String) async throws -> WorkoutCustomization?

    /// Fetches specific exercises by IDs.
    func fetchExercisesByIds(_ ids: [String]) async throws -> [CatalogExercise]
}

/// Errors for program workout loading.
enum ProgramWorkoutError: LocalizedError {
    case unknownTemplate(String)
    case exercisesNotFound
    case serviceError(Error)
    case noCategories

    var errorDescription: String? {
        switch self {
        case .unknownTemplate(let id):
            return "Template de treino desconhecido: \(id)"
        case .exercisesNotFound:
            return "Nenhum exercício encontrado para este treino"
        case .serviceError(let error):
            return "Erro no serviço: \(error.localizedDescription)"
        case .noCategories:
            return "Nenhuma categoria encontrada para o tipo de treino"
        }
    }
}
