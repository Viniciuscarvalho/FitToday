//
//  AIChatViewModel.swift
//  FitToday
//
//  ViewModel for the AI FitOrb chat feature.
//

import Foundation
import Swinject

@MainActor
@Observable
final class AIChatViewModel: ErrorPresenting {

    // MARK: - Properties

    var messages: [AIChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: ErrorMessage?

    // MARK: - Quick Actions

    static var quickActions: [String] {
        [
            "fitorb.quick.plan_workout".localized,
            "fitorb.quick.suggest_exercises".localized,
            "fitorb.quick.warmup".localized,
            "fitorb.quick.recovery".localized
        ]
    }

    // MARK: - Private

    private let chatService: AIChatService?
    private let chatRepository: ChatRepository?

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.chatService = resolver.resolve(AIChatService.self)
        self.chatRepository = resolver.resolve(ChatRepository.self)
    }

    // MARK: - Computed

    var isChatAvailable: Bool {
        chatService != nil
    }

    // MARK: - Actions

    func loadHistory() async {
        guard let repo = chatRepository else { return }
        do {
            messages = try await repo.loadMessages(limit: 50)
        } catch {
            handleError(error)
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        guard chatService != nil else {
            errorMessage = ErrorMessage(
                title: "error.openai.not_configured.title".localized,
                message: "fitorb.error_no_api_key".localized,
                action: .dismiss
            )
            return
        }

        let userMessage = AIChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        Task {
            // Save user message
            try? await chatRepository?.saveMessage(userMessage)

            do {
                let response = try await chatService!.sendMessage(text, history: messages)
                let assistantMessage = AIChatMessage(role: .assistant, content: response)
                messages.append(assistantMessage)
                // Save assistant message
                try? await chatRepository?.saveMessage(assistantMessage)
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }

    func clearHistory() async {
        messages.removeAll()
        try? await chatRepository?.clearHistory()
        // Invalidate cached system prompt for fresh context on next conversation
        await chatService?.invalidatePromptCache()
    }
}
