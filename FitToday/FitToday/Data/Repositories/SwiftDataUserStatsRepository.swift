//
//  SwiftDataUserStatsRepository.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataUserStatsRepository: UserStatsRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    private func context() -> ModelContext {
        ModelContext(modelContainer)
    }

    func getCurrentStats() async throws -> UserStats? {
        let context = context()
        var descriptor = FetchDescriptor<SDUserStats>(
            predicate: #Predicate { $0.id == "current" }
        )
        descriptor.fetchLimit = 1

        let models = try context.fetch(descriptor)
        guard let model = models.first else { return nil }
        return UserStatsMapper.toDomain(model)
    }

    func saveStats(_ stats: UserStats) async throws {
        let context = context()
        var descriptor = FetchDescriptor<SDUserStats>(
            predicate: #Predicate { $0.id == "current" }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            // Update existing record
            UserStatsMapper.updateModel(existing, with: stats)
        } else {
            // Insert new record
            let model = UserStatsMapper.toModel(stats)
            context.insert(model)
        }
        try context.save()
    }

    func resetStats() async throws {
        let context = context()
        let descriptor = FetchDescriptor<SDUserStats>(
            predicate: #Predicate { $0.id == "current" }
        )

        let models = try context.fetch(descriptor)
        for model in models {
            context.delete(model)
        }
        try context.save()
    }
}
