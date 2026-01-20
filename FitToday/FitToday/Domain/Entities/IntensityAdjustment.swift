//
//  IntensityAdjustment.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

/// Represents intensity adjustments based on user feedback analysis.
/// Used to modify future workout parameters for adaptive training.
struct IntensityAdjustment: Sendable, Equatable {
    /// Volume multiplier for exercise count/sets (0.8 - 1.2)
    let volumeMultiplier: Double

    /// RPE (Rate of Perceived Exertion) adjustment (-1, 0, +1)
    let rpeAdjustment: Int

    /// Rest period adjustment in seconds (-15s to +30s)
    let restAdjustment: TimeInterval

    /// Recommendation text for OpenAI prompt (in Portuguese)
    let recommendation: String

    // MARK: - Factory Methods

    /// No changes needed - user feedback is balanced or insufficient
    static var noChange: IntensityAdjustment {
        IntensityAdjustment(
            volumeMultiplier: 1.0,
            rpeAdjustment: 0,
            restAdjustment: 0,
            recommendation: ""
        )
    }

    /// Increase intensity - user rated workouts as too easy
    static var increaseIntensity: IntensityAdjustment {
        IntensityAdjustment(
            volumeMultiplier: 1.15,
            rpeAdjustment: 1,
            restAdjustment: -15,
            recommendation: "O usuário relatou que os treinos recentes estavam muito fáceis. Aumente a intensidade: adicione mais séries ou repetições, reduza os intervalos de descanso e escolha variações mais desafiadoras dos exercícios."
        )
    }

    /// Decrease intensity - user rated workouts as too hard
    static var decreaseIntensity: IntensityAdjustment {
        IntensityAdjustment(
            volumeMultiplier: 0.85,
            rpeAdjustment: -1,
            restAdjustment: 30,
            recommendation: "O usuário relatou que os treinos recentes estavam muito difíceis. Diminua a intensidade: reduza o número de séries ou repetições, aumente os intervalos de descanso e escolha variações mais acessíveis dos exercícios."
        )
    }

    // MARK: - Computed Properties

    /// Whether any adjustment is needed
    var hasAdjustment: Bool {
        volumeMultiplier != 1.0 || rpeAdjustment != 0 || restAdjustment != 0
    }

    /// Direction of intensity change
    var direction: IntensityDirection {
        if volumeMultiplier > 1.0 {
            return .increase
        } else if volumeMultiplier < 1.0 {
            return .decrease
        }
        return .maintain
    }
}

/// Direction of intensity adjustment
enum IntensityDirection: String, Sendable {
    case increase
    case decrease
    case maintain
}
