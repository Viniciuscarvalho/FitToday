//
//  ExerciseCatalogModels.swift
//  FitToday
//
//  Category, equipment, and language mappings for the exercise catalog.
//  Extracted from WgerModels.swift — same logic, no Wger dependency.
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

/// Maps category IDs to human-readable names.
enum ExerciseCategoryMapping: Int, CaseIterable, Sendable {
    case arms = 8
    case legs = 9
    case abs = 10
    case chest = 11
    case back = 12
    case shoulders = 13
    case calves = 14
    case cardio = 15

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
        }
    }

    var icon: String {
        switch self {
        case .arms: return "figure.boxing"
        case .legs: return "figure.run"
        case .abs: return "figure.core.training"
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .calves: return "figure.run"
        case .cardio: return "heart.fill"
        }
    }

    var muscleGroup: MuscleGroup {
        switch self {
        case .arms: return .arms
        case .legs: return .quadriceps
        case .abs: return .core
        case .chest: return .chest
        case .back: return .back
        case .shoulders: return .shoulders
        case .calves: return .calves
        case .cardio: return .cardioSystem
        }
    }

    static func from(id: Int) -> ExerciseCategoryMapping? {
        ExerciseCategoryMapping(rawValue: id)
    }

    static func localizedName(for id: Int, language: String = "pt") -> String {
        guard let category = ExerciseCategoryMapping(rawValue: id) else {
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
