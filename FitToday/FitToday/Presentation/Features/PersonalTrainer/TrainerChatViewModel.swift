//
//  TrainerChatViewModel.swift
//  FitToday
//
//  ViewModel for trainer chat interface with Firestore real-time messaging.
//

import Foundation
import Swinject

@MainActor
@Observable final class TrainerChatViewModel {
    private(set) var messages: [TrainerChatMessage] = []
    var newMessageText = ""
    private(set) var isLoading = false
    private(set) var isEmpty = false
    private(set) var error: Error?

    private let trainerId: String
    private let trainerName: String
    private let currentUserId: String
    private let chatService: TrainerChatServiceProtocol?

    nonisolated(unsafe) private var listenerTask: Task<Void, Never>?

    var conversationId: String {
        let ids = [trainerId, currentUserId].sorted()
        return "\(ids[0])_\(ids[1])"
    }

    var canSend: Bool {
        !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(trainerId: String, trainerName: String, currentUserId: String, resolver: Resolver) {
        self.trainerId = trainerId
        self.trainerName = trainerName
        self.currentUserId = currentUserId
        self.chatService = resolver.resolve(TrainerChatServiceProtocol.self)
    }

    deinit {
        let task = listenerTask
        task?.cancel()
    }

    // MARK: - Start Listening

    func startListening() async {
        guard let chatService, listenerTask == nil else { return }

        isLoading = true

        // Mark messages as read when opening
        try? await chatService.markMessagesAsRead(
            conversationId: conversationId,
            byUserId: currentUserId
        )

        listenerTask = Task {
            for await newMessages in chatService.observeMessages(conversationId: conversationId) {
                guard !Task.isCancelled else { break }
                self.messages = newMessages
                self.isEmpty = newMessages.isEmpty
                self.isLoading = false
            }
        }
    }

    // MARK: - Send Message

    func sendMessage() {
        guard canSend, let chatService else { return }
        let content = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        newMessageText = ""

        // Optimistic append
        let optimisticMessage = TrainerChatMessage(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: currentUserId,
            content: content,
            type: .text,
            createdAt: Date(),
            isRead: false
        )
        messages.append(optimisticMessage)

        Task {
            do {
                try await chatService.sendMessage(
                    conversationId: conversationId,
                    senderId: currentUserId,
                    content: content
                )
            } catch {
                // Remove optimistic message on failure
                messages.removeAll { $0.id == optimisticMessage.id }
                self.error = error
            }
        }
    }

    func isFromCurrentUser(_ message: TrainerChatMessage) -> Bool {
        message.senderId == currentUserId
    }

    // MARK: - Stop Listening

    func stopListening() {
        listenerTask?.cancel()
        listenerTask = nil
    }
}
