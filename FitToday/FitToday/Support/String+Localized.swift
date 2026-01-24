//
//  String+Localized.swift
//  FitToday
//
//  String extension for easy localization.
//

import Foundation

extension String {
    /// Returns the localized version of this string.
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns the localized version of this string with format arguments.
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
