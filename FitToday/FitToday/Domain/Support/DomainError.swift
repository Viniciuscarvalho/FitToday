//
//  DomainError.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

enum DomainError: Error, LocalizedError, Sendable, Equatable {
    case profileNotFound
    case invalidInput(reason: String)
    case noCompatibleBlocks
    case repositoryFailure(reason: String)
    case networkFailure
    case subscriptionExpired

    // MARK: - Social Feature Errors
    case notAuthenticated
    case alreadyInGroup
    case groupNotFound
    case groupFull
    case notGroupAdmin
    case networkUnavailable
    case challengeNotFound
    case invalidChallengeType
    case challengeExpired
    case notFound(resource: String)

    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "Nenhum perfil configurado."
        case .invalidInput(let reason):
            return reason
        case .noCompatibleBlocks:
            return "Não encontramos blocos compatíveis para montar o treino de hoje."
        case .repositoryFailure(let reason):
            return reason
        case .networkFailure:
            return "Falha de conexão de rede."
        case .subscriptionExpired:
            return "Assinatura expirada."
        case .notAuthenticated:
            return "Você precisa estar autenticado para realizar esta ação."
        case .alreadyInGroup:
            return "Você já está em um grupo."
        case .groupNotFound:
            return "Grupo não encontrado."
        case .groupFull:
            return "Este grupo já atingiu o limite máximo de membros."
        case .notGroupAdmin:
            return "Apenas administradores do grupo podem realizar esta ação."
        case .networkUnavailable:
            return "Sem conexão com a internet."
        case .challengeNotFound:
            return "Desafio não encontrado."
        case .invalidChallengeType:
            return "Tipo de desafio inválido."
        case .challengeExpired:
            return "Este desafio já expirou."
        case .notFound(let resource):
            return "Recurso não encontrado: \(resource)"
        }
    }
}




