//
//  WgerProgramWorkoutRepository.swift
//  FitToday
//
//  Protocol para repositório que carrega exercícios Wger para programas de treino.
//

import Foundation

/// Repositório para carregar exercícios da API Wger para programas de treino.
protocol WgerProgramWorkoutRepository: Sendable {
    /// Carrega exercícios Wger para um template de workout específico.
    /// - Parameters:
    ///   - templateId: ID do template (ex: "lib_push_beginner_gym")
    ///   - exerciseCount: Número de exercícios a retornar (default: 8)
    /// - Returns: Array de exercícios da API Wger
    func loadWorkoutExercises(
        templateId: String,
        exerciseCount: Int
    ) async throws -> [WgerExercise]

    /// Salva customização do usuário para um treino.
    /// - Parameters:
    ///   - programId: ID do programa
    ///   - workoutId: ID do treino dentro do programa
    ///   - exerciseIds: IDs dos exercícios na ordem customizada
    ///   - order: Índices de ordenação
    func saveCustomization(
        programId: String,
        workoutId: String,
        exerciseIds: [Int],
        order: [Int]
    ) async throws

    /// Carrega customização do usuário se existir.
    /// - Parameters:
    ///   - programId: ID do programa
    ///   - workoutId: ID do treino
    /// - Returns: Customização salva ou nil se não existir
    func loadCustomization(
        programId: String,
        workoutId: String
    ) async throws -> WorkoutCustomization?

    /// Busca exercícios específicos por IDs.
    /// - Parameter ids: Array de IDs de exercícios Wger
    /// - Returns: Array de exercícios encontrados
    func fetchExercisesByIds(_ ids: [Int]) async throws -> [WgerExercise]
}

/// Erros específicos do repositório de programas Wger.
enum WgerProgramError: LocalizedError {
    case unknownTemplate(String)
    case exercisesNotFound
    case apiError(Error)
    case noCategories

    var errorDescription: String? {
        switch self {
        case .unknownTemplate(let id):
            return "Template de treino desconhecido: \(id)"
        case .exercisesNotFound:
            return "Nenhum exercício encontrado para este treino"
        case .apiError(let error):
            return "Erro na API: \(error.localizedDescription)"
        case .noCategories:
            return "Nenhuma categoria encontrada para o tipo de treino"
        }
    }
}
