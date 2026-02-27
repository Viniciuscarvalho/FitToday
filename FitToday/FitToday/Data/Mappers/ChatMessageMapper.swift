//
//  ChatMessageMapper.swift
//  FitToday
//

import Foundation

struct ChatMessageMapper {
    static func toDomain(_ model: SDChatMessage) -> AIChatMessage? {
        guard let role = AIChatMessage.Role(rawValue: model.roleRaw) else { return nil }
        return AIChatMessage(id: model.id, role: role, content: model.content, timestamp: model.timestamp)
    }

    static func toModel(_ message: AIChatMessage) -> SDChatMessage {
        SDChatMessage(id: message.id, roleRaw: message.role.rawValue, content: message.content, timestamp: message.timestamp)
    }
}
