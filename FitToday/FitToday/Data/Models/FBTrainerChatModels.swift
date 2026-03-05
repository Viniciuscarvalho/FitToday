//
//  FBTrainerChatModels.swift
//  FitToday
//

import FirebaseFirestore
import Foundation

struct FBConversation: Codable {
    @DocumentID var id: String?
    var trainerId: String
    var studentId: String
    var lastMessage: String?
    @ServerTimestamp var lastMessageAt: Timestamp?
    var unreadByTrainer: Int
    var unreadByStudent: Int
}

struct FBChatMessage: Codable {
    @DocumentID var id: String?
    var senderId: String
    var content: String
    var type: String
    var isRead: Bool
    @ServerTimestamp var createdAt: Timestamp?
}
