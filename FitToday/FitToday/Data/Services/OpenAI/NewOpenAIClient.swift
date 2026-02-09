//
//  NewOpenAIClient.swift
//  FitToday
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 3.0)
//

import Foundation

/// Simplified OpenAI client focused on workout generation.
///
/// Key features:
/// - Single responsibility: generate workouts via OpenAI API
/// - Built-in retry logic (up to 2 retries on network errors)
/// - No caching (handled at composer level if needed)
/// - Clean error handling
///
/// - Note: Part of FR-002 (OpenAI Generation Enhancement) from PRD
actor NewOpenAIClient: Sendable {

    // MARK: - Types

    enum ClientError: Error, LocalizedError {
        case missingAPIKey
        case invalidResponse
        case httpError(statusCode: Int, message: String)
        case decodingError(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "OpenAI API key not configured"
            case .invalidResponse:
                return "Invalid response from OpenAI"
            case .httpError(let code, let message):
                return "HTTP \(code): \(message)"
            case .decodingError(let detail):
                return "Failed to decode response: \(detail)"
            }
        }
    }

    // MARK: - Configuration

    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let timeout: TimeInterval
    private let maxTokens: Int
    private let temperature: Double
    private let maxRetries: Int

    private let session: URLSession

    // MARK: - Initialization

    init(
        apiKey: String,
        model: String = "gpt-4o-mini",
        baseURL: URL = URL(string: "https://api.openai.com/v1/chat/completions")!,
        timeout: TimeInterval = 60,
        maxTokens: Int = 2000,
        temperature: Double = 0.55,
        maxRetries: Int = 2
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.timeout = timeout
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.maxRetries = maxRetries

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = timeout
        self.session = URLSession(configuration: sessionConfig)
    }

    /// Factory method to create client from user's stored API key
    static func fromUserKey() -> NewOpenAIClient? {
        guard let apiKey = UserAPIKeyManager.shared.getAPIKey(for: .openAI),
              !apiKey.isEmpty else {
            return nil
        }

        return NewOpenAIClient(apiKey: apiKey)
    }

    // MARK: - Public API

    /// Generates a workout by sending a prompt to OpenAI.
    ///
    /// - Parameter prompt: The complete prompt (system + user messages combined)
    /// - Returns: Raw JSON data containing the workout response
    /// - Throws: ClientError if the request fails after retries
    func generateWorkout(prompt: String) async throws -> Data {
        var lastError: Error?

        // Retry loop
        for attempt in 0...maxRetries {
            do {
                let data = try await performRequest(prompt: prompt)

                #if DEBUG
                if attempt > 0 {
                    print("[NewOpenAIClient] ✅ Request succeeded on attempt \(attempt + 1)")
                }
                #endif

                return data
            } catch {
                lastError = error

                #if DEBUG
                print("[NewOpenAIClient] ⚠️ Attempt \(attempt + 1) failed: \(error.localizedDescription)")
                #endif

                // Don't retry on client errors (4xx)
                if case ClientError.httpError(let code, _) = error, (400..<500).contains(code) {
                    throw error
                }

                // Small delay before retry
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
            }
        }

        // All retries exhausted
        throw lastError ?? ClientError.invalidResponse
    }

    // MARK: - Private Helpers

    private func performRequest(prompt: String) async throws -> Data {
        // 1. Build request
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 2. Build payload
        let messages: [[String: String]] = [
            [
                "role": "system",
                "content": "You are an expert personal trainer who creates personalized workout plans. Always respond with valid JSON following the requested schema."
            ],
            [
                "role": "user",
                "content": prompt
            ]
        ]

        let payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "response_format": ["type": "json_object"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        // 3. Perform request
        let (data, response) = try await session.data(for: request)

        // 4. Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "No details"
            throw ClientError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        return data
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
