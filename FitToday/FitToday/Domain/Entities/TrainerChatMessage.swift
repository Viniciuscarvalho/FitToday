//
//  TrainerChatMessage.swift
//  FitToday
//

import Foundation

struct TrainerChatMessage: Identifiable, Sendable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let type: MessageType
    let createdAt: Date
    let isRead: Bool

    enum MessageType: String, Sendable, Hashable {
        case text
    }
}
