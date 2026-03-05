//
//  FirebaseTrainerChatService.swift
//  FitToday
//

import FirebaseFirestore
import Foundation

actor FirebaseTrainerChatService: TrainerChatServiceProtocol {
    private let db = Firestore.firestore()
    private let collectionName = "conversations"

    // MARK: - Observe Messages (Real-Time)

    nonisolated func observeMessages(conversationId: String) -> AsyncStream<[TrainerChatMessage]> {
        AsyncStream { continuation in
            let listener = Firestore.firestore()
                .collection("conversations")
                .document(conversationId)
                .collection("messages")
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }

                    let messages = documents.compactMap { doc in
                        guard let fb = try? doc.data(as: FBChatMessage.self) else { return nil as TrainerChatMessage? }
                        return TrainerChatMessageMapper.toDomain(fb, conversationId: conversationId)
                    }

                    continuation.yield(messages)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Send Message

    func sendMessage(conversationId: String, senderId: String, content: String) async throws {
        let conversationRef = db.collection(collectionName).document(conversationId)
        let messagesRef = conversationRef.collection("messages")

        let fbMessage = FBChatMessage(
            senderId: senderId,
            content: content,
            type: "text",
            isRead: false
        )

        _ = try messagesRef.addDocument(from: fbMessage)

        // Get conversation to determine which unread counter to increment
        let conversationDoc = try await conversationRef.getDocument()

        if conversationDoc.exists {
            // Update existing conversation
            let conversation = try conversationDoc.data(as: FBConversation.self)
            let isTrainer = senderId == conversation.trainerId
            let unreadField = isTrainer ? "unreadByStudent" : "unreadByTrainer"

            try await conversationRef.updateData([
                "lastMessage": content,
                "lastMessageAt": FieldValue.serverTimestamp(),
                unreadField: FieldValue.increment(Int64(1))
            ])
        } else {
            // Create conversation on first message
            // Determine trainerId and studentId from conversationId parts
            let parts = conversationId.split(separator: "_")
            guard parts.count == 2 else { return }

            let id1 = String(parts[0])
            let id2 = String(parts[1])

            // The sender is one of the two; assume the other is the counterpart
            let trainerId: String
            let studentId: String
            if senderId == id1 {
                trainerId = id1
                studentId = id2
            } else {
                trainerId = id2
                studentId = id1
            }

            let newConversation = FBConversation(
                trainerId: trainerId,
                studentId: studentId,
                lastMessage: content,
                unreadByTrainer: senderId == studentId ? 1 : 0,
                unreadByStudent: senderId == trainerId ? 1 : 0
            )

            try conversationRef.setData(from: newConversation)
        }
    }

    // MARK: - Mark Messages as Read

    func markMessagesAsRead(conversationId: String, byUserId: String) async throws {
        let conversationRef = db.collection(collectionName).document(conversationId)
        let conversationDoc = try await conversationRef.getDocument()

        guard conversationDoc.exists,
              let conversation = try? conversationDoc.data(as: FBConversation.self) else { return }

        let isTrainer = byUserId == conversation.trainerId
        let unreadField = isTrainer ? "unreadByTrainer" : "unreadByStudent"

        try await conversationRef.updateData([unreadField: 0])
    }
}
