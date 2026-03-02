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
    private let profileRepository: UserProfileRepository
    private let statsRepository: UserStatsRepository
    private let historyRepository: WorkoutHistoryRepository
    private let promptBuilder = ChatSystemPromptBuilder()

    private var cachedSystemPrompt: String?

    // MARK: - Initialization

    init(
        client: NewOpenAIClient,
        profileRepository: UserProfileRepository,
        statsRepository: UserStatsRepository,
        historyRepository: WorkoutHistoryRepository
    ) {
        self.client = client
        self.profileRepository = profileRepository
        self.statsRepository = statsRepository
        self.historyRepository = historyRepository
    }

    // MARK: - Public API

    /// Sends a message along with the conversation history and returns the assistant response.
    func sendMessage(_ message: String, history: [AIChatMessage]) async throws -> String {
        let systemPrompt = await buildContextualPrompt()

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

    /// Invalidates cached system prompt (call when starting new conversation).
    func invalidatePromptCache() {
        cachedSystemPrompt = nil
    }

    // MARK: - Private

    private func buildContextualPrompt() async -> String {
        if let cached = cachedSystemPrompt {
            return cached
        }

        do {
            let profile = try await profileRepository.loadProfile()
            let stats = try await statsRepository.getCurrentStats()
            let recentWorkouts = try await historyRepository.listEntries(limit: 3, offset: 0)

            let prompt = promptBuilder.buildSystemPrompt(
                profile: profile,
                stats: stats,
                recentWorkouts: recentWorkouts
            )
            cachedSystemPrompt = prompt
            return prompt
        } catch {
            // Fallback to generic prompt if repos fail
            let prompt = promptBuilder.buildSystemPrompt(
                profile: nil,
                stats: nil,
                recentWorkouts: []
            )
            cachedSystemPrompt = prompt
            return prompt
        }
    }
}
