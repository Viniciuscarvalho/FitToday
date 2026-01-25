//
//  String+Localized.swift
//  FitToday
//
//  String extension for easy localization with runtime language switching.
//

import Foundation

extension String {
    /// Returns the localized version of this string using the currently selected language.
    @MainActor var localized: String {
        let bundle = LocalizationManager.shared.currentBundle
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }

    /// Returns the localized version of this string with format arguments.
    @MainActor func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
