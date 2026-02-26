//
//  AIChatViewModel.swift
//  FitToday
//
//  ViewModel for the AI FitPal chat feature.
//

import Foundation
import Swinject

@MainActor
@Observable
final class AIChatViewModel {

    // MARK: - Properties

    var messages: [AIChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Quick Actions

    static var quickActions: [String] {
        [
            "fitpal.quick.plan_workout".localized,
            "fitpal.quick.suggest_exercises".localized,
            "fitpal.quick.warmup".localized,
            "fitpal.quick.recovery".localized
        ]
    }

    // MARK: - Private

    private let chatService: AIChatService?

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.chatService = try? resolver.resolve(AIChatService.self) ?? AIChatService(resolver: resolver)
    }

    // MARK: - Actions

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = AIChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let service = chatService else {
                    throw AIChatService.ServiceError.clientUnavailable
                }
                let response = try await service.sendMessage(text, history: messages)
                let assistantMessage = AIChatMessage(role: .assistant, content: response)
                messages.append(assistantMessage)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
