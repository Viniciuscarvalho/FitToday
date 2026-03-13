//
//  SwiftDataXPRepository.swift
//  FitToday
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataXPRepository: XPRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    private func context() -> ModelContext {
        ModelContext(modelContainer)
    }

    func getUserXP() async throws -> UserXP {
        let context = context()
        var descriptor = FetchDescriptor<SDUserXP>(
            predicate: #Predicate { $0.id == "current" }
        )
        descriptor.fetchLimit = 1

        guard let model = try context.fetch(descriptor).first else {
            return .empty
        }
        return model.toDomain()
    }

    func awardXP(transaction: XPTransaction) async throws -> UserXP {
        let context = context()
        var descriptor = FetchDescriptor<SDUserXP>(
            predicate: #Predicate { $0.id == "current" }
        )
        descriptor.fetchLimit = 1

        let model: SDUserXP
        if let existing = try context.fetch(descriptor).first {
            model = existing
        } else {
            model = SDUserXP()
            context.insert(model)
        }

        model.totalXP += transaction.amount
        model.lastAwardDate = transaction.date
        try context.save()

        return model.toDomain()
    }

    func syncFromRemote() async throws {
        // Future: sync from Firestore
    }
}
