//
//  UserProfileMapper.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

struct UserProfileMapper {
    static func toDomain(_ model: SDUserProfile) -> UserProfile? {
        guard
            let goal = FitnessGoal(rawValue: model.mainGoalRaw),
            let structure = TrainingStructure(rawValue: model.availableStructureRaw),
            let method = TrainingMethod(rawValue: model.preferredMethodRaw),
            let level = TrainingLevel(rawValue: model.levelRaw)
        else { return nil }

        let conditions = model.healthConditionsRaw.compactMap(HealthCondition.init(rawValue:))

        return UserProfile(
            id: model.id,
            mainGoal: goal,
            availableStructure: structure,
            preferredMethod: method,
            level: level,
            healthConditions: conditions.isEmpty ? [.none] : conditions,
            weeklyFrequency: model.weeklyFrequency,
            createdAt: model.createdAt,
            isProfileComplete: model.isProfileComplete
        )
    }

    static func toModel(_ profile: UserProfile) -> SDUserProfile {
        SDUserProfile(
            id: profile.id,
            mainGoalRaw: profile.mainGoal.rawValue,
            availableStructureRaw: profile.availableStructure.rawValue,
            preferredMethodRaw: profile.preferredMethod.rawValue,
            levelRaw: profile.level.rawValue,
            healthConditionsRaw: profile.healthConditions.map(\.rawValue),
            weeklyFrequency: profile.weeklyFrequency,
            createdAt: profile.createdAt,
            isProfileComplete: profile.isProfileComplete
        )
    }
}

