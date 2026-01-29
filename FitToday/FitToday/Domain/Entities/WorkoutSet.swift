//
//  WorkoutSet.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation

/// Represents a single set within a custom exercise entry.
/// Can be used for both target (planned) and actual (performed) tracking.
struct WorkoutSet: Identifiable, Codable, Sendable, Hashable {
    let id: UUID

    // Target values (what user plans to do)
    var targetReps: Int?
    var targetWeight: Double?
    var targetDuration: TimeInterval? // For timed exercises (planks, etc.)

    // Actual values (what user actually did)
    var actualReps: Int?
    var actualWeight: Double?
    var actualDuration: TimeInterval?

    // Completion state
    var isCompleted: Bool

    /// Creates a new set with default values
    init(
        id: UUID = UUID(),
        targetReps: Int? = 10,
        targetWeight: Double? = nil,
        targetDuration: TimeInterval? = nil,
        actualReps: Int? = nil,
        actualWeight: Double? = nil,
        actualDuration: TimeInterval? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.targetDuration = targetDuration
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.actualDuration = actualDuration
        self.isCompleted = isCompleted
    }

    /// Creates a copy of this set for a new workout session
    func copyForNewSession() -> WorkoutSet {
        WorkoutSet(
            targetReps: targetReps,
            targetWeight: targetWeight,
            targetDuration: targetDuration,
            actualReps: nil,
            actualWeight: nil,
            actualDuration: nil,
            isCompleted: false
        )
    }

    /// Whether this set uses time-based tracking instead of reps
    var isTimedSet: Bool {
        targetDuration != nil
    }

    /// Display string for the set (e.g., "10 reps @ 50kg" or "30 sec")
    var displayString: String {
        if let duration = targetDuration {
            return "\(Int(duration))s"
        }

        var parts: [String] = []
        if let reps = targetReps {
            parts.append("\(reps) reps")
        }
        if let weight = targetWeight {
            parts.append("@ \(Int(weight))kg")
        }
        return parts.isEmpty ? "Set" : parts.joined(separator: " ")
    }
}
