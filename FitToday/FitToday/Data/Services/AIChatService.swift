//
//  AIChatService.swift
//  FitToday
//
//  Wraps NewOpenAIClient for conversational chat mode (FitPal).
//

import Foundation
import Swinject

actor AIChatService {

    // MARK: - Types

    enum ServiceError: LocalizedError {
        case clientUnavailable
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .clientUnavailable:
                return "OpenAI client is not available. Please configure your API key."
            case .emptyResponse:
                return "Received an empty response from the assistant."
            }
        }
    }

    // MARK: - Properties

    private let client: NewOpenAIClient

    private let systemPrompt = "You are FitPal, an AI fitness assistant. Help users plan workouts, suggest exercises, and provide fitness guidance. Be friendly, motivating, and concise."

    // MARK: - Initialization

    init(resolver: Resolver) throws {
        guard let client = resolver.resolve(NewOpenAIClient.self) ?? NewOpenAIClient.fromUserKey() else {
            throw ServiceError.clientUnavailable
        }
        self.client = client
    }

    // MARK: - Public API

    /// Sends a message along with the conversation history and returns the assistant response.
    func sendMessage(_ message: String, history: [AIChatMessage]) async throws -> String {
        // Build messages array for OpenAI
        var chatMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]

        // Append conversation history (skip system messages already in history)
        for msg in history where msg.role != .system {
            chatMessages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }

        // Append current user message
        chatMessages.append([
            "role": "user",
            "content": message
        ])

        // Build request payload
        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": chatMessages,
            "max_tokens": 1000,
            "temperature": 0.7
        ]

        let data = try await performChatRequest(payload: payload)

        // Decode response
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = response.choices.first?.message.content, !content.isEmpty else {
            throw ServiceError.emptyResponse
        }

        return content
    }

    // MARK: - Private

    private func performChatRequest(payload: [String: Any]) async throws -> Data {
        guard let apiKey = UserAPIKeyManager.shared.getAPIKey(for: .openAI) else {
            throw NewOpenAIClient.ClientError.missingAPIKey
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "No details"
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NewOpenAIClient.ClientError.httpError(statusCode: code, message: message)
        }

        return data
    }
}
