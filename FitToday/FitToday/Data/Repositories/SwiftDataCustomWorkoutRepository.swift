//
//  SwiftDataCustomWorkoutRepository.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation
import SwiftData

/// SwiftData implementation of CustomWorkoutRepository
final class SwiftDataCustomWorkoutRepository: CustomWorkoutRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func listTemplates() async throws -> [CustomWorkoutTemplate] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<SDCustomWorkoutTemplate>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )

        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    @MainActor
    func getTemplate(id: UUID) async throws -> CustomWorkoutTemplate? {
        let context = modelContainer.mainContext
        let predicate = #Predicate<SDCustomWorkoutTemplate> { $0.id == id }
        let descriptor = FetchDescriptor<SDCustomWorkoutTemplate>(predicate: predicate)

        return try context.fetch(descriptor).first?.toDomain()
    }

    @MainActor
    func saveTemplate(_ template: CustomWorkoutTemplate) async throws {
        let context = modelContainer.mainContext

        // Check if exists
        let predicate = #Predicate<SDCustomWorkoutTemplate> { $0.id == template.id }
        let descriptor = FetchDescriptor<SDCustomWorkoutTemplate>(predicate: predicate)
        let existing = try context.fetch(descriptor).first

        if let existing {
            // Update existing
            let encoder = JSONEncoder()
            existing.name = template.name
            existing.exercisesData = (try? encoder.encode(template.exercises)) ?? Data()
            existing.lastUsedAt = template.lastUsedAt
            existing.workoutDescription = template.workoutDescription
            existing.category = template.category
        } else {
            // Insert new
            let model = SDCustomWorkoutTemplate(from: template)
            context.insert(model)
        }

        try context.save()
    }

    @MainActor
    func deleteTemplate(id: UUID) async throws {
        let context = modelContainer.mainContext
        let predicate = #Predicate<SDCustomWorkoutTemplate> { $0.id == id }
        let descriptor = FetchDescriptor<SDCustomWorkoutTemplate>(predicate: predicate)

        if let model = try context.fetch(descriptor).first {
            context.delete(model)
            try context.save()
        }
    }

    @MainActor
    func recordCompletion(
        templateId: UUID,
        actualExercises: [CustomExerciseEntry],
        duration: Int,
        completedAt: Date
    ) async throws {
        let context = modelContainer.mainContext

        let completion = CustomWorkoutCompletion(
            templateId: templateId,
            completedAt: completedAt,
            durationMinutes: duration,
            exercises: actualExercises
        )

        let model = SDCustomWorkoutCompletion(from: completion)
        context.insert(model)

        // Update template's lastUsedAt
        try await updateLastUsed(id: templateId)

        try context.save()
    }

    @MainActor
    func getCompletionHistory(templateId: UUID) async throws -> [CustomWorkoutCompletion] {
        let context = modelContainer.mainContext
        let predicate = #Predicate<SDCustomWorkoutCompletion> { $0.templateId == templateId }
        let descriptor = FetchDescriptor<SDCustomWorkoutCompletion>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    @MainActor
    func updateLastUsed(id: UUID) async throws {
        let context = modelContainer.mainContext
        let predicate = #Predicate<SDCustomWorkoutTemplate> { $0.id == id }
        let descriptor = FetchDescriptor<SDCustomWorkoutTemplate>(predicate: predicate)

        if let model = try context.fetch(descriptor).first {
            model.lastUsedAt = Date()
            try context.save()
        }
    }
}
