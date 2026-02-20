//
//  ExerciseTranslationService.swift
//  FitToday
//
//  Service to detect language and translate exercise descriptions to Portuguese.
//  Uses NaturalLanguage framework for detection and local dictionaries for translation.
//

import Foundation
import NaturalLanguage

/// Actor-based service for ensuring exercise descriptions are in Portuguese.
/// Translates English/Spanish descriptions using local dictionaries to avoid external API costs.
actor ExerciseTranslationService {
    /// In-memory cache to avoid repeated processing
    private var cache: [String: String] = [:]

    /// The only accepted language for descriptions (Portuguese)
    private let acceptedLanguage: NLLanguage = .portuguese

    /// Languages to translate from
    private let translatableLanguages: Set<NLLanguage> = [.english, .spanish]

    // MARK: - Public Methods

    /// Ensures the description is in Portuguese, translating if necessary.
    /// - Parameters:
    ///   - text: The original description text
    ///   - targetLocale: The target locale (defaults to current system locale)
    /// - Returns: The Portuguese description (translated if needed)
    func ensureLocalizedDescription(_ text: String, targetLocale: Locale = .current) -> String {
        // Skip empty or very short text
        guard !text.isEmpty, text.count > 10 else {
            return getPortugueseFallback()
        }

        // Check cache first
        let cacheKey = "\(text.hashValue)_\(targetLocale.identifier)"
        if let cached = cache[cacheKey] {
            return cached
        }

        // Detect language
        let detectedLanguage = detectLanguage(text)

        // If already Portuguese, use as-is
        if let lang = detectedLanguage, lang == acceptedLanguage {
            cache[cacheKey] = text
            return text
        }

        // If Portuguese patterns detected, use as-is
        if containsPortuguesePatterns(text) && !containsEnglishPatterns(text) {
            cache[cacheKey] = text
            return text
        }

        // Translate if possible
        if let lang = detectedLanguage, translatableLanguages.contains(lang) {
            let translated = translateToPortuguese(text, from: lang)
            let result = validateTranslationQuality(translated)
            cache[cacheKey] = result
            #if DEBUG
            print("[Translation] 🌐 Translated from \(lang.rawValue): '\(text.prefix(50))...' -> '\(result.prefix(50))...'")
            #endif
            return result
        }

        // Check patterns for English even if language detection failed
        if containsEnglishPatterns(text) {
            let translated = translateToPortuguese(text, from: .english)
            let result = validateTranslationQuality(translated)
            cache[cacheKey] = result
            return result
        }

        // Check patterns for Spanish
        if containsSpanishPatterns(text) {
            let translated = translateToPortuguese(text, from: .spanish)
            let result = validateTranslationQuality(translated)
            cache[cacheKey] = result
            return result
        }

        // Fallback for unknown languages
        let fallback = getPortugueseFallback()
        cache[cacheKey] = fallback
        return fallback
    }

    /// Clears the translation cache.
    func clearCache() {
        cache.removeAll()
        #if DEBUG
        print("[Translation] 🗑️ Cache cleared")
        #endif
    }

    // MARK: - Translation Quality Validation

    /// Checks if translated text still contains foreign language patterns.
    /// If it does, the dictionary-based translation produced garbled mixed-language text,
    /// so we return the Portuguese fallback instead.
    private func validateTranslationQuality(_ translated: String) -> String {
        if containsSpanishPatterns(translated) || containsEnglishPatterns(translated) {
            #if DEBUG
            print("[Translation] ⚠️ Post-translation still contains foreign patterns, using fallback")
            #endif
            return getPortugueseFallback()
        }
        return translated
    }

    // MARK: - Translation Engine

    /// Translates text to Portuguese using local dictionaries.
    private func translateToPortuguese(_ text: String, from language: NLLanguage) -> String {
        var result = text

        // Get the appropriate dictionary
        let dictionary: [String: String]
        switch language {
        case .english:
            dictionary = englishToPortugueseDictionary
        case .spanish:
            dictionary = spanishToPortugueseDictionary
        default:
            dictionary = englishToPortugueseDictionary
        }

        // Apply replacements (case-insensitive)
        for (source, target) in dictionary {
            result = result.replacingOccurrences(
                of: source,
                with: target,
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        }

        return result
    }

    // MARK: - Language Detection

    private func detectLanguage(_ text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage
    }

    // MARK: - Pattern Detection

    private func containsSpanishPatterns(_ text: String) -> Bool {
        let spanishIndicators = [
            " el ", " la ", " los ", " las ",
            " del ", " al ", " muy ", " más ",
            " hacia ", " desde ", " hasta ",
            "ción ", "¿", "¡"
        ]
        let lowercased = text.lowercased()
        return spanishIndicators.contains { lowercased.contains($0) }
    }

    private func containsEnglishPatterns(_ text: String) -> Bool {
        // Space-padded patterns match words mid-sentence.
        // Unprefixed patterns (no leading space) match at sentence start.
        let englishIndicators = [
            " the ", " and ", " with ", " your ", " this ",
            " that ", " from ", " have ", " will ", " should ",
            " keep ", " hold ", " push ", " pull ", " lift ",
            " lower ", " raise ", " extend ", " flex ", " repeat ",
            // Sentence-start variants (no leading space required)
            "keep ", "hold ", "push ", "pull ", "lift ",
            "lower ", "raise ", "extend ", "flex ", "stand ",
            "sit ", "lie ", "bend ", "squeeze ", "the "
        ]
        let lowercased = text.lowercased()
        return englishIndicators.contains { lowercased.contains($0) }
    }

    private func containsPortuguesePatterns(_ text: String) -> Bool {
        // Space-padded patterns match words mid-sentence.
        // Sentence-start and suffix patterns need no leading space.
        let portugueseIndicators = [
            " o ", " a ", " os ", " as ", " um ", " uma ",
            " do ", " da ", " dos ", " das ", " no ", " na ",
            " com ", " para ", " por ", " que ", " não ",
            " mantenha ", " segure ", " empurre ", " puxe ",
            "ção ", "ões ", "mente ",
            // Sentence-start variants
            "mantenha ", "segure ", "empurre ", "puxe ",
            "fique ", "deite ", "sente ", "levante ", "abaixe "
        ]
        let lowercased = text.lowercased()
        return portugueseIndicators.contains { lowercased.contains($0) }
    }

    // MARK: - Fallback

    private nonisolated func getPortugueseFallback() -> String {
        String(localized: "exercise.description.fallback")
    }

    // MARK: - Translation Dictionaries

    /// English to Portuguese translation dictionary for exercise terms
    private let englishToPortugueseDictionary: [String: String] = [
        // Articles and prepositions
        " the ": " o ",
        " a ": " um ",
        " an ": " um ",
        " and ": " e ",
        " or ": " ou ",
        " with ": " com ",
        " without ": " sem ",
        " on ": " em ",
        " in ": " em ",
        " to ": " para ",
        " from ": " de ",
        " at ": " em ",
        " by ": " por ",
        " for ": " para ",
        " of ": " de ",
        " your ": " seu ",
        " this ": " este ",
        " that ": " esse ",

        // Verbs (imperative)
        "stand ": "fique de pé ",
        "sit ": "sente ",
        "lie ": "deite ",
        "lying ": "deitado ",
        "standing ": "em pé ",
        "sitting ": "sentado ",
        "keep ": "mantenha ",
        "hold ": "segure ",
        "push ": "empurre ",
        "pull ": "puxe ",
        "lift ": "levante ",
        "lower ": "abaixe ",
        "raise ": "eleve ",
        "extend ": "estenda ",
        "flex ": "flexione ",
        "bend ": "flexione ",
        "stretch ": "alongue ",
        "squeeze ": "contraia ",
        "contract ": "contraia ",
        "relax ": "relaxe ",
        "repeat ": "repita ",
        "return ": "retorne ",
        "rotate ": "gire ",
        "twist ": "gire ",
        "grip ": "segure ",
        "grasp ": "segure ",
        "place ": "posicione ",
        "position ": "posicione ",
        "start ": "comece ",
        "begin ": "comece ",
        "finish ": "termine ",
        "complete ": "complete ",
        "perform ": "execute ",
        "execute ": "execute ",
        "maintain ": "mantenha ",
        "control ": "controle ",
        "avoid ": "evite ",
        "breathe ": "respire ",
        "inhale ": "inspire ",
        "exhale ": "expire ",
        "pause ": "pause ",
        "rest ": "descanse ",

        // Body parts
        "arms": "braços",
        "arm": "braço",
        "legs": "pernas",
        "leg": "perna",
        "hands": "mãos",
        "hand": "mão",
        "feet": "pés",
        "foot": "pé",
        "back": "costas",
        "chest": "peito",
        "shoulders": "ombros",
        "shoulder": "ombro",
        "core": "core",
        "abs": "abdominais",
        "abdominals": "abdominais",
        "glutes": "glúteos",
        "hips": "quadris",
        "hip": "quadril",
        "knees": "joelhos",
        "knee": "joelho",
        "elbows": "cotovelos",
        "elbow": "cotovelo",
        "wrists": "pulsos",
        "wrist": "pulso",
        "ankles": "tornozelos",
        "ankle": "tornozelo",
        "neck": "pescoço",
        "head": "cabeça",
        "torso": "tronco",
        "spine": "coluna",
        "lower back": "lombar",
        "upper back": "costas superiores",
        "thighs": "coxas",
        "thigh": "coxa",
        "calves": "panturrilhas",
        "calf": "panturrilha",
        "biceps": "bíceps",
        "triceps": "tríceps",
        "forearms": "antebraços",
        "forearm": "antebraço",
        "quads": "quadríceps",
        "quadriceps": "quadríceps",
        "hamstrings": "isquiotibiais",
        "hamstring": "isquiotibial",
        "lats": "dorsais",
        "pecs": "peitorais",
        "traps": "trapézio",
        "delts": "deltoides",

        // Equipment
        "barbell": "barra",
        "dumbbell": "halter",
        "dumbbells": "halteres",
        "weight": "peso",
        "weights": "pesos",
        "bench": "banco",
        "bar": "barra",
        "cable": "cabo",
        "machine": "máquina",
        "floor": "chão",
        "mat": "colchonete",
        "resistance band": "elástico",
        "kettlebell": "kettlebell",
        "pull-up bar": "barra fixa",
        "rack": "rack",

        // Directions and positions
        "up": "para cima",
        "down": "para baixo",
        "forward": "para frente",
        "backward": "para trás",
        "left": "esquerda",
        "right": "direita",
        "side": "lado",
        "sides": "lados",
        "front": "frente",
        "behind": "atrás",
        "above": "acima",
        "below": "abaixo",
        "between": "entre",
        "parallel": "paralelo",
        "perpendicular": "perpendicular",
        "straight": "reto",
        "bent": "flexionado",
        "slightly": "levemente",

        // Common phrases
        "starting position": "posição inicial",
        "throughout the movement": "durante todo o movimento",
        "full range of motion": "amplitude completa de movimento",
        "controlled manner": "de forma controlada",
        "slowly": "lentamente",
        "quickly": "rapidamente",
        "then": "então",
        "while": "enquanto",
        "until": "até",
        "when": "quando",
        "before": "antes",
        "after": "depois",
        "during": "durante",
        "always": "sempre",
        "never": "nunca",

        // Numbers
        "one": "um",
        "two": "dois",
        "three": "três",
        "four": "quatro",
        "five": "cinco",
        "seconds": "segundos",
        "second": "segundo",
        "reps": "repetições",
        "rep": "repetição",
        "sets": "séries",
        "set": "série",
        "times": "vezes",
        "time": "vez"
    ]

    /// Spanish to Portuguese translation dictionary for exercise terms
    private let spanishToPortugueseDictionary: [String: String] = [
        // Articles and prepositions
        " el ": " o ",
        " la ": " a ",
        " los ": " os ",
        " las ": " as ",
        " un ": " um ",
        " una ": " uma ",
        " y ": " e ",
        " o ": " ou ",
        " con ": " com ",
        " sin ": " sem ",
        " en ": " em ",
        " de ": " de ",
        " del ": " do ",
        " al ": " ao ",
        " para ": " para ",
        " por ": " por ",
        " su ": " seu ",
        " sus ": " seus ",
        " este ": " este ",
        " esta ": " esta ",
        " ese ": " esse ",
        " esa ": " essa ",

        // Verbs
        "mantener ": "manter ",
        "mantenga ": "mantenha ",
        "sostener ": "segurar ",
        "sostenga ": "segure ",
        "empujar ": "empurrar ",
        "empuje ": "empurre ",
        "tirar ": "puxar ",
        "tire ": "puxe ",
        "levantar ": "levantar ",
        "levante ": "levante ",
        "bajar ": "abaixar ",
        "baje ": "abaixe ",
        "elevar ": "elevar ",
        "eleve ": "eleve ",
        "extender ": "estender ",
        "extienda ": "estenda ",
        "flexionar ": "flexionar ",
        "flexione ": "flexione ",
        "estirar ": "alongar ",
        "estire ": "alongue ",
        "contraer ": "contrair ",
        "contraiga ": "contraia ",
        "relajar ": "relaxar ",
        "relaje ": "relaxe ",
        "repetir ": "repetir ",
        "repita ": "repita ",
        "volver ": "voltar ",
        "vuelva ": "volte ",
        "girar ": "girar ",
        "gire ": "gire ",
        "respirar ": "respirar ",
        "respire ": "respire ",
        "inhalar ": "inspirar ",
        "inhale ": "inspire ",
        "exhalar ": "expirar ",
        "exhale ": "expire ",

        // Body parts
        "brazos": "braços",
        "brazo": "braço",
        "piernas": "pernas",
        "pierna": "perna",
        "manos": "mãos",
        "mano": "mão",
        "pies": "pés",
        "pie": "pé",
        "espalda": "costas",
        "pecho": "peito",
        "hombros": "ombros",
        "hombro": "ombro",
        "abdominales": "abdominais",
        "glúteos": "glúteos",
        "caderas": "quadris",
        "cadera": "quadril",
        "rodillas": "joelhos",
        "rodilla": "joelho",
        "codos": "cotovelos",
        "codo": "cotovelo",
        "muñecas": "pulsos",
        "muñeca": "pulso",
        "tobillos": "tornozelos",
        "tobillo": "tornozelo",
        "cuello": "pescoço",
        "cabeza": "cabeça",
        "tronco": "tronco",
        "columna": "coluna",
        "muslos": "coxas",
        "muslo": "coxa",
        "pantorrillas": "panturrilhas",
        "pantorrilla": "panturrilha",

        // Equipment
        "barra": "barra",
        "mancuerna": "halter",
        "mancuernas": "halteres",
        "peso": "peso",
        "pesos": "pesos",
        "banco": "banco",
        "cable": "cabo",
        "máquina": "máquina",
        "suelo": "chão",
        "colchoneta": "colchonete",

        // Directions
        " hacia ": " em direção a ",
        "arriba": "para cima",
        "abajo": "para baixo",
        "adelante": "para frente",
        "atrás": "para trás",
        "izquierda": "esquerda",
        "derecha": "direita",
        "lado": "lado",
        "lados": "lados",
        "frente": "frente",
        "detrás": "atrás",
        "encima": "acima",
        "debajo": "abaixo",
        "entre": "entre",
        "paralelo": "paralelo",
        "recto": "reto",
        "doblado": "flexionado",
        "ligeramente": "levemente",

        // Common words
        "posición inicial": "posição inicial",
        "movimiento": "movimento",
        "lentamente": "lentamente",
        "rápidamente": "rapidamente",
        "entonces": "então",
        "mientras": "enquanto",
        "hasta": "até",
        "cuando": "quando",
        "antes": "antes",
        "después": "depois",
        "durante": "durante",
        "siempre": "sempre",
        "nunca": "nunca",
        "segundos": "segundos",
        "segundo": "segundo",
        "repeticiones": "repetições",
        "repetición": "repetição",
        "series": "séries",
        "serie": "série",
        "veces": "vezes",
        "vez": "vez"
    ]
}
