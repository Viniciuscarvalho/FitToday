//
//  ErrorMapper.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import Foundation

/// Mapeia erros técnicos para mensagens user-friendly em português
enum ErrorMapper {
  
  /// Converte erro técnico em ErrorMessage amigável
  /// - Parameter error: Erro a ser mapeado
  /// - Returns: ErrorMessage com título, mensagem e ação apropriados
  static func userFriendlyMessage(for error: Error) -> ErrorMessage {
    switch error {
    case let urlError as URLError:
      return handleURLError(urlError)
      
    case let domainError as DomainError:
      return handleDomainError(domainError)
      
    case let openAIError as OpenAIClientError:
      return handleOpenAIError(openAIError)
      
    case let imageCacheError as ImageCacheError:
      return handleImageCacheError(imageCacheError)
      
    default:
      return ErrorMessage(
        title: "Ops!",
        message: "Algo inesperado aconteceu. Tente novamente.",
        action: .dismiss
      )
    }
  }
  
  // MARK: - URLError Handling
  
  private static func handleURLError(_ error: URLError) -> ErrorMessage {
    switch error.code {
    case .notConnectedToInternet, .networkConnectionLost:
      return ErrorMessage(
        title: "Sem conexão",
        message: "Verifique sua internet e tente novamente.",
        action: .openSettings
      )
      
    case .timedOut:
      return ErrorMessage(
        title: "Tempo esgotado",
        message: "A operação demorou muito. Tente novamente.",
        action: .dismiss
      )
      
    case .cannotFindHost, .cannotConnectToHost:
      return ErrorMessage(
        title: "Servidor indisponível",
        message: "Não conseguimos conectar ao servidor. Tente mais tarde.",
        action: .dismiss
      )
      
    case .badURL, .unsupportedURL:
      return ErrorMessage(
        title: "URL inválida",
        message: "Endereço não reconhecido.",
        action: .dismiss
      )
      
    case .dataNotAllowed:
      return ErrorMessage(
        title: "Dados móveis desabilitados",
        message: "Ative os dados móveis ou conecte-se ao Wi-Fi.",
        action: .openSettings
      )
      
    default:
      return ErrorMessage(
        title: "Erro de conexão",
        message: "Não conseguimos conectar. Tente novamente.",
        action: .dismiss
      )
    }
  }
  
  // MARK: - DomainError Handling
  
  private static func handleDomainError(_ error: DomainError) -> ErrorMessage {
    switch error {
    case .profileNotFound:
      return ErrorMessage(
        title: "Perfil não encontrado",
        message: "Complete seu perfil para gerar treinos personalizados.",
        action: .dismiss
      )
      
    case .invalidInput(let reason):
      return ErrorMessage(
        title: "Dados inválidos",
        message: reason,
        action: .dismiss
      )
      
    case .noCompatibleBlocks:
      return ErrorMessage(
        title: "Nenhum treino compatível",
        message: "Não encontramos exercícios para seu perfil. Tente ajustar suas preferências.",
        action: .dismiss
      )
      
    case .repositoryFailure(let reason):
      return ErrorMessage(
        title: "Erro ao salvar",
        message: "Não conseguimos salvar os dados. \(reason)",
        action: .dismiss
      )
      
    case .networkFailure:
      return ErrorMessage(
        title: "Sem conexão",
        message: "Verifique sua internet e tente novamente.",
        action: .openSettings
      )
      
    case .subscriptionExpired:
      return ErrorMessage(
        title: "Assinatura expirada",
        message: "Renove sua assinatura para continuar usando recursos Pro.",
        action: .dismiss
      )

    case .notAuthenticated:
      return ErrorMessage(
        title: "Autenticação necessária",
        message: "Você precisa estar autenticado para realizar esta ação.",
        action: .dismiss
      )

    case .alreadyInGroup:
      return ErrorMessage(
        title: "Já está em um grupo",
        message: "Você já faz parte de um grupo. Saia do grupo atual para entrar em outro.",
        action: .dismiss
      )

    case .groupNotFound:
      return ErrorMessage(
        title: "Grupo não encontrado",
        message: "O grupo que você está procurando não existe ou foi removido.",
        action: .dismiss
      )

    case .groupFull:
      return ErrorMessage(
        title: "Grupo cheio",
        message: "Este grupo já atingiu o limite máximo de membros.",
        action: .dismiss
      )

    case .notGroupAdmin:
      return ErrorMessage(
        title: "Permissão negada",
        message: "Apenas administradores do grupo podem realizar esta ação.",
        action: .dismiss
      )

    case .networkUnavailable:
      return ErrorMessage(
        title: "Sem conexão",
        message: "Verifique sua conexão com a internet e tente novamente.",
        action: .openSettings
      )

    case .challengeNotFound:
      return ErrorMessage(
        title: "Desafio não encontrado",
        message: "O desafio que você está procurando não existe.",
        action: .dismiss
      )

    case .invalidChallengeType:
      return ErrorMessage(
        title: "Tipo de desafio inválido",
        message: "O tipo de desafio especificado não é válido.",
        action: .dismiss
      )

    case .challengeExpired:
      return ErrorMessage(
        title: "Desafio expirado",
        message: "Este desafio já terminou.",
        action: .dismiss
      )

    case .notFound(let resource):
      return ErrorMessage(
        title: "Não encontrado",
        message: "Recurso não encontrado: \(resource)",
        action: .dismiss
      )
    }
  }
  
  // MARK: - OpenAIClientError Handling
  
  private static func handleOpenAIError(_ error: OpenAIClientError) -> ErrorMessage {
    switch error {
    case .configurationMissing:
      return ErrorMessage(
        title: "IA não configurada",
        message: "Geramos um ótimo treino local para você hoje.",
        action: .dismiss
      )
      
    case .invalidResponse:
      return ErrorMessage(
        title: "IA temporariamente indisponível",
        message: "Geramos um ótimo treino local para você hoje.",
        action: .dismiss
      )
      
    case .httpError(let status, _):
      if status == 429 {
        return ErrorMessage(
          title: "Limite atingido",
          message: "Você atingiu o limite de treinos com IA hoje. Geramos um treino local.",
          action: .dismiss
        )
      } else if status >= 500 {
        return ErrorMessage(
          title: "Servidor temporariamente indisponível",
          message: "Geramos um ótimo treino local para você hoje.",
          action: .dismiss
        )
      } else {
        return ErrorMessage(
          title: "IA temporariamente indisponível",
          message: "Geramos um ótimo treino local para você hoje.",
          action: .dismiss
        )
      }
    }
  }
  
  // MARK: - ImageCacheError Handling
  
  private static func handleImageCacheError(_ error: ImageCacheError) -> ErrorMessage {
    switch error {
    case .invalidResponse(let statusCode):
      return ErrorMessage(
        title: "Erro ao carregar imagem",
        message: "Não conseguimos carregar a imagem (código \(statusCode)).",
        action: .dismiss
      )
      
    case .diskWriteFailed:
      return ErrorMessage(
        title: "Erro ao salvar",
        message: "Não conseguimos salvar a imagem no cache.",
        action: .dismiss
      )
      
    case .cacheSizeExceeded:
      return ErrorMessage(
        title: "Cache cheio",
        message: "O cache de imagens está cheio. Limpe o cache nas configurações.",
        action: .dismiss
      )
      
    case .invalidImageData:
      return ErrorMessage(
        title: "Imagem inválida",
        message: "Os dados da imagem estão corrompidos.",
        action: .dismiss
      )
    }
  }
}

