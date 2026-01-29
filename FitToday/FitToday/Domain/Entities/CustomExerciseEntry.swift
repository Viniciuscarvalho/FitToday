//
//  CustomExerciseEntry.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation

/// Represents an exercise within a custom workout template.
/// Contains reference to Wger API data plus user-configured sets.
struct CustomExerciseEntry: Identifiable, Codable, Sendable, Hashable {
    let id: UUID

    // Wger API reference
    var exerciseId: String
    var exerciseName: String
    var exerciseGifURL: String?
    var bodyPart: String?
    var equipment: String?

    // Ordering
    var orderIndex: Int

    // Sets configuration
    var sets: [WorkoutSet]

    // Optional notes
    var notes: String?

    /// Creates a new exercise entry from Wger API data
    init(
        id: UUID = UUID(),
        exerciseId: String,
        exerciseName: String,
        exerciseGifURL: String? = nil,
        bodyPart: String? = nil,
        equipment: String? = nil,
        orderIndex: Int,
        sets: [WorkoutSet] = [WorkoutSet()],
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.exerciseGifURL = exerciseGifURL
        self.bodyPart = bodyPart
        self.equipment = equipment
        self.orderIndex = orderIndex
        self.sets = sets
        self.notes = notes
    }

    /// Creates a copy of this entry for a new workout session (resets completion state)
    func copyForNewSession(orderIndex: Int) -> CustomExerciseEntry {
        CustomExerciseEntry(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            exerciseGifURL: exerciseGifURL,
            bodyPart: bodyPart,
            equipment: equipment,
            orderIndex: orderIndex,
            sets: sets.map { $0.copyForNewSession() },
            notes: notes
        )
    }

    /// Total number of sets
    var totalSets: Int {
        sets.count
    }

    /// Number of completed sets
    var completedSets: Int {
        sets.filter { $0.isCompleted }.count
    }

    /// Whether all sets are completed
    var isFullyCompleted: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.isCompleted }
    }

    /// Estimated duration in minutes (2 min per set average)
    var estimatedDurationMinutes: Int {
        sets.count * 2
    }
}

// MARK: - Convenience initializer from WgerExercise

extension CustomExerciseEntry {
    /// Creates a new entry from a WgerExercise model
    /// - Parameters:
    ///   - wgerExercise: The WgerExercise from Wger API service
    ///   - orderIndex: Position in the workout
    ///   - imageURL: Optional image URL
    init(from wgerExercise: WgerExercise, orderIndex: Int, imageURL: String? = nil) {
        self.id = UUID()
        self.exerciseId = String(wgerExercise.id)
        self.exerciseName = wgerExercise.name
        self.exerciseGifURL = imageURL
        self.bodyPart = wgerExercise.category.flatMap { WgerCategoryMapping.from(id: $0)?.portugueseName }
        self.equipment = wgerExercise.equipment.first.flatMap { WgerEquipmentMapping.from(id: $0)?.portugueseName }
        self.orderIndex = orderIndex
        self.sets = [WorkoutSet()] // Start with 1 default set
        self.notes = nil
    }
}

