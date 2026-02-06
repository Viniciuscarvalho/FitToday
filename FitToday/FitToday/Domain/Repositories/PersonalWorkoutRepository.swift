//
//  PersonalWorkoutRepository.swift
//  FitToday
//
//  Protocol para acesso aos treinos do Personal.
//

import Foundation

/// Protocol para acesso aos treinos enviados pelo Personal Trainer.
public protocol PersonalWorkoutRepository: Sendable {
    /// Busca todos os treinos do personal para o usuário atual.
    /// - Parameter userId: ID do usuário
    /// - Returns: Lista de treinos ordenados por data (mais recente primeiro)
    func fetchWorkouts(for userId: String) async throws -> [PersonalWorkout]

    /// Marca um treino como visualizado.
    /// - Parameter workoutId: ID do treino
    func markAsViewed(_ workoutId: String) async throws

    /// Observa mudanças em tempo real nos treinos.
    /// - Parameter userId: ID do usuário
    /// - Returns: AsyncStream com atualizações da lista de treinos
    func observeWorkouts(for userId: String) -> AsyncStream<[PersonalWorkout]>
}
