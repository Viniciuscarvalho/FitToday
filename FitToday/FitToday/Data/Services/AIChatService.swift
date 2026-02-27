//
//  AIChatService.swift
//  FitToday
//
//  Wraps NewOpenAIClient for conversational chat mode (FitOrb).
//

import Foundation

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

    private let systemPrompt = "You are FitOrb, an AI fitness assistant. Help users plan workouts, suggest exercises, and provide fitness guidance. Be friendly, motivating, and concise."

    // MARK: - Initialization

    init(client: NewOpenAIClient) {
        self.client = client
    }

    // MARK: - Public API

    /// Sends a message along with the conversation history and returns the assistant response.
    func sendMessage(_ message: String, history: [AIChatMessage]) async throws -> String {
        var chatMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]

        for msg in history where msg.role != .system {
            chatMessages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }

        chatMessages.append([
            "role": "user",
            "content": message
        ])

        return try await client.sendChat(messages: chatMessages, maxTokens: 1000, temperature: 0.7)
    }
}
