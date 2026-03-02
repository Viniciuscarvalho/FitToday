//
//  ChatRepository.swift
//  FitToday
//

import Foundation

protocol ChatRepository: Sendable {
    func loadMessages(limit: Int) async throws -> [AIChatMessage]
    func saveMessage(_ message: AIChatMessage) async throws
    func clearHistory() async throws
    func messageCount() async throws -> Int
}
