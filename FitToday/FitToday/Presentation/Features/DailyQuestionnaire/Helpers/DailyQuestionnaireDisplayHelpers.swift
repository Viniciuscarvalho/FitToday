//
//  DailyQuestionnaireDisplayHelpers.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// MARK: - DailyFocus Extensions

extension DailyFocus {
    var displayTitle: String {
        switch self {
        case .fullBody: return "Corpo inteiro"
        case .upper: return "Superior"
        case .lower: return "Inferior"
        case .cardio: return "Cardio"
        case .core: return "Core"
        case .surprise: return "Surpreenda-me"
        }
    }

    var displaySubtitle: String {
        switch self {
        case .fullBody: return "Equilíbrio total"
        case .upper: return "Peito, costas e braços"
        case .lower: return "Glúteos e pernas"
        case .cardio: return "Foco em fôlego"
        case .core: return "Estabilidade e ABS"
        case .surprise: return "Deixe a IA decidir"
        }
    }

    var iconName: String {
        switch self {
        case .fullBody: return "figure.walk"
        case .upper: return "figure.strengthtraining.traditional"
        case .lower: return "figure.step.training"
        case .cardio: return "figure.run"
        case .core: return "circle.grid.cross"
        case .surprise: return "sparkles"
        }
    }
}

// MARK: - MuscleSorenessLevel Extensions

extension MuscleSorenessLevel {
    var displayTitle: String {
        switch self {
        case .none: return "Nada"
        case .light: return "Leve"
        case .moderate: return "Moderada"
        case .strong: return "Forte"
        }
    }

    var displaySubtitle: String {
        switch self {
        case .none: return "Pronto para ir ao limite"
        case .light: return "Só um incômodo leve"
        case .moderate: return "Precisa de ajustes"
        case .strong: return "Vamos proteger seu corpo"
        }
    }

    var displayColor: Color {
        switch self {
        case .none: return Color.green
        case .light: return Color.blue
        case .moderate: return Color.orange
        case .strong: return Color.red
        }
    }
}
