//
//  SwiftDataWorkoutHistoryRepository.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataWorkoutHistoryRepository: WorkoutHistoryRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    private func context() -> ModelContext {
        ModelContext(modelContainer)
    }

    func listEntries() async throws -> [WorkoutHistoryEntry] {
        let descriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let models = try context().fetch(descriptor)
        return models.compactMap(WorkoutHistoryMapper.toDomain)
    }

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        let ctx = context()
        var descriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
            predicate: #Predicate { $0.id == entry.id }
        )
        descriptor.fetchLimit = 1
        if let existing = try ctx.fetch(descriptor).first {
            existing.date = entry.date
            existing.planId = entry.planId
            existing.title = entry.title
            existing.focusRaw = entry.focus.rawValue
            existing.statusRaw = entry.status.rawValue
        } else {
            ctx.insert(WorkoutHistoryMapper.toModel(entry))
        }
        try ctx.save()
    }
}

