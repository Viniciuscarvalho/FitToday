//
//  TrainerChatViewModel.swift
//  FitToday
//
//  ViewModel for trainer chat interface.
//  Currently uses mock data — real chat backend to be integrated later.
//

import Foundation

/// A single chat message between trainer and student.
struct ChatMessage: Identifiable, Sendable {
    let id: String
    let text: String
    let senderId: String
    let timestamp: Date
    let isFromTrainer: Bool
}

@MainActor
@Observable final class TrainerChatViewModel {
    private(set) var messages: [ChatMessage] = []
    var newMessageText = ""

    private let trainerId: String
    private let trainerName: String

    var canSend: Bool {
        !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(trainerId: String, trainerName: String) {
        self.trainerId = trainerId
        self.trainerName = trainerName
        loadMockMessages()
    }

    func sendMessage() {
        guard canSend else { return }
        let message = ChatMessage(
            id: UUID().uuidString,
            text: newMessageText.trimmingCharacters(in: .whitespacesAndNewlines),
            senderId: "current_user",
            timestamp: Date(),
            isFromTrainer: false
        )
        messages.append(message)
        newMessageText = ""
    }

    private func loadMockMessages() {
        let calendar = Calendar.current
        let now = Date()
        messages = [
            ChatMessage(id: "1", text: "trainer.chat.mock.msg1".localized, senderId: trainerId, timestamp: calendar.date(byAdding: .hour, value: -2, to: now)!, isFromTrainer: true),
            ChatMessage(id: "2", text: "trainer.chat.mock.msg2".localized, senderId: "current_user", timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!, isFromTrainer: false),
            ChatMessage(id: "3", text: "trainer.chat.mock.msg3".localized, senderId: trainerId, timestamp: calendar.date(byAdding: .minute, value: -45, to: now)!, isFromTrainer: true),
            ChatMessage(id: "4", text: "trainer.chat.mock.msg4".localized, senderId: "current_user", timestamp: calendar.date(byAdding: .minute, value: -30, to: now)!, isFromTrainer: false),
            ChatMessage(id: "5", text: "trainer.chat.mock.msg5".localized, senderId: trainerId, timestamp: calendar.date(byAdding: .minute, value: -10, to: now)!, isFromTrainer: true),
        ]
    }
}
