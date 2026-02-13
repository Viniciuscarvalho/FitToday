//
//  ErrorMapper.swift
//  FitToday
//
//  Created by AI on 07/01/26.
//

import Foundation

/// Maps technical errors to user-friendly localized messages
enum ErrorMapper {

  /// Converts technical error to user-friendly ErrorMessage
  /// - Parameter error: Error to be mapped
  /// - Returns: ErrorMessage with localized title, message, and appropriate action
  static func userFriendlyMessage(for error: Error) -> ErrorMessage {
    switch error {
    case let urlError as URLError:
      return handleURLError(urlError)

    case let domainError as DomainError:
      return handleDomainError(domainError)

    case let openAIError as NewOpenAIClient.ClientError:
      return handleOpenAIError(openAIError)

    case let imageCacheError as ImageCacheError:
      return handleImageCacheError(imageCacheError)

    default:
      return ErrorMessage(
        title: "error.generic.title".localized,
        message: "error.generic.message".localized,
        action: .dismiss
      )
    }
  }

  // MARK: - URLError Handling

  private static func handleURLError(_ error: URLError) -> ErrorMessage {
    switch error.code {
    case .notConnectedToInternet, .networkConnectionLost:
      return ErrorMessage(
        title: "error.network.no_connection.title".localized,
        message: "error.network.no_connection.message".localized,
        action: .openSettings
      )

    case .timedOut:
      return ErrorMessage(
        title: "error.network.timeout.title".localized,
        message: "error.network.timeout.message".localized,
        action: .dismiss
      )

    case .cannotFindHost, .cannotConnectToHost:
      return ErrorMessage(
        title: "error.network.server_unavailable.title".localized,
        message: "error.network.server_unavailable.message".localized,
        action: .dismiss
      )

    case .badURL, .unsupportedURL:
      return ErrorMessage(
        title: "error.network.invalid_url.title".localized,
        message: "error.network.invalid_url.message".localized,
        action: .dismiss
      )

    case .dataNotAllowed:
      return ErrorMessage(
        title: "error.network.mobile_data.title".localized,
        message: "error.network.mobile_data.message".localized,
        action: .openSettings
      )

    default:
      return ErrorMessage(
        title: "error.network.connection.title".localized,
        message: "error.network.connection.message".localized,
        action: .dismiss
      )
    }
  }

  // MARK: - DomainError Handling

  private static func handleDomainError(_ error: DomainError) -> ErrorMessage {
    switch error {
    case .profileNotFound:
      return ErrorMessage(
        title: "error.domain.profile_not_found.title".localized,
        message: "error.domain.profile_not_found.message".localized,
        action: .dismiss
      )

    case .invalidInput(let reason):
      return ErrorMessage(
        title: "error.domain.invalid_input.title".localized,
        message: reason,
        action: .dismiss
      )

    case .noCompatibleBlocks:
      return ErrorMessage(
        title: "error.domain.no_compatible_blocks.title".localized,
        message: "error.domain.no_compatible_blocks.message".localized,
        action: .dismiss
      )

    case .repositoryFailure(let reason):
      return ErrorMessage(
        title: "error.domain.repository_failure.title".localized,
        message: "error.domain.repository_failure.message".localized + " \(reason)",
        action: .dismiss
      )

    case .networkFailure:
      return ErrorMessage(
        title: "error.network.no_connection.title".localized,
        message: "error.network.no_connection.message".localized,
        action: .openSettings
      )

    case .subscriptionExpired:
      return ErrorMessage(
        title: "error.domain.subscription_expired.title".localized,
        message: "error.domain.subscription_expired.message".localized,
        action: .dismiss
      )

    case .notAuthenticated:
      return ErrorMessage(
        title: "error.domain.not_authenticated.title".localized,
        message: "error.domain.not_authenticated.message".localized,
        action: .dismiss
      )

    case .alreadyInGroup:
      return ErrorMessage(
        title: "error.domain.already_in_group.title".localized,
        message: "error.domain.already_in_group.message".localized,
        action: .dismiss
      )

    case .groupNotFound:
      return ErrorMessage(
        title: "error.domain.group_not_found.title".localized,
        message: "error.domain.group_not_found.message".localized,
        action: .dismiss
      )

    case .groupFull:
      return ErrorMessage(
        title: "error.domain.group_full.title".localized,
        message: "error.domain.group_full.message".localized,
        action: .dismiss
      )

    case .notGroupAdmin:
      return ErrorMessage(
        title: "error.domain.not_group_admin.title".localized,
        message: "error.domain.not_group_admin.message".localized,
        action: .dismiss
      )

    case .networkUnavailable:
      return ErrorMessage(
        title: "error.network.no_connection.title".localized,
        message: "error.network.no_connection.message".localized,
        action: .openSettings
      )

    case .challengeNotFound:
      return ErrorMessage(
        title: "error.domain.challenge_not_found.title".localized,
        message: "error.domain.challenge_not_found.message".localized,
        action: .dismiss
      )

    case .invalidChallengeType:
      return ErrorMessage(
        title: "error.domain.invalid_challenge_type.title".localized,
        message: "error.domain.invalid_challenge_type.message".localized,
        action: .dismiss
      )

    case .challengeExpired:
      return ErrorMessage(
        title: "error.domain.challenge_expired.title".localized,
        message: "error.domain.challenge_expired.message".localized,
        action: .dismiss
      )

    case .notFound(let resource):
      return ErrorMessage(
        title: "error.domain.not_found.title".localized,
        message: String(format: "error.domain.not_found.message".localized, resource),
        action: .dismiss
      )

    case .dailyGenerationLimitReached:
      return ErrorMessage(
        title: "error.domain.daily_limit.title".localized,
        message: "error.domain.daily_limit.message".localized,
        action: .dismiss
      )

    case .diversityValidationFailed:
      return ErrorMessage(
        title: "error.domain.diversity_failed.title".localized,
        message: "error.domain.diversity_failed.message".localized,
        action: .dismiss
      )
    }
  }

  // MARK: - OpenAIClientError Handling

  private static func handleOpenAIError(_ error: NewOpenAIClient.ClientError) -> ErrorMessage {
    switch error {
    case .missingAPIKey:
      return ErrorMessage(
        title: "error.openai.not_configured.title".localized,
        message: "error.openai.fallback.message".localized,
        action: .dismiss
      )

    case .invalidResponse:
      return ErrorMessage(
        title: "error.openai.temporarily_unavailable.title".localized,
        message: "error.openai.fallback.message".localized,
        action: .dismiss
      )

    case .decodingError:
      return ErrorMessage(
        title: "error.openai.processing.title".localized,
        message: "error.openai.fallback.message".localized,
        action: .dismiss
      )

    case .httpError(let statusCode, _):
      if statusCode == 429 {
        return ErrorMessage(
          title: "error.openai.rate_limit.title".localized,
          message: "error.openai.rate_limit.message".localized,
          action: .dismiss
        )
      } else if statusCode >= 500 {
        return ErrorMessage(
          title: "error.openai.server_unavailable.title".localized,
          message: "error.openai.fallback.message".localized,
          action: .dismiss
        )
      } else {
        return ErrorMessage(
          title: "error.openai.temporarily_unavailable.title".localized,
          message: "error.openai.fallback.message".localized,
          action: .dismiss
        )
      }

    case .emptyWorkoutResponse:
      return ErrorMessage(
        title: "error.openai.incomplete_response.title".localized,
        message: "error.openai.incomplete_response.message".localized,
        action: .dismiss
      )
    }
  }

  // MARK: - ImageCacheError Handling

  private static func handleImageCacheError(_ error: ImageCacheError) -> ErrorMessage {
    switch error {
    case .invalidResponse(let statusCode):
      return ErrorMessage(
        title: "error.image.load_failed.title".localized,
        message: String(format: "error.image.load_failed.message".localized, statusCode),
        action: .dismiss
      )

    case .diskWriteFailed:
      return ErrorMessage(
        title: "error.image.save_failed.title".localized,
        message: "error.image.save_failed.message".localized,
        action: .dismiss
      )

    case .cacheSizeExceeded:
      return ErrorMessage(
        title: "error.image.cache_full.title".localized,
        message: "error.image.cache_full.message".localized,
        action: .dismiss
      )

    case .invalidImageData:
      return ErrorMessage(
        title: "error.image.invalid_data.title".localized,
        message: "error.image.invalid_data.message".localized,
        action: .dismiss
      )
    }
  }
}

