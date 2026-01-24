//
//  ProgramModels.swift
//  FitToday
//
//  Entidade de domínio para "Programas" de treinamento.
//  Um Programa agrupa treinos relacionados e fornece contexto para recomendação.
//

import Foundation

/// Tag de objetivo do programa para classificação e recomendação.
public enum ProgramGoalTag: String, Sendable, Codable, CaseIterable {
    case strength     // Foco em força e hipertrofia
    case conditioning // Foco em HIIT e circuitos metabólicos
    case aerobic      // Foco em cardio e queima calórica
    case core         // Foco em abdominal e estabilidade
    case endurance    // Foco em resistência muscular e stamina
}

/// Nível de dificuldade do programa.
public enum ProgramLevel: String, Sendable, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
    
    var displayName: String {
        switch self {
        case .beginner: return "Iniciante"
        case .intermediate: return "Intermediário"
        case .advanced: return "Avançado"
        }
    }
}

/// Um programa de treinamento que agrupa múltiplos treinos.
public struct Program: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let goalTag: ProgramGoalTag
    public let level: ProgramLevel
    public let durationWeeks: Int
    public let heroImageName: String       // Nome do asset no bundle para imagem de fundo
    public let workoutTemplateIds: [String] // IDs dos LibraryWorkout que compõem o programa
    public let estimatedMinutesPerSession: Int
    public let sessionsPerWeek: Int
    
    public init(
        id: String,
        name: String,
        subtitle: String,
        goalTag: ProgramGoalTag,
        level: ProgramLevel,
        durationWeeks: Int,
        heroImageName: String,
        workoutTemplateIds: [String],
        estimatedMinutesPerSession: Int,
        sessionsPerWeek: Int
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.goalTag = goalTag
        self.level = level
        self.durationWeeks = durationWeeks
        self.heroImageName = heroImageName
        self.workoutTemplateIds = workoutTemplateIds
        self.estimatedMinutesPerSession = estimatedMinutesPerSession
        self.sessionsPerWeek = sessionsPerWeek
    }
    
    /// Número total de treinos no programa.
    public var totalWorkouts: Int {
        workoutTemplateIds.count
    }
    
    /// Descrição curta da duração.
    public var durationDescription: String {
        if durationWeeks == 1 {
            return "1 semana"
        }
        return "\(durationWeeks) semanas"
    }
    
    /// Descrição curta de sessões.
    public var sessionsDescription: String {
        "\(sessionsPerWeek)x por semana"
    }
}

// MARK: - Display Names

extension ProgramGoalTag {
    var displayName: String {
        switch self {
        case .strength: return "programs.category.strength".localized
        case .conditioning: return "programs.category.conditioning".localized
        case .aerobic: return "programs.category.aerobic".localized
        case .core: return "programs.category.wellness".localized
        case .endurance: return "programs.category.endurance".localized
        }
    }

    var iconName: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .conditioning: return "flame.fill"
        case .aerobic: return "figure.run"
        case .core: return "figure.core.training"
        case .endurance: return "heart.fill"
        }
    }
}


