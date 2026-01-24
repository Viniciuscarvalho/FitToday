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
            case .portuguese: return "Portugues"
            }
        }

        var flagEmoji: String {
            switch self {
            case .english: return "US"
            case .portuguese: return "BR"
            }
        }
    }

    /// Currently selected language.
    private(set) var selectedLanguage: Language {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "app_language")
        }
    }

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
    }

    /// Changes the app language.
    func setLanguage(_ language: Language) {
        selectedLanguage = language
        // Note: Full runtime language switching requires app restart or Bundle swizzling
        // For now, we save the preference and it will take effect on next launch
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
