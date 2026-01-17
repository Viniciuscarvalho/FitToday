//
//  OnboardingDisplayHelpers.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import Foundation

// MARK: - SetupStep

enum SetupStep: Int, CaseIterable {
    case goal, structure, method, level, health, frequency

    var title: String {
        switch self {
        case .goal: return "Qual é seu objetivo principal?"
        case .structure: return "Onde você treina?"
        case .method: return "Qual metodologia prefere?"
        case .level: return "Qual seu nível atual?"
        case .health: return "Alguma condição ou dor?"
        case .frequency: return "Quantos dias por semana você treina?"
        }
    }
}

// MARK: - FitnessGoal Extensions

extension FitnessGoal {
    var title: String {
        switch self {
        case .hypertrophy: return "Hipertrofia"
        case .conditioning: return "Condicionamento"
        case .endurance: return "Resistência"
        case .weightLoss: return "Emagrecimento"
        case .performance: return "Performance"
        }
    }
    var subtitle: String {
        switch self {
        case .hypertrophy: return "Ganhe massa muscular"
        case .conditioning: return "Melhore o fôlego diário"
        case .endurance: return "Aumente resistência"
        case .weightLoss: return "Defina e reduza gordura"
        case .performance: return "Otimize performance esportiva"
        }
    }
}

// MARK: - TrainingStructure Extensions

extension TrainingStructure {
    var title: String {
        switch self {
        case .fullGym: return "Academia completa"
        case .basicGym: return "Academia básica"
        case .homeDumbbells: return "Casa (halteres)"
        case .bodyweight: return "Peso corporal"
        }
    }
    var subtitle: String? {
        switch self {
        case .fullGym: return "Máquinas + pesos livres"
        case .basicGym: return "Equipamentos essenciais"
        case .homeDumbbells: return "Até 2 pares de halteres"
        case .bodyweight: return "Sem equipamentos"
        }
    }
}

// MARK: - TrainingMethod Extensions

extension TrainingMethod {
    var title: String {
        switch self {
        case .traditional: return "Tradicional"
        case .circuit: return "Circuito"
        case .hiit: return "HIIT"
        case .mixed: return "Misto"
        }
    }
    var subtitle: String? {
        switch self {
        case .traditional: return "Séries e repetições"
        case .circuit: return "Blocos em sequência"
        case .hiit: return "Intervalos intensos"
        case .mixed: return "Combinação equilibrada"
        }
    }
}

// MARK: - TrainingLevel Extensions

extension TrainingLevel {
    var title: String {
        switch self {
        case .beginner: return "Iniciante"
        case .intermediate: return "Intermediário"
        case .advanced: return "Avançado"
        }
    }
    var subtitle: String? {
        switch self {
        case .beginner: return "Até 6 meses treinando"
        case .intermediate: return "Entre 6 meses e 2 anos"
        case .advanced: return "2+ anos consistentes"
        }
    }
}

// MARK: - HealthCondition Extensions

extension HealthCondition {
    var title: String {
        switch self {
        case .none: return "Nenhuma"
        case .lowerBackPain: return "Dor lombar"
        case .knee: return "Joelho"
        case .shoulder: return "Ombro"
        case .other: return "Outra"
        }
    }
    var subtitle: String? {
        switch self {
        case .none: return "Tudo bem por aqui"
        case .lowerBackPain: return "Adaptações para coluna"
        case .knee: return "Proteja os joelhos"
        case .shoulder: return "Cuidados em empurrar/puxar"
        case .other: return "Tratamos com menor volume"
        }
    }
}
