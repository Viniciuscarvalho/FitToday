//
//  SpecialistSessionRules.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

/// Regras de estrutura de sessão por objetivo, baseadas nos perfis de `personal-active/`
/// Define a organização do treino: aquecimento, principal, acessórios, finalização
struct SpecialistSessionRules: Sendable {
    
    // MARK: - Session Structure
    
    /// Fases do treino com número de exercícios por fase
    struct SessionPhases {
        let warmupExercises: Int
        let mainExercises: Int
        let accessoryExercises: Int
        let finisherExercises: Int
        
        var totalExercises: Int {
            warmupExercises + mainExercises + accessoryExercises + finisherExercises
        }
    }
    
    /// Prescrição padrão por fase
    struct PhasePrescription {
        let setsRange: ClosedRange<Int>
        let repsRange: ClosedRange<Int>
        let restSeconds: Int
        let rpeTarget: Int  // 1-10
    }
    
    /// Grupos musculares prioritários por objetivo
    struct MuscleGroupPriority {
        let primary: [MuscleGroup]
        let secondary: [MuscleGroup]
        let avoid: [MuscleGroup]  // Para DOMS alto
    }
    
    // MARK: - Goal-Specific Rules
    
    enum SessionType {
        case strength       // Força Pura
        case performance    // Performance
        case weightLoss     // Emagrecimento
        case conditioning   // Condicionamento
        case endurance      // Resistência
    }
    
    // MARK: - Static Rules
    
    static func sessionType(for goal: FitnessGoal) -> SessionType {
        switch goal {
        case .hypertrophy: return .strength
        case .performance: return .performance
        case .weightLoss: return .weightLoss
        case .conditioning: return .conditioning
        case .endurance: return .endurance
        }
    }
    
    static func phases(for type: SessionType) -> SessionPhases {
        switch type {
        case .strength:
            // Força Pura: aquecimento + principais pesados + acessórios de suporte
            return SessionPhases(warmupExercises: 1, mainExercises: 3, accessoryExercises: 2, finisherExercises: 0)
        case .performance:
            // Performance: aquecimento + força explosiva + condicionamento
            return SessionPhases(warmupExercises: 1, mainExercises: 2, accessoryExercises: 2, finisherExercises: 1)
        case .weightLoss:
            // Emagrecimento: circuito metabólico + aeróbio
            return SessionPhases(warmupExercises: 1, mainExercises: 3, accessoryExercises: 2, finisherExercises: 1)
        case .conditioning:
            // Condicionamento: força + resistência
            return SessionPhases(warmupExercises: 1, mainExercises: 3, accessoryExercises: 2, finisherExercises: 1)
        case .endurance:
            // Resistência: volume alto, múltiplos exercícios
            return SessionPhases(warmupExercises: 1, mainExercises: 3, accessoryExercises: 2, finisherExercises: 1)
        }
    }
    
    static func mainPrescription(for type: SessionType) -> PhasePrescription {
        switch type {
        case .strength:
            // 1-6 reps, descanso longo 2-5min, RPE 7-9
            return PhasePrescription(setsRange: 3...5, repsRange: 1...6, restSeconds: 180, rpeTarget: 8)
        case .performance:
            // Movimentos rápidos, baixo volume
            return PhasePrescription(setsRange: 3...4, repsRange: 3...8, restSeconds: 120, rpeTarget: 7)
        case .weightLoss:
            // Volume moderado, intervalos curtos, RPE 6-8
            return PhasePrescription(setsRange: 3...4, repsRange: 10...15, restSeconds: 45, rpeTarget: 7)
        case .conditioning:
            // Intensidade moderada, RPE 6-7
            return PhasePrescription(setsRange: 3...4, repsRange: 10...15, restSeconds: 60, rpeTarget: 6)
        case .endurance:
            // Alto volume, descanso curto
            return PhasePrescription(setsRange: 2...4, repsRange: 15...25, restSeconds: 30, rpeTarget: 6)
        }
    }
    
    static func accessoryPrescription(for type: SessionType) -> PhasePrescription {
        switch type {
        case .strength:
            // Acessórios de suporte e estabilidade
            return PhasePrescription(setsRange: 2...3, repsRange: 8...12, restSeconds: 90, rpeTarget: 6)
        case .performance:
            return PhasePrescription(setsRange: 2...3, repsRange: 8...12, restSeconds: 60, rpeTarget: 6)
        case .weightLoss:
            return PhasePrescription(setsRange: 2...3, repsRange: 12...18, restSeconds: 30, rpeTarget: 6)
        case .conditioning:
            return PhasePrescription(setsRange: 2...3, repsRange: 12...15, restSeconds: 45, rpeTarget: 5)
        case .endurance:
            return PhasePrescription(setsRange: 2...3, repsRange: 15...20, restSeconds: 20, rpeTarget: 5)
        }
    }
    
    static func musclePriority(for focus: DailyFocus, goal: FitnessGoal) -> MuscleGroupPriority {
        switch focus {
        case .upper:
            return MuscleGroupPriority(
                primary: [.chest, .back, .shoulders],
                secondary: [.biceps, .triceps, .arms],
                avoid: []
            )
        case .lower:
            return MuscleGroupPriority(
                primary: [.quads, .quadriceps, .glutes, .hamstrings],
                secondary: [.calves, .core],
                avoid: []
            )
        case .fullBody:
            return MuscleGroupPriority(
                primary: [.chest, .back, .quads, .quadriceps],
                secondary: [.shoulders, .glutes, .core],
                avoid: []
            )
        case .cardio:
            return MuscleGroupPriority(
                primary: [.cardioSystem, .fullBody],
                secondary: [.core, .glutes],
                avoid: []
            )
        case .core:
            return MuscleGroupPriority(
                primary: [.core],
                secondary: [.glutes, .back],
                avoid: []
            )
        case .surprise:
            // Variar baseado no objetivo
            let primaryGoal = sessionType(for: goal)
            switch primaryGoal {
            case .strength:
                return MuscleGroupPriority(
                    primary: [.chest, .back, .quads],
                    secondary: [.shoulders, .glutes],
                    avoid: []
                )
            default:
                return MuscleGroupPriority(
                    primary: [.fullBody],
                    secondary: [.core, .glutes],
                    avoid: []
                )
            }
        }
    }
    
    // MARK: - DOMS Adjustment Rules
    
    /// Fatores de ajuste baseados em DOMS (conforme guias personal-active)
    struct DOMSAdjustment {
        let volumeMultiplier: Double      // 1.0 = sem ajuste, 0.7 = -30%
        let intensityReduction: Bool
        let avoidPlyometrics: Bool
        let avoidMuscleFailure: Bool
        let extraRestSeconds: Int
        let substituteHighImpact: Bool
        
        /// DOMS nível 0-3: sem ajuste
        static let none = DOMSAdjustment(
            volumeMultiplier: 1.0,
            intensityReduction: false,
            avoidPlyometrics: false,
            avoidMuscleFailure: false,
            extraRestSeconds: 0,
            substituteHighImpact: false
        )
        
        /// DOMS nível 4-6: ajuste leve
        static let moderate = DOMSAdjustment(
            volumeMultiplier: 0.9,          // -10%
            intensityReduction: false,
            avoidPlyometrics: false,
            avoidMuscleFailure: true,
            extraRestSeconds: 15,
            substituteHighImpact: false
        )
        
        /// DOMS nível 7-10: ajuste significativo
        static let strong = DOMSAdjustment(
            volumeMultiplier: 0.7,          // -30%
            intensityReduction: true,
            avoidPlyometrics: true,
            avoidMuscleFailure: true,
            extraRestSeconds: 30,
            substituteHighImpact: true
        )
        
        static func adjustment(for soreness: MuscleSorenessLevel) -> DOMSAdjustment {
            switch soreness {
            case .none:
                return .none
            case .light:
                return .none
            case .moderate:
                return .moderate
            case .strong:
                return .strong
            }
        }
    }
    
    // MARK: - Session Title Generation
    
    static func sessionTitle(focus: DailyFocus, goal: FitnessGoal, soreness: MuscleSorenessLevel) -> String {
        let prefix: String
        switch focus {
        case .upper: prefix = "Upper"
        case .lower: prefix = "Lower"
        case .fullBody: prefix = "Full Body"
        case .cardio: prefix = "Cardio"
        case .core: prefix = "Core"
        case .surprise: prefix = "Mix"
        }
        
        let suffix: String
        switch sessionType(for: goal) {
        case .strength: suffix = "Força"
        case .performance: suffix = "Performance"
        case .weightLoss: suffix = "Fat Burn"
        case .conditioning: suffix = "Conditioning"
        case .endurance: suffix = "Endurance"
        }
        
        if soreness == .strong {
            return "\(prefix) \(suffix) (Recovery)"
        }
        
        return "\(prefix) \(suffix)"
    }
    
    // MARK: - Intensity Calculation
    
    static func intensity(
        for level: TrainingLevel,
        soreness: MuscleSorenessLevel,
        goal: FitnessGoal
    ) -> WorkoutIntensity {
        // DOMS alto sempre reduz intensidade
        if soreness == .strong {
            return .low
        }
        
        // Avançado sem dor pode ir alto
        if level == .advanced && soreness == .none {
            switch goal {
            case .hypertrophy, .performance:
                return .high
            default:
                return .moderate
            }
        }
        
        // Casos gerais
        if soreness == .moderate {
            return .low
        }
        
        switch goal {
        case .hypertrophy:
            return level == .beginner ? .moderate : .high
        case .performance:
            return .moderate
        case .weightLoss, .conditioning, .endurance:
            return .moderate
        }
    }
}

