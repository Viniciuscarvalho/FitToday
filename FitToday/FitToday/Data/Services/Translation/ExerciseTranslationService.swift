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
actor ExerciseTranslationService {
    /// In-memory cache to avoid repeated processing
    private var cache: [String: String] = [:]

    /// Supported languages for exercise descriptions
    private let supportedLanguages: Set<NLLanguage> = [.portuguese, .english]

    /// Languages to explicitly filter out (commonly mixed in API responses)
    private let blockedLanguages: Set<NLLanguage> = [.spanish, .german, .french, .italian]

    /// Ensures the description is in a supported language, returning fallback if not.
    /// - Parameters:
    ///   - text: The original description text
    ///   - targetLocale: The target locale (defaults to current system locale)
    /// - Returns: The localized description or a fallback message
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

        // If the detected language is blocked, use fallback
        if let lang = detectedLanguage, blockedLanguages.contains(lang) {
            #if DEBUG
            print("[Translation] ⚠️ Blocked language detected: \(lang.rawValue) - using fallback")
            #endif
            let fallback = getPortugueseFallback()
            cache[cacheKey] = fallback
            return fallback
        }

        // If it's a supported language, use the text as-is
        if let lang = detectedLanguage, supportedLanguages.contains(lang) {
            cache[cacheKey] = text
            return text
        }

        // For unknown or mixed content, check for specific patterns
        if containsSpanishPatterns(text) {
            #if DEBUG
            print("[Translation] ⚠️ Spanish patterns detected in text - using fallback")
            #endif
            let fallback = getPortugueseFallback()
            cache[cacheKey] = fallback
            return fallback
        }

        // Default: use the original text (likely English or acceptable)
        cache[cacheKey] = text
        return text
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
