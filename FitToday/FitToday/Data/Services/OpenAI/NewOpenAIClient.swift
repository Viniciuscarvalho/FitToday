//
//  NewOpenAIClient.swift
//  FitToday
//
//  Proxies AI requests through Firebase Cloud Functions.
//  The OpenAI API key lives on the server — never on the device.
//

import Foundation
import FirebaseFunctions

/// OpenAI client that proxies requests through Firebase Cloud Functions.
///
/// The API key is stored server-side as a Firebase secret. The client
/// authenticates via the user's Firebase Auth token automatically.
///
/// Key features:
/// - No API key on the device
/// - Built-in retry logic (up to 2 retries on transient errors)
/// - Same public API as the previous direct-call implementation
actor NewOpenAIClient: Sendable {

    // MARK: - Types

    enum ClientError: Error, LocalizedError {
        case notAuthenticated
        case invalidResponse
        case httpError(statusCode: Int, message: String)
        case decodingError(String)
        case emptyWorkoutResponse
        case functionsError(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Authentication required to use AI features"
            case .invalidResponse:
                return "Invalid response from AI service"
            case .httpError(let code, let message):
                return "HTTP \(code): \(message)"
            case .decodingError(let detail):
                return "Failed to decode response: \(detail)"
            case .emptyWorkoutResponse:
                return "AI returned an empty workout response"
            case .functionsError(let message):
                return "AI service error: \(message)"
            }
        }
    }

    // MARK: - Configuration

    private let functions: Functions
    private let maxRetries: Int

    // MARK: - Initialization

    init(maxRetries: Int = 2) {
        self.functions = Functions.functions()
        self.maxRetries = maxRetries
    }

    // MARK: - Public API

    /// Generates a workout by sending a prompt to the AI service via Firebase Functions.
    ///
    /// - Parameter prompt: The complete prompt for workout generation
    /// - Returns: Raw JSON data containing the ChatCompletion response
    /// - Throws: ClientError if the request fails after retries
    func generateWorkout(prompt: String) async throws -> Data {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                let callable = functions.httpsCallable("generateWorkout")
                let result = try await callable.call(["prompt": prompt])

                guard let responseDict = result.data as? [String: Any] else {
                    throw ClientError.invalidResponse
                }

                let data = try JSONSerialization.data(withJSONObject: responseDict)

                #if DEBUG
                if attempt > 0 {
                    print("[NewOpenAIClient] Request succeeded on attempt \(attempt + 1)")
                }
                #endif

                return data
            } catch {
                lastError = error

                #if DEBUG
                print("[NewOpenAIClient] Attempt \(attempt + 1) failed: \(error.localizedDescription)")
                #endif

                if let mapped = mapFunctionsError(error), isNonRetryable(mapped) {
                    throw mapped
                }

                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }

        throw lastError.flatMap(mapFunctionsError) ?? ClientError.invalidResponse
    }

    /// Sends a chat completion request with conversation history via Firebase Functions.
    ///
    /// - Parameters:
    ///   - messages: Array of message dictionaries with "role" and "content" keys
    ///   - maxTokens: Maximum tokens in response (default 1000)
    ///   - temperature: Randomness (default 0.7)
    /// - Returns: The assistant's response content string
    func sendChat(
        messages: [[String: String]],
        maxTokens: Int = 1000,
        temperature: Double = 0.7
    ) async throws -> String {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                let callable = functions.httpsCallable("sendChat")
                let result = try await callable.call([
                    "messages": messages,
                    "maxTokens": maxTokens,
                    "temperature": temperature,
                ] as [String: Any])

                guard let responseDict = result.data as? [String: Any],
                      let content = responseDict["content"] as? String,
                      !content.isEmpty else {
                    throw ClientError.emptyWorkoutResponse
                }

                return content
            } catch {
                lastError = error

                #if DEBUG
                print("[NewOpenAIClient] Chat attempt \(attempt + 1) failed: \(error.localizedDescription)")
                #endif

                if let mapped = mapFunctionsError(error), isNonRetryable(mapped) {
                    throw mapped
                }

                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }

        throw lastError.flatMap(mapFunctionsError) ?? ClientError.invalidResponse
    }

    // MARK: - Private Helpers

    private func mapFunctionsError(_ error: Error) -> ClientError? {
        guard let functionsError = error as NSError?,
              functionsError.domain == FunctionsErrorDomain else {
            return nil
        }

        let code = FunctionsErrorCode(rawValue: functionsError.code)
        let message = functionsError.localizedDescription

        switch code {
        case .unauthenticated:
            return .notAuthenticated
        case .resourceExhausted:
            return .httpError(statusCode: 429, message: message)
        case .invalidArgument:
            return .httpError(statusCode: 400, message: message)
        case .internal:
            return .functionsError(message)
        default:
            return .functionsError(message)
        }
    }

    private func isNonRetryable(_ error: ClientError) -> Bool {
        switch error {
        case .notAuthenticated:
            return true
        case .httpError(let code, _) where (400..<500).contains(code):
            return true
        default:
            return false
        }
    }
}

/// Response model for OpenAI Chat Completions API
struct ChatCompletionResponse: Decodable, Sendable {
    let choices: [Choice]

    struct Choice: Decodable, Sendable {
        let message: Message
    }

    struct Message: Decodable, Sendable {
        let content: String?
    }
}
