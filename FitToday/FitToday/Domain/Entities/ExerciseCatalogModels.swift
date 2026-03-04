//
//  ExerciseCatalogModels.swift
//  FitToday
//
//  Category, equipment, and language mappings for the exercise catalog.
//  Mappings for the exercise catalog used by Firestore data source.
//

import Foundation

// MARK: - HTML Stripping Helper

extension String {
    /// Remove tags HTML e converte entidades HTML para texto limpo.
    nonisolated var strippingHTML: String {
        var result = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        let htmlEntities: [String: String] = [
            "&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&apos;": "'", "&#39;": "'",
            "&ndash;": "–", "&mdash;": "—", "&bull;": "•", "&hellip;": "…",
            "&copy;": "©", "&reg;": "®", "&trade;": "™",
            "&euro;": "€", "&pound;": "£", "&yen;": "¥",
            "&deg;": "°", "&plusmn;": "±", "&times;": "×", "&divide;": "÷",
            "&frac12;": "½", "&frac14;": "¼", "&frac34;": "¾"
        ]

        for (entity, replacement) in htmlEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Exercise Category Mapping

/// Maps category names to human-readable names.
enum ExerciseCategoryMapping: String, CaseIterable, Sendable {
    case arms
    case legs
    case abs = "core"
    case chest
    case back
    case shoulders
    case calves
    case cardio = "cardioSystem"
    case biceps
    case triceps
    case quads
    case hamstrings
    case glutes
    case lats
    case middleBack

    var englishName: String {
        switch self {
        case .arms: return "Arms"
        case .legs: return "Legs"
        case .abs: return "Abs"
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .calves: return "Calves"
        case .cardio: return "Cardio"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .lats: return "Lats"
        case .middleBack: return "Middle Back"
        }
    }

    var portugueseName: String {
        switch self {
        case .arms: return "Braços"
        case .legs: return "Pernas"
        case .abs: return "Abdômen"
        case .chest: return "Peito"
        case .back: return "Costas"
        case .shoulders: return "Ombros"
        case .calves: return "Panturrilhas"
        case .cardio: return "Cardio"
        case .biceps: return "Bíceps"
        case .triceps: return "Tríceps"
        case .quads: return "Quadríceps"
        case .hamstrings: return "Posteriores"
        case .glutes: return "Glúteos"
        case .lats: return "Dorsais"
        case .middleBack: return "Meio das Costas"
        }
    }

    var icon: String {
        switch self {
        case .arms, .biceps, .triceps: return "figure.boxing"
        case .legs, .quads, .hamstrings, .calves: return "figure.run"
        case .abs: return "figure.core.training"
        case .chest: return "figure.strengthtraining.traditional"
        case .back, .lats, .middleBack: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .cardio: return "heart.fill"
        case .glutes: return "figure.run"
        }
    }

    var muscleGroup: MuscleGroup {
        switch self {
        case .arms: return .arms
        case .legs: return .quadriceps
        case .abs: return .core
        case .chest: return .chest
        case .back, .lats, .middleBack: return .back
        case .shoulders: return .shoulders
        case .calves: return .calves
        case .cardio: return .cardioSystem
        case .biceps: return .biceps
        case .triceps: return .triceps
        case .quads: return .quads
        case .hamstrings: return .hamstrings
        case .glutes: return .glutes
        }
    }

    static func from(name: String) -> ExerciseCategoryMapping? {
        ExerciseCategoryMapping(rawValue: name)
    }

    static func localizedName(for name: String, language: String = "pt") -> String {
        guard let category = ExerciseCategoryMapping(rawValue: name) else {
            return "Outro"
        }
        return language == "pt" ? category.portugueseName : category.englishName
    }
}

// MARK: - Exercise Equipment Mapping

/// Maps equipment IDs to human-readable names.
enum ExerciseEquipmentMapping: Int, CaseIterable, Sendable {
    case barbell = 1
    case szBar = 2
    case dumbbell = 3
    case gymMat = 4
    case swissBall = 5
    case pullUpBar = 6
    case bodyweight = 7
    case bench = 8
    case inclineBench = 9
    case kettlebell = 10

    var englishName: String {
        switch self {
        case .barbell: return "Barbell"
        case .szBar: return "SZ-Bar"
        case .dumbbell: return "Dumbbell"
        case .gymMat: return "Gym Mat"
        case .swissBall: return "Swiss Ball"
        case .pullUpBar: return "Pull-up Bar"
        case .bodyweight: return "Bodyweight"
        case .bench: return "Bench"
        case .inclineBench: return "Incline Bench"
        case .kettlebell: return "Kettlebell"
        }
    }

    var portugueseName: String {
        switch self {
        case .barbell: return "Barra"
        case .szBar: return "Barra W"
        case .dumbbell: return "Halteres"
        case .gymMat: return "Colchonete"
        case .swissBall: return "Bola Suíça"
        case .pullUpBar: return "Barra Fixa"
        case .bodyweight: return "Peso Corporal"
        case .bench: return "Banco"
        case .inclineBench: return "Banco Inclinado"
        case .kettlebell: return "Kettlebell"
        }
    }

    var toEquipmentType: EquipmentType {
        switch self {
        case .barbell, .szBar: return .barbell
        case .dumbbell: return .dumbbell
        case .gymMat: return .bodyweight
        case .swissBall: return .bodyweight
        case .pullUpBar: return .pullupBar
        case .bodyweight: return .bodyweight
        case .bench, .inclineBench: return .machine
        case .kettlebell: return .kettlebell
        }
    }

    static func from(id: Int) -> ExerciseEquipmentMapping? {
        ExerciseEquipmentMapping(rawValue: id)
    }

    static func localizedName(for id: Int, language: String = "pt") -> String {
        guard let equipment = ExerciseEquipmentMapping(rawValue: id) else {
            return "Outro"
        }
        return language == "pt" ? equipment.portugueseName : equipment.englishName
    }
}

// MARK: - Exercise Language Code

/// Language code constants for exercise catalog.
enum ExerciseLanguageCode: Int, Sendable {
    case german = 1
    case english = 2
    case bulgarian = 3
    case portuguese = 4
    case spanish = 5
    case russian = 6
    case dutch = 7
    case czech = 9
    case greek = 10
    case french = 14

    var code: String {
        switch self {
        case .german: return "de"
        case .english: return "en"
        case .bulgarian: return "bg"
        case .portuguese: return "pt"
        case .spanish: return "es"
        case .russian: return "ru"
        case .dutch: return "nl"
        case .czech: return "cs"
        case .greek: return "el"
        case .french: return "fr"
        }
    }

    static func from(code: String) -> ExerciseLanguageCode {
        switch code.lowercased() {
        case "pt", "pt-br": return .portuguese
        case "en": return .english
        case "es": return .spanish
        case "de": return .german
        case "fr": return .french
        default: return .english
        }
    }
}
