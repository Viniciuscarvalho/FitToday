//
//  SwiftDataSavedRoutineRepository.swift
//  FitToday
//
//  SwiftData implementation for SavedRoutineRepository.
//  Manages user's saved routines with a maximum limit of 5.
//

import Foundation
import SwiftData

/// SwiftData implementation of SavedRoutineRepository
final class SwiftDataSavedRoutineRepository: SavedRoutineRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func listRoutines() async throws -> [SavedRoutine] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDSavedRoutine>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )

        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    @MainActor
    func saveRoutine(_ routine: SavedRoutine) async throws {
        let context = modelContainer.mainContext

        // Check limit
        let countDescriptor = FetchDescriptor<SDSavedRoutine>()
        let count = try context.fetchCount(countDescriptor)

        guard count < SavedRoutine.maxSavedRoutines else {
            throw SavedRoutineError.limitReached
        }

        // Check if program is already saved
        let programId = routine.programId
        let existingPredicate = #Predicate<SDSavedRoutine> { $0.programId == programId }
        let existingDescriptor = FetchDescriptor<SDSavedRoutine>(predicate: existingPredicate)

        if try context.fetchCount(existingDescriptor) > 0 {
            throw SavedRoutineError.alreadySaved
        }

        // Insert new routine
        let model = SDSavedRoutine(from: routine)
        context.insert(model)
        try context.save()

        #if DEBUG
        print("[SavedRoutineRepo] ✅ Saved routine '\(routine.name)' (\(count + 1)/\(SavedRoutine.maxSavedRoutines))")
        #endif
    }

    @MainActor
    func deleteRoutine(_ id: UUID) async throws {
        let context = modelContainer.mainContext
        let predicate = #Predicate<SDSavedRoutine> { $0.id == id }
        let descriptor = FetchDescriptor<SDSavedRoutine>(predicate: predicate)

        if let model = try context.fetch(descriptor).first {
            let name = model.name
            context.delete(model)
            try context.save()

            #if DEBUG
            print("[SavedRoutineRepo] 🗑️ Deleted routine '\(name)'")
            #endif
        } else {
            throw SavedRoutineError.notFound
        }
    }

    @MainActor
    func canSaveMore() async -> Bool {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDSavedRoutine>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count < SavedRoutine.maxSavedRoutines
    }

    @MainActor
    func isRoutineSaved(programId: String) async -> Bool {
        let context = modelContainer.mainContext
        let predicate = #Predicate<SDSavedRoutine> { $0.programId == programId }
        let descriptor = FetchDescriptor<SDSavedRoutine>(predicate: predicate)
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }
}
