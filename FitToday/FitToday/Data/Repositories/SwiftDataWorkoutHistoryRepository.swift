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
    
    /// Lista entradas com paginação para performance otimizada
    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        var descriptor = FetchDescriptor<SDWorkoutHistoryEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        let models = try context().fetch(descriptor)
        return models.compactMap(WorkoutHistoryMapper.toDomain)
    }
    
    /// Retorna o total de entradas no histórico
    func count() async throws -> Int {
        let descriptor = FetchDescriptor<SDWorkoutHistoryEntry>()
        return try context().fetchCount(descriptor)
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
            existing.programId = entry.programId
            existing.programName = entry.programName
            existing.durationMinutes = entry.durationMinutes
            existing.caloriesBurned = entry.caloriesBurned
            existing.healthKitWorkoutUUID = entry.healthKitWorkoutUUID
            
            // Serializar WorkoutPlan se houver (mantém histórico rico)
            if let plan = entry.workoutPlan {
                existing.workoutPlanJSON = try? JSONEncoder().encode(plan)
            } else {
                existing.workoutPlanJSON = nil
            }
        } else {
            ctx.insert(WorkoutHistoryMapper.toModel(entry))
        }
        try ctx.save()
    }
}

