//
//  WorkoutTemplateType.swift
//  FitToday
//
//  Tipo de template de treino para mapeamento com categorias de exercício.
//

import Foundation

/// Tipo de template de treino para mapeamento com categorias de exercício.
/// Usado para determinar quais exercícios buscar baseado no tipo de treino.
enum WorkoutTemplateType: String, CaseIterable, Sendable {
    case push
    case pull
    case legs
    case fullbody
    case core
    case hiit
    case upper
    case lower
    case conditioning
    // Bro Split specific
    case chest
    case back
    case shoulders
    case arms
    // Strength focused
    case strength
    // Glute focused
    case glutes

    /// Nomes das categorias no Firestore correspondentes a este tipo de treino.
    var categoryNames: [String] {
        switch self {
        case .push:
            return ["chest", "shoulders", "triceps"]
        case .pull:
            return ["back", "biceps"]
        case .legs:
            return ["legs", "quads", "hamstrings", "calves"]
        case .fullbody:
            return ["chest", "back", "legs", "shoulders", "core"]
        case .core:
            return ["core"]
        case .hiit, .conditioning:
            return ["chest", "legs", "core"]
        case .upper:
            return ["chest", "back", "shoulders", "biceps", "triceps"]
        case .lower:
            return ["legs", "quads", "hamstrings", "calves"]
        case .chest:
            return ["chest"]
        case .back:
            return ["back"]
        case .shoulders:
            return ["shoulders"]
        case .arms:
            return ["biceps", "triceps"]
        case .strength:
            return ["chest", "back", "legs"]
        case .glutes:
            return ["glutes", "legs"]
        }
    }

    /// Nome de exibição em português para o tipo de treino.
    var displayName: String {
        switch self {
        case .push: return "Push (Empurrar)"
        case .pull: return "Pull (Puxar)"
        case .legs: return "Pernas"
        case .fullbody: return "Corpo Inteiro"
        case .core: return "Core e Abdômen"
        case .hiit: return "HIIT"
        case .upper: return "Superior"
        case .lower: return "Inferior"
        case .conditioning: return "Condicionamento"
        case .chest: return "Peito"
        case .back: return "Costas"
        case .shoulders: return "Ombros"
        case .arms: return "Braços"
        case .strength: return "Força"
        case .glutes: return "Glúteos"
        }
    }

    /// Subtítulo descritivo dos grupos musculares trabalhados.
    var muscleGroupsDescription: String {
        switch self {
        case .push: return "Peito, Ombros e Tríceps"
        case .pull: return "Costas e Bíceps"
        case .legs: return "Quadríceps, Glúteos e Panturrilha"
        case .fullbody: return "Todos os grupos musculares"
        case .core: return "Abdômen e estabilizadores"
        case .hiit: return "Cardio e exercícios compostos"
        case .upper: return "Toda parte superior"
        case .lower: return "Toda parte inferior"
        case .conditioning: return "Resistência e queima"
        case .chest: return "Peitoral maior e menor"
        case .back: return "Dorsais, trapézio e lombar"
        case .shoulders: return "Deltoides anterior, lateral e posterior"
        case .arms: return "Bíceps e tríceps"
        case .strength: return "Movimentos compostos de força"
        case .glutes: return "Glúteos máximo, médio e mínimo"
        }
    }

    /// Extrai o tipo de template a partir do ID do template.
    /// Ex: "lib_push_beginner_gym" -> .push
    static func from(templateId: String) -> WorkoutTemplateType? {
        let lowered = templateId.lowercased()

        // Ordem importa: mais específicos primeiro
        if lowered.contains("fullbody") || lowered.contains("full_body") {
            return .fullbody
        }
        if lowered.contains("hiit") {
            return .hiit
        }
        if lowered.contains("conditioning") {
            return .conditioning
        }
        if lowered.contains("core") {
            return .core
        }
        if lowered.contains("upper") {
            return .upper
        }
        if lowered.contains("lower") {
            return .lower
        }
        if lowered.contains("push") {
            return .push
        }
        if lowered.contains("pull") {
            return .pull
        }
        if lowered.contains("legs") || lowered.contains("leg") {
            return .legs
        }
        // Bro Split specific
        if lowered.contains("chest") {
            return .chest
        }
        if lowered.contains("back") {
            return .back
        }
        if lowered.contains("shoulders") || lowered.contains("shoulder") {
            return .shoulders
        }
        if lowered.contains("arms") || lowered.contains("arm") {
            return .arms
        }
        if lowered.contains("strength") {
            return .strength
        }
        if lowered.contains("glutes") || lowered.contains("glute") {
            return .glutes
        }

        // Fallback para fullbody se não conseguir determinar
        return .fullbody
    }
}
