//
//  WorkoutPlanValidator.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Validador de planos de treino que aplica regras por objetivo
struct WorkoutPlanValidator: WorkoutPlanValidating, Sendable {
    
    // MARK: - Validation Rules per Goal
    
    private struct ValidationRules {
        let minimumExercises: Int
        let setsRange: ClosedRange<Int>
        let repsRange: ClosedRange<Int>
        let restRange: ClosedRange<TimeInterval>
        let minimumMainExercises: Int
        
        static func rules(for goal: FitnessGoal) -> ValidationRules {
            switch goal {
            case .hypertrophy:
                // Força Pura: baixas reps, descanso longo
                return ValidationRules(
                    minimumExercises: 4,
                    setsRange: 1...8,
                    repsRange: 1...12,
                    restRange: 60...300,  // 1-5 min
                    minimumMainExercises: 2
                )
            case .performance:
                // Performance: força explosiva + condicionamento
                return ValidationRules(
                    minimumExercises: 4,
                    setsRange: 2...6,
                    repsRange: 3...15,
                    restRange: 45...180,  // 45s-3min
                    minimumMainExercises: 2
                )
            case .weightLoss:
                // Emagrecimento: circuitos, intervalos curtos
                return ValidationRules(
                    minimumExercises: 5,
                    setsRange: 2...5,
                    repsRange: 8...20,
                    restRange: 20...90,   // 20s-90s
                    minimumMainExercises: 3
                )
            case .conditioning:
                // Condicionamento: força + resistência
                return ValidationRules(
                    minimumExercises: 5,
                    setsRange: 2...5,
                    repsRange: 8...20,
                    restRange: 30...120,  // 30s-2min
                    minimumMainExercises: 3
                )
            case .endurance:
                // Resistência: volume alto, descanso curto
                return ValidationRules(
                    minimumExercises: 5,
                    setsRange: 2...5,
                    repsRange: 10...30,
                    restRange: 20...60,   // 20s-60s
                    minimumMainExercises: 3
                )
            }
        }
    }
    
    // MARK: - WorkoutPlanValidating
    
    func validate(plan: WorkoutPlan, for goal: FitnessGoal) throws {
        let rules = ValidationRules.rules(for: goal)
        
        // 1. Verificar lista não vazia
        guard !plan.exercises.isEmpty else {
            throw WorkoutPlanValidationError.emptyExercises
        }
        
        // 2. Verificar número mínimo de exercícios
        guard plan.exercises.count >= rules.minimumExercises else {
            throw WorkoutPlanValidationError.insufficientExercises(
                minimum: rules.minimumExercises,
                actual: plan.exercises.count
            )
        }
        
        // 3. Validar cada prescrição
        for prescription in plan.exercises {
            // Sets
            guard rules.setsRange.contains(prescription.sets) else {
                throw WorkoutPlanValidationError.invalidSets(
                    exercise: prescription.exercise.name,
                    sets: prescription.sets
                )
            }
            
            // Reps
            guard rules.repsRange.contains(prescription.reps.lowerBound),
                  rules.repsRange.contains(prescription.reps.upperBound) else {
                throw WorkoutPlanValidationError.invalidReps(
                    exercise: prescription.exercise.name,
                    reps: prescription.reps
                )
            }
            
            // Rest
            guard rules.restRange.contains(prescription.restInterval) else {
                throw WorkoutPlanValidationError.invalidRestInterval(
                    exercise: prescription.exercise.name,
                    rest: prescription.restInterval
                )
            }
        }
        
        // 4. Verificar exercícios principais (multiarticulares)
        let mainMuscles: Set<MuscleGroup> = [.chest, .back, .quads, .quadriceps, .glutes, .shoulders]
        let mainExercisesCount = plan.exercises.filter { mainMuscles.contains($0.exercise.mainMuscle) }.count
        
        guard mainExercisesCount >= rules.minimumMainExercises else {
            throw WorkoutPlanValidationError.missingMainExercises
        }
    }
}

// MARK: - Validation Extensions

extension WorkoutPlanValidator {
    /// Tenta corrigir um plano inválido ajustando valores fora dos limites
    func sanitize(plan: WorkoutPlan, for goal: FitnessGoal) -> WorkoutPlan {
        let rules = ValidationRules.rules(for: goal)
        
        let sanitizedExercises = plan.exercises.map { prescription in
            let sanitizedSets = min(max(prescription.sets, rules.setsRange.lowerBound), rules.setsRange.upperBound)
            
            let sanitizedLower = min(max(prescription.reps.lowerBound, rules.repsRange.lowerBound), rules.repsRange.upperBound)
            let sanitizedUpper = min(max(prescription.reps.upperBound, rules.repsRange.lowerBound), rules.repsRange.upperBound)
            let sanitizedReps = IntRange(min(sanitizedLower, sanitizedUpper), max(sanitizedLower, sanitizedUpper))
            
            let sanitizedRest = min(max(prescription.restInterval, rules.restRange.lowerBound), rules.restRange.upperBound)
            
            return ExercisePrescription(
                exercise: prescription.exercise,
                sets: sanitizedSets,
                reps: sanitizedReps,
                restInterval: sanitizedRest,
                tip: prescription.tip
            )
        }
        
        return WorkoutPlan(
            id: plan.id,
            title: plan.title,
            focus: plan.focus,
            estimatedDurationMinutes: plan.estimatedDurationMinutes,
            intensity: plan.intensity,
            exercises: sanitizedExercises
        )
    }
}

