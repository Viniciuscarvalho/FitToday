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
        case .beginner: return NSLocalizedString("programs.level.beginner", comment: "Beginner level")
        case .intermediate: return NSLocalizedString("programs.level.intermediate", comment: "Intermediate level")
        case .advanced: return NSLocalizedString("programs.level.advanced", comment: "Advanced level")
        }
    }
}

/// Tipo de equipamento necessário para o programa.
public enum ProgramEquipment: String, Sendable, Codable, CaseIterable {
    case gym        // Academia completa
    case home       // Casa (equipamentos básicos)
    case dumbbell   // Apenas halteres
    case bodyweight // Sem equipamento (peso corporal)
    case kettlebell // Kettlebell
    case bands      // Elásticos

    var displayName: String {
        switch self {
        case .gym: return NSLocalizedString("programs.equipment.gym", comment: "Gym equipment")
        case .home: return NSLocalizedString("programs.equipment.home", comment: "Home equipment")
        case .dumbbell: return NSLocalizedString("programs.equipment.dumbbell", comment: "Dumbbell equipment")
        case .bodyweight: return NSLocalizedString("programs.equipment.bodyweight", comment: "Bodyweight")
        case .kettlebell: return NSLocalizedString("programs.equipment.kettlebell", comment: "Kettlebell")
        case .bands: return NSLocalizedString("programs.equipment.bands", comment: "Bands")
        }
    }

    var iconName: String {
        switch self {
        case .gym: return "building.2.fill"
        case .home: return "house.fill"
        case .dumbbell: return "dumbbell.fill"
        case .bodyweight: return "figure.stand"
        case .kettlebell: return "figure.strengthtraining.functional"
        case .bands: return "figure.flexibility"
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
    public let equipment: ProgramEquipment
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
        equipment: ProgramEquipment = .gym,
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
        self.equipment = equipment
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
        case .strength: return NSLocalizedString("programs.category.strength", comment: "Strength goal")
        case .conditioning: return NSLocalizedString("programs.category.conditioning", comment: "Conditioning goal")
        case .aerobic: return NSLocalizedString("programs.category.aerobic", comment: "Aerobic goal")
        case .core: return NSLocalizedString("programs.category.wellness", comment: "Core/wellness goal")
        case .endurance: return NSLocalizedString("programs.category.endurance", comment: "Endurance goal")
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


