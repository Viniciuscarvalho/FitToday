//
//  SDChatMessage.swift
//  FitToday
//

import Foundation
import SwiftData

@Model
final class SDChatMessage {
    @Attribute(.unique) var id: UUID
    var roleRaw: String
    var content: String
    var timestamp: Date

    init(id: UUID = UUID(), roleRaw: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.roleRaw = roleRaw
        self.content = content
        self.timestamp = timestamp
    }
}
