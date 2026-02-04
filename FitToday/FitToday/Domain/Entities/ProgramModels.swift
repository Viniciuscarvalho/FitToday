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

/// Categoria de agrupamento visual de programas.
public enum ProgramCategory: String, CaseIterable, Sendable {
    case pushPullLegs
    case fullBody
    case upperLower
    case specialized
    case fatLoss
    case homeWorkout

    var displayName: String {
        switch self {
        case .pushPullLegs: return "Push Pull Legs"
        case .fullBody: return "Full Body"
        case .upperLower: return "Upper Lower"
        case .specialized: return "Especializados"
        case .fatLoss: return "Emagrecimento"
        case .homeWorkout: return "Treino em Casa"
        }
    }

    var sortOrder: Int {
        switch self {
        case .pushPullLegs: return 0
        case .fullBody: return 1
        case .upperLower: return 2
        case .specialized: return 3
        case .fatLoss: return 4
        case .homeWorkout: return 5
        }
    }
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

    /// Categoria visual inferida do ID e nome do programa.
    public var category: ProgramCategory {
        let lowerId = id.lowercased()
        let lowerName = name.lowercased()

        // Push Pull Legs
        if lowerId.contains("ppl") || lowerName.contains("push pull") {
            return .pushPullLegs
        }

        // Home workout
        if lowerId.contains("home") || equipment == .bodyweight || lowerName.contains("calistenia") {
            return .homeWorkout
        }

        // Fat loss / conditioning programs
        if lowerId.contains("weightloss") || lowerId.contains("hiit") ||
           lowerName.contains("hiit") || lowerName.contains("queima") ||
           lowerName.contains("metabolic") || lowerName.contains("fat burn") {
            return .fatLoss
        }

        // Upper Lower
        if lowerId.contains("upperlower") || lowerName.contains("upper lower") {
            return .upperLower
        }

        // Full Body
        if lowerId.contains("fullbody") || lowerName.contains("full body") ||
           lowerName.contains("minimalista") || lowerId.contains("beginner_complete") {
            return .fullBody
        }

        // Specialized (Arnold, PHUL, Bro Split, Functional, Glute-focused, Strength-focused)
        if lowerId.contains("arnold") || lowerId.contains("phul") ||
           lowerId.contains("brosplit") || lowerId.contains("strength_") ||
           lowerId.contains("glute") || lowerId.contains("functional") ||
           lowerName.contains("arnold") || lowerName.contains("phul") ||
           lowerName.contains("bro split") || lowerName.contains("5x5") ||
           lowerName.contains("fundamentos") || lowerName.contains("glúteos") ||
           lowerName.contains("funcional") {
            return .specialized
        }

        // Default to full body for general programs
        return .fullBody
    }

    /// Nome curto para exibição em cards.
    public var shortName: String {
        // Remove prefixes comuns para deixar o nome mais curto
        let cleanName = name
            .replacingOccurrences(of: "Push Pull Legs", with: "PPL")
            .replacingOccurrences(of: "Upper Lower", with: "UL")
            .replacingOccurrences(of: "Full Body", with: "FB")

        // Limita a 15 caracteres se ainda for muito longo
        if cleanName.count > 15 {
            return String(cleanName.prefix(12)) + "..."
        }
        return cleanName
    }
}

// MARK: - Display Names

extension ProgramGoalTag {
    var displayName: String {
        switch self {
        case .strength: return NSLocalizedString("programs.goal.strength", comment: "Strength goal")
        case .conditioning: return NSLocalizedString("programs.goal.conditioning", comment: "Conditioning goal")
        case .aerobic: return NSLocalizedString("programs.goal.aerobic", comment: "Aerobic goal")
        case .core: return NSLocalizedString("programs.goal.core", comment: "Core/wellness goal")
        case .endurance: return NSLocalizedString("programs.goal.endurance", comment: "Endurance goal")
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


