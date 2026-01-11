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

