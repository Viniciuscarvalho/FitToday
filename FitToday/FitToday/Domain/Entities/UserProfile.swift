//
//  UserProfile.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

enum FitnessGoal: String, Codable, CaseIterable, Sendable {
    case hypertrophy
    case conditioning
    case endurance
    case weightLoss
    case performance
}

enum TrainingStructure: String, Codable, CaseIterable, Sendable {
    case fullGym
    case basicGym
    case homeDumbbells
    case bodyweight
}

enum TrainingMethod: String, Codable, CaseIterable, Sendable {
    case traditional
    case circuit
    case hiit
    case mixed
}

enum TrainingLevel: String, Codable, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced
}

enum HealthCondition: String, Codable, CaseIterable, Sendable {
    case none
    case lowerBackPain
    case knee
    case shoulder
    case other
}

struct UserProfile: Codable, Hashable, Sendable {
    var id: UUID
    var mainGoal: FitnessGoal
    var availableStructure: TrainingStructure
    var preferredMethod: TrainingMethod
    var level: TrainingLevel
    var healthConditions: [HealthCondition]
    var weeklyFrequency: Int
    var createdAt: Date
    var isProfileComplete: Bool // Indica se perfil foi preenchido completamente ou usa defaults

    init(
        id: UUID = .init(),
        mainGoal: FitnessGoal,
        availableStructure: TrainingStructure,
        preferredMethod: TrainingMethod,
        level: TrainingLevel,
        healthConditions: [HealthCondition],
        weeklyFrequency: Int,
        createdAt: Date = .init(),
        isProfileComplete: Bool = true
    ) {
        self.id = id
        self.mainGoal = mainGoal
        self.availableStructure = availableStructure
        self.preferredMethod = preferredMethod
        self.level = level
        self.healthConditions = healthConditions
        self.weeklyFrequency = max(1, weeklyFrequency)
        self.createdAt = createdAt
        self.isProfileComplete = isProfileComplete
    }
}



