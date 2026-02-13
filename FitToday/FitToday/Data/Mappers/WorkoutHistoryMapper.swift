//
//  WorkoutHistoryMapper.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

struct WorkoutHistoryMapper {
    static func toDomain(_ model: SDWorkoutHistoryEntry) -> WorkoutHistoryEntry? {
        guard
            let focus = DailyFocus(rawValue: model.focusRaw),
            let status = WorkoutStatus(rawValue: model.statusRaw)
        else { return nil }
        
        // Decodificar WorkoutPlan se houver
        var workoutPlan: WorkoutPlan? = nil
        if let jsonData = model.workoutPlanJSON {
            workoutPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: jsonData)
        }

        // Decodificar lista de exercícios completados
        var completedExercises: [CompletedExercise]? = nil
        if let exercisesData = model.completedExercisesJSON {
            completedExercises = try? JSONDecoder().decode([CompletedExercise].self, from: exercisesData)
        }

        // Converter userRating string para enum
        let userRating = WorkoutRating(rawString: model.userRating)

        // Converter source string para enum (fallback para .app)
        let source = WorkoutSource(rawValue: model.sourceRaw) ?? .app

        return WorkoutHistoryEntry(
            id: model.id,
            date: model.date,
            planId: model.planId,
            title: model.title,
            focus: focus,
            status: status,
            programId: model.programId,
            programName: model.programName,
            durationMinutes: model.durationMinutes,
            caloriesBurned: model.caloriesBurned,
            healthKitWorkoutUUID: model.healthKitWorkoutUUID,
            workoutPlan: workoutPlan,
            userRating: userRating,
            completedExercises: completedExercises,
            source: source
        )
    }

    static func toModel(_ entry: WorkoutHistoryEntry) -> SDWorkoutHistoryEntry {
        // Serializar WorkoutPlan se houver
        var workoutPlanJSON: Data? = nil
        if let plan = entry.workoutPlan {
            workoutPlanJSON = try? JSONEncoder().encode(plan)
        }

        // Serializar lista de exercícios completados
        var completedExercisesJSON: Data? = nil
        if let exercises = entry.completedExercises {
            completedExercisesJSON = try? JSONEncoder().encode(exercises)
        }

        return SDWorkoutHistoryEntry(
            id: entry.id,
            date: entry.date,
            planId: entry.planId,
            title: entry.title,
            focusRaw: entry.focus.rawValue,
            statusRaw: entry.status.rawValue,
            programId: entry.programId,
            programName: entry.programName,
            durationMinutes: entry.durationMinutes,
            caloriesBurned: entry.caloriesBurned,
            healthKitWorkoutUUID: entry.healthKitWorkoutUUID,
            workoutPlanJSON: workoutPlanJSON,
            userRating: entry.userRating?.rawValue,
            completedExercisesJSON: completedExercisesJSON,
            sourceRaw: entry.source.rawValue
        )
    }
}




