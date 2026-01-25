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
    }

    /// Currently selected language.
    private(set) var selectedLanguage: Language {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "app_language")
            updateBundle()
        }
    }

    /// The bundle to use for localization (enables runtime switching)
    private(set) var currentBundle: Bundle = .main

    private init() {
        // Load saved language or detect from device
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = Language(rawValue: savedLanguage) {
            self.selectedLanguage = language
        } else {
            // Default to device language or English
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            if deviceLanguage.hasPrefix("pt") {
                self.selectedLanguage = .portuguese
            } else {
                self.selectedLanguage = .english
            }
        }
        updateBundle()
    }

    /// Changes the app language with immediate effect.
    func setLanguage(_ language: Language) {
        selectedLanguage = language
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
    @MainActor static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    @MainActor var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
