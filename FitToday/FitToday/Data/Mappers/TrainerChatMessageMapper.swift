//
//  TrainerChatMessageMapper.swift
//  FitToday
//

import Foundation
import FirebaseCore

struct TrainerChatMessageMapper {

    static func toDomain(_ fb: FBChatMessage, conversationId: String) -> TrainerChatMessage {
        TrainerChatMessage(
            id: fb.id ?? UUID().uuidString,
            conversationId: conversationId,
            senderId: fb.senderId,
            content: fb.content,
            type: TrainerChatMessage.MessageType(rawValue: fb.type) ?? .text,
            createdAt: fb.createdAt?.dateValue() ?? Date(),
            isRead: fb.isRead
        )
    }
}
