//
//  WorkoutPlanValidating.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Erros de validação do plano de treino
enum WorkoutPlanValidationError: Error, LocalizedError {
    case emptyExercises
    case insufficientExercises(minimum: Int, actual: Int)
    case invalidSets(exercise: String, sets: Int)
    case invalidReps(exercise: String, reps: IntRange)
    case invalidRestInterval(exercise: String, rest: TimeInterval)
    case missingMainExercises
    case inconsistentIntensity
    
    var errorDescription: String? {
        switch self {
        case .emptyExercises:
            return "O plano não contém exercícios"
        case .insufficientExercises(let min, let actual):
            return "Plano deve ter pelo menos \(min) exercícios, mas tem \(actual)"
        case .invalidSets(let exercise, let sets):
            return "Exercício '\(exercise)' tem séries inválidas: \(sets)"
        case .invalidReps(let exercise, let reps):
            return "Exercício '\(exercise)' tem repetições inválidas: \(reps.display)"
        case .invalidRestInterval(let exercise, let rest):
            return "Exercício '\(exercise)' tem descanso inválido: \(Int(rest))s"
        case .missingMainExercises:
            return "O plano não contém exercícios principais suficientes"
        case .inconsistentIntensity:
            return "A intensidade do plano é inconsistente com a prescrição"
        }
    }
}

/// Protocolo para validação de planos de treino
protocol WorkoutPlanValidating: Sendable {
    /// Valida um plano de treino e lança erro se inválido
    func validate(plan: WorkoutPlan, for goal: FitnessGoal) throws
    
    /// Retorna true se o plano é válido
    func isValid(plan: WorkoutPlan, for goal: FitnessGoal) -> Bool
}

// MARK: - Default Implementation

extension WorkoutPlanValidating {
    func isValid(plan: WorkoutPlan, for goal: FitnessGoal) -> Bool {
        do {
            try validate(plan: plan, for: goal)
            return true
        } catch {
            return false
        }
    }
}


