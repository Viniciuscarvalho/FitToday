//
//  WorkoutDisplayHelpers.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

extension WorkoutPlan {
    var focusDescription: String {
        switch focus {
        case .upper: return "Foco em membros superiores"
        case .lower: return "Foco em membros inferiores"
        case .cardio: return "Condicionamento e cardio"
        case .core: return "Core e estabilidade"
        case .fullBody: return "Corpo inteiro equilibrado"
        case .surprise: return "Treino surpresa"
        }
    }
}

extension WorkoutIntensity {
    var displayTitle: String {
        switch self {
        case .low: return "Baixa intensidade"
        case .moderate: return "Intensidade moderada"
        case .high: return "Alta intensidade"
        }
    }
}

extension MuscleGroup {
    var displayTitle: String {
        switch self {
        case .chest: return "Peito"
        case .back: return "Costas"
        case .shoulders: return "Ombros"
        case .arms: return "Braços"
        case .biceps: return "Bíceps"
        case .triceps: return "Tríceps"
        case .core: return "Core"
        case .glutes: return "Glúteos"
        case .quads: return "Quadríceps"
        case .quadriceps: return "Quadríceps"
        case .hamstrings: return "Posteriores"
        case .calves: return "Panturrilhas"
        case .cardioSystem: return "Cardio"
        case .fullBody: return "Corpo inteiro"
        }
    }
}

extension EquipmentType {
    var displayName: String {
        switch self {
        case .barbell: return "Barra"
        case .dumbbell: return "Halteres"
        case .machine: return "Máquina"
        case .kettlebell: return "Kettlebell"
        case .bodyweight: return "Peso Corporal"
        case .resistanceBand: return "Elástico"
        case .cardioMachine: return "Cardio"
        case .cable: return "Cabo"
        case .pullupBar: return "Barra Fixa"
        }
    }
}

