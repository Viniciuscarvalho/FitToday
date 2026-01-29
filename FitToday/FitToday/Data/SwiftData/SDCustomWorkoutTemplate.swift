//
//  SDCustomWorkoutTemplate.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation
import SwiftData

// MARK: - SDCustomWorkoutTemplate

@Model
final class SDCustomWorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var exercisesData: Data // JSON encoded [CustomExerciseEntry]
    var createdAt: Date
    var lastUsedAt: Date?
    var workoutDescription: String?
    var category: String?

    init(
        id: UUID,
        name: String,
        exercisesData: Data,
        createdAt: Date,
        lastUsedAt: Date?,
        workoutDescription: String?,
        category: String?
    ) {
        self.id = id
        self.name = name
        self.exercisesData = exercisesData
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.workoutDescription = workoutDescription
        self.category = category
    }

    convenience init(from domain: CustomWorkoutTemplate) {
        let encoder = JSONEncoder()
        let exercisesData = (try? encoder.encode(domain.exercises)) ?? Data()

        self.init(
            id: domain.id,
            name: domain.name,
            exercisesData: exercisesData,
            createdAt: domain.createdAt,
            lastUsedAt: domain.lastUsedAt,
            workoutDescription: domain.workoutDescription,
            category: domain.category
        )
    }

    func toDomain() -> CustomWorkoutTemplate {
        let decoder = JSONDecoder()
        let exercises = (try? decoder.decode([CustomExerciseEntry].self, from: exercisesData)) ?? []

        return CustomWorkoutTemplate(
            id: id,
            name: name,
            exercises: exercises,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            workoutDescription: workoutDescription,
            category: category
        )
    }
}

// MARK: - SDCustomWorkoutCompletion

@Model
final class SDCustomWorkoutCompletion {
    @Attribute(.unique) var id: UUID
    var templateId: UUID
    var completedAt: Date
    var durationMinutes: Int
    var exercisesData: Data // JSON encoded [CustomExerciseEntry]

    init(
        id: UUID,
        templateId: UUID,
        completedAt: Date,
        durationMinutes: Int,
        exercisesData: Data
    ) {
        self.id = id
        self.templateId = templateId
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
        self.exercisesData = exercisesData
    }

    convenience init(from domain: CustomWorkoutCompletion) {
        let encoder = JSONEncoder()
        let exercisesData = (try? encoder.encode(domain.exercises)) ?? Data()

        self.init(
            id: domain.id,
            templateId: domain.templateId,
            completedAt: domain.completedAt,
            durationMinutes: domain.durationMinutes,
            exercisesData: exercisesData
        )
    }

    func toDomain() -> CustomWorkoutCompletion {
        let decoder = JSONDecoder()
        let exercises = (try? decoder.decode([CustomExerciseEntry].self, from: exercisesData)) ?? []

        return CustomWorkoutCompletion(
            id: id,
            templateId: templateId,
            completedAt: completedAt,
            durationMinutes: durationMinutes,
            exercises: exercises
        )
    }
}
