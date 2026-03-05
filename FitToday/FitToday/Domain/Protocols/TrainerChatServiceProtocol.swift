//
//  TrainerChatServiceProtocol.swift
//  FitToday
//

import Foundation

protocol TrainerChatServiceProtocol: Sendable {
    func observeMessages(conversationId: String) -> AsyncStream<[TrainerChatMessage]>
    func sendMessage(conversationId: String, senderId: String, content: String) async throws
    func markMessagesAsRead(conversationId: String, byUserId: String) async throws
}
