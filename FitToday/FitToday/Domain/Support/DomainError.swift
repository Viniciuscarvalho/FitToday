//
//  DomainError.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

enum DomainError: Error, LocalizedError, Sendable {
    case profileNotFound
    case invalidInput(reason: String)
    case noCompatibleBlocks
    case repositoryFailure(reason: String)
    case networkFailure
    case subscriptionExpired

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
        }
    }
}


