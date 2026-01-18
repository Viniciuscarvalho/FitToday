//
//  HistoryModels.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

enum WorkoutStatus: String, Codable, CaseIterable, Sendable {
    case completed
    case skipped
}

struct WorkoutHistoryEntry: Codable, Hashable, Sendable, Identifiable {
    var id: UUID
    var date: Date
    var planId: UUID
    var title: String
    var focus: DailyFocus
    var status: WorkoutStatus
    
    // Novos campos para evolução e vínculo com programa
    var programId: String?        // ID do programa (se atrelado a um)
    var programName: String?      // Nome do programa para exibição
    var durationMinutes: Int?     // Duração real do treino em minutos
    var caloriesBurned: Int?      // Calorias estimadas queimadas
    
    // Integração HealthKit (iPhone)
    var healthKitWorkoutUUID: UUID?
    
    // WorkoutPlan completo (para histórico de variação)
    var workoutPlan: WorkoutPlan?

    // User feedback sobre o treino (Task 1.0 - Workout Quality Optimization)
    var userRating: WorkoutRating?

    // Lista de exercícios completados
    var completedExercises: [CompletedExercise]?

    init(
        id: UUID = .init(),
        date: Date = .init(),
        planId: UUID,
        title: String,
        focus: DailyFocus,
        status: WorkoutStatus,
        programId: String? = nil,
        programName: String? = nil,
        durationMinutes: Int? = nil,
        caloriesBurned: Int? = nil,
        healthKitWorkoutUUID: UUID? = nil,
        workoutPlan: WorkoutPlan? = nil,
        userRating: WorkoutRating? = nil,
        completedExercises: [CompletedExercise]? = nil
    ) {
        self.id = id
        self.date = date
        self.planId = planId
        self.title = title
        self.focus = focus
        self.status = status
        self.programId = programId
        self.programName = programName
        self.durationMinutes = durationMinutes
        self.caloriesBurned = caloriesBurned
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
        self.workoutPlan = workoutPlan
        self.userRating = userRating
        self.completedExercises = completedExercises
    }
}

struct WorkoutSession: Codable, Hashable, Sendable {
    var id: UUID
    var plan: WorkoutPlan
    var startedAt: Date

    init(id: UUID = .init(), plan: WorkoutPlan, startedAt: Date = .init()) {
        self.id = id
        self.plan = plan
        self.startedAt = startedAt
    }
}




