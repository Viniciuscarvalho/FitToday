//
//  LibraryModels.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Um treino fixo da biblioteca Free, sem adaptação diária.
struct LibraryWorkout: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let goal: FitnessGoal
    let structure: TrainingStructure
    let estimatedDurationMinutes: Int
    let intensity: WorkoutIntensity
    let exercises: [ExercisePrescription]
    
    var exerciseCount: Int { exercises.count }
}

/// Filtros disponíveis para a biblioteca.
struct LibraryFilter: Equatable, Sendable {
    var goal: FitnessGoal?
    var structure: TrainingStructure?
    
    static let empty = LibraryFilter()
    
    var isActive: Bool {
        goal != nil || structure != nil
    }
}

/// Extensão para converter LibraryWorkout em WorkoutPlan (para reutilizar execução).
extension LibraryWorkout {
    func toWorkoutPlan() -> WorkoutPlan {
        WorkoutPlan(
            id: UUID(),
            title: title,
            focus: goalToDailyFocus(goal),
            estimatedDurationMinutes: estimatedDurationMinutes,
            intensity: intensity,
            exercises: exercises
        )
    }
    
    private func goalToDailyFocus(_ goal: FitnessGoal) -> DailyFocus {
        switch goal {
        case .hypertrophy, .performance:
            return .fullBody
        case .conditioning, .endurance:
            return .cardio
        case .weightLoss:
            return .fullBody
        }
    }
}


