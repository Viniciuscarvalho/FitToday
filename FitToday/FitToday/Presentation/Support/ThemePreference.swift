//
//  ThemePreference.swift
//  FitToday
//

import SwiftUI

enum ThemePreference: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }

    var localizationKey: String {
        switch self {
        case .system: return "settings.theme.system"
        case .dark: return "settings.theme.dark"
        case .light: return "settings.theme.light"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}
