//
//  SwiftDataChatRepository.swift
//  FitToday
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataChatRepository: ChatRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    private func context() -> ModelContext {
        ModelContext(modelContainer)
    }

    func loadMessages(limit: Int) async throws -> [AIChatMessage] {
        var descriptor = FetchDescriptor<SDChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        descriptor.fetchLimit = limit
        let models = try context().fetch(descriptor)
        return models.compactMap(ChatMessageMapper.toDomain)
    }

    func saveMessage(_ message: AIChatMessage) async throws {
        let ctx = context()
        ctx.insert(ChatMessageMapper.toModel(message))
        try ctx.save()
    }

    func clearHistory() async throws {
        let ctx = context()
        let descriptor = FetchDescriptor<SDChatMessage>()
        let all = try ctx.fetch(descriptor)
        for model in all {
            ctx.delete(model)
        }
        try ctx.save()
    }

    func messageCount() async throws -> Int {
        let descriptor = FetchDescriptor<SDChatMessage>()
        return try context().fetchCount(descriptor)
    }
}
