//
//  WgerModels.swift
//  FitToday
//
//  Models for Wger API responses.
//  API Documentation: https://wger.de/en/software/api
//

@preconcurrency import Foundation

// MARK: - HTML Stripping Helper

extension String {
    /// Remove tags HTML e converte entidades HTML para texto limpo.
    nonisolated var strippingHTML: String {
        // Remove tags HTML
        var result = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Converte entidades HTML comuns
        let htmlEntities: [String: String] = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&ndash;": "–",
            "&mdash;": "—",
            "&bull;": "•",
            "&hellip;": "…",
            "&copy;": "©",
            "&reg;": "®",
            "&trade;": "™",
            "&euro;": "€",
            "&pound;": "£",
            "&yen;": "¥",
            "&deg;": "°",
            "&plusmn;": "±",
            "&times;": "×",
            "&divide;": "÷",
            "&frac12;": "½",
            "&frac14;": "¼",
            "&frac34;": "¾"
        ]

        for (entity, replacement) in htmlEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Remove múltiplos espaços e quebras de linha consecutivas
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Wger Exercise

/// Exercise model from Wger API.
struct WgerExercise: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let uuid: String?
    let name: String
    let exerciseBaseId: Int?
    let description: String?
    let category: Int?
    let muscles: [Int]
    let musclesSecondary: [Int]
    let equipment: [Int]
    let language: Int?
    let license: Int?
    let licenseAuthor: String?
    /// URL da imagem principal do exercício
    let mainImageURL: String?
    /// URLs de todas as imagens do exercício
    let imageURLs: [String]

    enum CodingKeys: String, CodingKey {
        case id, uuid, name, description, category, muscles, equipment, language, license
        case exerciseBaseId = "exercise_base"
        case musclesSecondary = "muscles_secondary"
        case licenseAuthor = "license_author"
        case mainImageURL = "main_image"
        case imageURLs = "images"
    }

    /// Memberwise initializer for manual construction.
    nonisolated init(
        id: Int,
        uuid: String? = nil,
        name: String,
        exerciseBaseId: Int? = nil,
        description: String? = nil,
        category: Int? = nil,
        muscles: [Int] = [],
        musclesSecondary: [Int] = [],
        equipment: [Int] = [],
        language: Int? = nil,
        license: Int? = nil,
        licenseAuthor: String? = nil,
        mainImageURL: String? = nil,
        imageURLs: [String] = []
    ) {
        self.id = id
        self.uuid = uuid
        self.name = name
        self.exerciseBaseId = exerciseBaseId
        self.description = description
        self.category = category
        self.muscles = muscles
        self.musclesSecondary = musclesSecondary
        self.equipment = equipment
        self.language = language
        self.license = license
        self.licenseAuthor = licenseAuthor
        self.mainImageURL = mainImageURL
        self.imageURLs = imageURLs
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        exerciseBaseId = try container.decodeIfPresent(Int.self, forKey: .exerciseBaseId)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(Int.self, forKey: .category)
        muscles = try container.decodeIfPresent([Int].self, forKey: .muscles) ?? []
        musclesSecondary = try container.decodeIfPresent([Int].self, forKey: .musclesSecondary) ?? []
        equipment = try container.decodeIfPresent([Int].self, forKey: .equipment) ?? []
        language = try container.decodeIfPresent(Int.self, forKey: .language)
        license = try container.decodeIfPresent(Int.self, forKey: .license)
        licenseAuthor = try container.decodeIfPresent(String.self, forKey: .licenseAuthor)
        mainImageURL = try container.decodeIfPresent(String.self, forKey: .mainImageURL)
        imageURLs = try container.decodeIfPresent([String].self, forKey: .imageURLs) ?? []
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(exerciseBaseId, forKey: .exerciseBaseId)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(muscles, forKey: .muscles)
        try container.encode(musclesSecondary, forKey: .musclesSecondary)
        try container.encode(equipment, forKey: .equipment)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(license, forKey: .license)
        try container.encodeIfPresent(licenseAuthor, forKey: .licenseAuthor)
        try container.encodeIfPresent(mainImageURL, forKey: .mainImageURL)
        try container.encode(imageURLs, forKey: .imageURLs)
    }
}

// MARK: - Wger Exercise Image

/// Exercise image from Wger API.
struct WgerExerciseImage: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let exercise: Int?
    let exerciseBase: Int?
    let image: String
    let isMain: Bool
    let style: String?

    enum CodingKeys: String, CodingKey {
        case id, image, style, exercise
        case exerciseBase = "exercise_base"
        case isMain = "is_main"
    }

    var imageURL: URL? {
        URL(string: image)
    }

    /// The exercise ID (either from 'exercise' or 'exercise_base' field).
    var exerciseId: Int {
        exercise ?? exerciseBase ?? 0
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        exercise = try container.decodeIfPresent(Int.self, forKey: .exercise)
        exerciseBase = try container.decodeIfPresent(Int.self, forKey: .exerciseBase)
        image = try container.decode(String.self, forKey: .image)
        isMain = try container.decodeIfPresent(Bool.self, forKey: .isMain) ?? false
        style = try container.decodeIfPresent(String.self, forKey: .style)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(exercise, forKey: .exercise)
        try container.encodeIfPresent(exerciseBase, forKey: .exerciseBase)
        try container.encode(image, forKey: .image)
        try container.encode(isMain, forKey: .isMain)
        try container.encodeIfPresent(style, forKey: .style)
    }
}

// MARK: - Wger Category

/// Exercise category (muscle group) from Wger API.
struct WgerCategory: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name
    }
}

// MARK: - Wger Equipment

/// Equipment type from Wger API.
struct WgerEquipment: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name
    }
}

// MARK: - Wger Muscle

/// Muscle from Wger API.
struct WgerMuscle: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let nameLatin: String?
    let isFront: Bool?
    let imageUrlMain: String?
    let imageUrlSecondary: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case nameLatin = "name_en"
        case isFront = "is_front"
        case imageUrlMain = "image_url_main"
        case imageUrlSecondary = "image_url_secondary"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        nameLatin = try container.decodeIfPresent(String.self, forKey: .nameLatin)
        isFront = try container.decodeIfPresent(Bool.self, forKey: .isFront)
        imageUrlMain = try container.decodeIfPresent(String.self, forKey: .imageUrlMain)
        imageUrlSecondary = try container.decodeIfPresent(String.self, forKey: .imageUrlSecondary)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(nameLatin, forKey: .nameLatin)
        try container.encodeIfPresent(isFront, forKey: .isFront)
        try container.encodeIfPresent(imageUrlMain, forKey: .imageUrlMain)
        try container.encodeIfPresent(imageUrlSecondary, forKey: .imageUrlSecondary)
    }
}

// MARK: - Wger Language

/// Language from Wger API.
struct WgerLanguage: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let shortName: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case id
        case shortName = "short_name"
        case fullName = "full_name"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        shortName = try container.decode(String.self, forKey: .shortName)
        fullName = try container.decode(String.self, forKey: .fullName)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(shortName, forKey: .shortName)
        try container.encode(fullName, forKey: .fullName)
    }
}

// MARK: - Paginated Response

/// Generic paginated response from Wger API.
struct WgerPaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
        next = try container.decodeIfPresent(String.self, forKey: .next)
        previous = try container.decodeIfPresent(String.self, forKey: .previous)
        results = try container.decode([T].self, forKey: .results)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(previous, forKey: .previous)
        try container.encode(results, forKey: .results)
    }

    private enum CodingKeys: String, CodingKey {
        case count, next, previous, results
    }
}

// MARK: - Wger Category Mapping

/// Maps Wger category IDs to human-readable names and translations.
enum WgerCategoryMapping: Int, CaseIterable, Sendable {
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

    /// Maps to existing MuscleGroup enum for compatibility.
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

    static func from(id: Int) -> WgerCategoryMapping? {
        WgerCategoryMapping(rawValue: id)
    }

    static func localizedName(for id: Int, language: String = "pt") -> String {
        guard let category = WgerCategoryMapping(rawValue: id) else {
            return "Outro"
        }
        return language == "pt" ? category.portugueseName : category.englishName
    }
}

// MARK: - Wger Equipment Mapping

/// Maps Wger equipment IDs to human-readable names and translations.
enum WgerEquipmentMapping: Int, CaseIterable, Sendable {
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

    /// Maps to existing EquipmentType enum for compatibility.
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

    static func from(id: Int) -> WgerEquipmentMapping? {
        WgerEquipmentMapping(rawValue: id)
    }

    static func localizedName(for id: Int, language: String = "pt") -> String {
        guard let equipment = WgerEquipmentMapping(rawValue: id) else {
            return "Outro"
        }
        return language == "pt" ? equipment.portugueseName : equipment.englishName
    }
}

// MARK: - Wger Language Constants

/// Common Wger language IDs.
enum WgerLanguageCode: Int, Sendable {
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

    static func from(code: String) -> WgerLanguageCode {
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

// MARK: - Wger Exercise Translation

/// Translation of an exercise (name, description) in a specific language.
struct WgerExerciseTranslation: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let uuid: String?
    let name: String
    let description: String?
    let language: Int

    enum CodingKeys: String, CodingKey {
        case id, uuid, name, description, language
    }
}

// MARK: - Wger Detailed Exercise Info

/// Complete exercise info from /exerciseinfo/ endpoint.
/// Note: The name is inside translations[], not at root level.
struct WgerExerciseInfo: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let uuid: String?
    let category: WgerCategory?
    let muscles: [WgerMuscle]
    let musclesSecondary: [WgerMuscle]
    let equipment: [WgerEquipment]
    let images: [WgerExerciseImage]
    let translations: [WgerExerciseTranslation]

    enum CodingKeys: String, CodingKey {
        case id, uuid, category, muscles, equipment, images, translations
        case musclesSecondary = "muscles_secondary"
    }

    /// Gets the name in the preferred language (falls back to English, then first available).
    nonisolated func name(for languageId: Int) -> String {
        // Try preferred language first
        if let translation = translations.first(where: { $0.language == languageId }) {
            return translation.name
        }
        // Fall back to English (language ID 2)
        if let english = translations.first(where: { $0.language == 2 }) {
            return english.name
        }
        // Fall back to first available
        return translations.first?.name ?? "Exercise \(id)"
    }

    /// Gets the description in the preferred language.
    /// Falls back to English only, returns nil if neither Portuguese nor English is available.
    /// This prevents returning descriptions in other languages like Spanish.
    nonisolated func description(for languageId: Int) -> String? {
        // Try preferred language first (Portuguese)
        if let translation = translations.first(where: { $0.language == languageId }),
           let description = translation.description,
           !description.isEmpty {
            return description
        }
        // Fall back to English only (language ID 2) - NOT any other language
        if let english = translations.first(where: { $0.language == 2 }),
           let description = english.description,
           !description.isEmpty {
            return description
        }
        // Return nil to trigger the Portuguese fallback message in WgerAPIService
        return nil
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
        category = try container.decodeIfPresent(WgerCategory.self, forKey: .category)
        muscles = try container.decodeIfPresent([WgerMuscle].self, forKey: .muscles) ?? []
        musclesSecondary = try container.decodeIfPresent([WgerMuscle].self, forKey: .musclesSecondary) ?? []
        equipment = try container.decodeIfPresent([WgerEquipment].self, forKey: .equipment) ?? []
        images = try container.decodeIfPresent([WgerExerciseImage].self, forKey: .images) ?? []
        translations = try container.decodeIfPresent([WgerExerciseTranslation].self, forKey: .translations) ?? []
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(uuid, forKey: .uuid)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(muscles, forKey: .muscles)
        try container.encode(musclesSecondary, forKey: .musclesSecondary)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(images, forKey: .images)
        try container.encode(translations, forKey: .translations)
    }
}
