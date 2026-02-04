//
//  ExerciseTranslationService.swift
//  FitToday
//
//  Service to detect language and provide localized descriptions.
//  Filters out Spanish and other non-supported languages.
//

import Foundation
import NaturalLanguage

/// Actor-based service for ensuring exercise descriptions are in the correct language.
/// Uses NaturalLanguage framework for language detection.
/// For a Portuguese app, non-Portuguese descriptions are replaced with a localized fallback.
actor ExerciseTranslationService {
    /// In-memory cache to avoid repeated processing
    private var cache: [String: String] = [:]

    /// The only accepted language for descriptions (Portuguese)
    private let acceptedLanguage: NLLanguage = .portuguese

    /// Languages to explicitly filter out (including English for Portuguese-only app)
    private let blockedLanguages: Set<NLLanguage> = [.spanish, .german, .french, .italian, .english]

    /// Ensures the description is in Portuguese, returning fallback if not.
    /// - Parameters:
    ///   - text: The original description text
    ///   - targetLocale: The target locale (defaults to current system locale)
    /// - Returns: The Portuguese description or a fallback message
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

        // Only accept Portuguese text
        if let lang = detectedLanguage, lang == acceptedLanguage {
            cache[cacheKey] = text
            return text
        }

        // If the detected language is explicitly blocked, use fallback
        if let lang = detectedLanguage, blockedLanguages.contains(lang) {
            #if DEBUG
            print("[Translation] ⚠️ Non-Portuguese language detected: \(lang.rawValue) - using fallback")
            #endif
            let fallback = getPortugueseFallback()
            cache[cacheKey] = fallback
            return fallback
        }

        // For unknown or mixed content, check for specific patterns
        if containsSpanishPatterns(text) || containsEnglishPatterns(text) {
            #if DEBUG
            print("[Translation] ⚠️ Non-Portuguese patterns detected in text - using fallback")
            #endif
            let fallback = getPortugueseFallback()
            cache[cacheKey] = fallback
            return fallback
        }

        // Check if it looks like Portuguese
        if containsPortuguesePatterns(text) {
            cache[cacheKey] = text
            return text
        }

        // Default: use fallback for any unrecognized language
        let fallback = getPortugueseFallback()
        cache[cacheKey] = fallback
        return fallback
    }

    /// Detects the dominant language in the text.
    private func detectLanguage(_ text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage
    }

    /// Checks for common Spanish words and patterns that might slip through.
    private func containsSpanishPatterns(_ text: String) -> Bool {
        let spanishIndicators = [
            " el ", " la ", " los ", " las ", " un ", " una ",
            " del ", " al ", " con ", " para ", " por ",
            " muy ", " más ", " también ", " pero ", " como ",
            " hacia ", " desde ", " hasta ", " sobre ",
            "ción ", "ñ", "¿", "¡"
        ]

        let lowercased = text.lowercased()
        return spanishIndicators.contains { lowercased.contains($0) }
    }

    /// Checks for common English words and patterns.
    private func containsEnglishPatterns(_ text: String) -> Bool {
        let englishIndicators = [
            " the ", " and ", " with ", " your ", " this ",
            " that ", " from ", " have ", " will ", " should ",
            " keep ", " hold ", " push ", " pull ", " lift ",
            " lower ", " raise ", " extend ", " flex ", " repeat ",
            " position ", " movement ", " exercise ", " muscle ",
            " slowly ", " until ", " while ", " throughout "
        ]

        let lowercased = text.lowercased()
        return englishIndicators.contains { lowercased.contains($0) }
    }

    /// Checks for common Portuguese words and patterns.
    private func containsPortuguesePatterns(_ text: String) -> Bool {
        let portugueseIndicators = [
            " o ", " a ", " os ", " as ", " um ", " uma ",
            " do ", " da ", " dos ", " das ", " no ", " na ",
            " com ", " para ", " por ", " que ", " não ",
            " seu ", " sua ", " seus ", " suas ", " este ", " esta ",
            " esse ", " essa ", " isso ", " isto ",
            " mantenha ", " segure ", " empurre ", " puxe ", " levante ",
            " abaixe ", " estenda ", " flexione ", " repita ",
            " posição ", " movimento ", " exercício ", " músculo ",
            " lentamente ", " até ", " enquanto ", " durante ",
            "ção ", "ões ", "mente "
        ]

        let lowercased = text.lowercased()
        return portugueseIndicators.contains { lowercased.contains($0) }
    }

    /// Returns a generic Portuguese fallback for exercise instructions.
    private nonisolated func getPortugueseFallback() -> String {
        String(localized: "exercise.description.fallback")
    }

    /// Clears the translation cache.
    func clearCache() {
        cache.removeAll()
        #if DEBUG
        print("[Translation] 🗑️ Cache cleared")
        #endif
    }
}
