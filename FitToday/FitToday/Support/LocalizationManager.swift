//
//  LocalizationManager.swift
//  FitToday
//
//  Manages app language selection and persistence.
//

import Foundation
import SwiftUI

/// Manages app localization and language preferences.
@MainActor
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    /// Supported languages in the app.
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case portuguese = "pt-BR"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .english: return "English"
            case .portuguese: return "Português"
            }
        }

        var flagEmoji: String {
            switch self {
            case .english: return "🇺🇸"
            case .portuguese: return "🇧🇷"
            }
        }

        /// Locale identifier in ICU format expected by RevenueCat (e.g. "pt_BR").
        var revenueCatLocale: String? {
            switch self {
            case .english: return nil   // nil = use system default
            case .portuguese: return "pt_BR"
            }
        }
    }

    /// Currently selected language.
    private(set) var selectedLanguage: Language

    /// The bundle to use for localization (enables runtime switching)
    private(set) var currentBundle: Bundle = .main

    private init() {
        // Load saved language or detect from device
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = Language(rawValue: savedLanguage) {
            self.selectedLanguage = language
        } else {
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.selectedLanguage = deviceLanguage.hasPrefix("pt") ? .portuguese : .english
        }
        updateBundle()
    }

    /// Changes the app language with immediate effect.
    func setLanguage(_ language: Language) {
        selectedLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        updateBundle()
    }

    /// Updates the bundle to match the selected language.
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: selectedLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
        } else {
            // Fallback to main bundle
            currentBundle = .main
        }
    }

    /// Returns true if the current language is Portuguese.
    var isPortuguese: Bool {
        selectedLanguage == .portuguese
    }

    /// Returns true if the current language is English.
    var isEnglish: Bool {
        selectedLanguage == .english
    }
}

// MARK: - Environment Key

private struct LocalizationManagerKey: EnvironmentKey {
    nonisolated static var defaultValue: LocalizationManager {
        MainActor.assumeIsolated { LocalizationManager.shared }
    }
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
