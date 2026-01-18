//
//  WorkoutRating.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

/// User's rating of a completed workout
/// Used to feed the adaptive training system
enum WorkoutRating: String, Codable, CaseIterable, Sendable {
    case tooEasy = "too_easy"
    case adequate = "adequate"
    case tooHard = "too_hard"

    /// Display name in Portuguese
    var displayName: String {
        switch self {
        case .tooEasy: return "Muito Fácil"
        case .adequate: return "Adequado"
        case .tooHard: return "Muito Difícil"
        }
    }

    /// Emoji representation for UI
    var emoji: String {
        switch self {
        case .tooEasy: return "😅"
        case .adequate: return "💪"
        case .tooHard: return "🔥"
        }
    }

    /// Creates a WorkoutRating from a raw string value
    /// Returns nil if the string doesn't match any case
    init?(rawString: String?) {
        guard let rawString = rawString else { return nil }
        self.init(rawValue: rawString)
    }
}

/// Record of a completed exercise within a workout
/// Used for tracking which exercises were actually performed
struct CompletedExercise: Codable, Sendable, Hashable {
    let exerciseId: String
    let exerciseName: String
    let muscleGroup: String
    let completed: Bool

    init(
        exerciseId: String,
        exerciseName: String,
        muscleGroup: String,
        completed: Bool = true
    ) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.completed = completed
    }
}
