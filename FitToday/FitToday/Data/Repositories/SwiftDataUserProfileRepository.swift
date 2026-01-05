//
//  SwiftDataUserProfileRepository.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataUserProfileRepository: UserProfileRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    private func context() -> ModelContext {
        ModelContext(modelContainer)
    }

    func loadProfile() async throws -> UserProfile? {
        let context = context()
        var descriptor = FetchDescriptor<SDUserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let models = try context.fetch(descriptor)
        guard let model = models.first else { return nil }
        return UserProfileMapper.toDomain(model)
    }

    func saveProfile(_ profile: UserProfile) async throws {
        let context = context()
        var descriptor = FetchDescriptor<SDUserProfile>(
            predicate: #Predicate { $0.id == profile.id }
        )
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.mainGoalRaw = profile.mainGoal.rawValue
            existing.availableStructureRaw = profile.availableStructure.rawValue
            existing.preferredMethodRaw = profile.preferredMethod.rawValue
            existing.levelRaw = profile.level.rawValue
            existing.healthConditionsRaw = profile.healthConditions.map(\.rawValue)
            existing.weeklyFrequency = profile.weeklyFrequency
        } else {
            context.insert(UserProfileMapper.toModel(profile))
        }
        try context.save()
    }
}

