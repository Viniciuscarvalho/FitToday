//
//  FBTrainerWorkout.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import FirebaseFirestore
import Foundation

// MARK: - Firebase Trainer Workout DTO

/// Firebase DTO for trainer-created workouts.
///
/// Matches Firestore collection: `/trainerWorkouts/{id}`
struct FBTrainerWorkout: Codable {
    /// Document ID (populated by Firestore).
    @DocumentID var id: String?

    /// The trainer who created this workout.
    var trainerId: String

    /// Array of student IDs this workout is assigned to.
    var assignedStudents: [String]

    /// Workout title/name.
    var title: String

    /// Optional description of the workout.
    var description: String?

    /// Focus area of the workout (maps to DailyFocus).
    var focus: String

    /// Estimated duration in minutes.
    var estimatedDurationMinutes: Int

    /// Workout intensity level ("low", "moderate", "high").
    var intensity: String

    /// Workout phases containing exercises.
    var phases: [FBWorkoutPhase]

    /// Schedule configuration for the workout.
    var schedule: FBWorkoutSchedule

    /// Whether the workout is currently active.
    var isActive: Bool

    /// When the workout was created.
    @ServerTimestamp var createdAt: Timestamp?

    /// Version number for tracking updates.
    var version: Int

    // MARK: - Initializer

    init(
        id: String? = nil,
        trainerId: String,
        assignedStudents: [String] = [],
        title: String,
        description: String? = nil,
        focus: String,
        estimatedDurationMinutes: Int,
        intensity: String = "moderate",
        phases: [FBWorkoutPhase] = [],
        schedule: FBWorkoutSchedule = FBWorkoutSchedule(),
        isActive: Bool = true,
        createdAt: Timestamp? = nil,
        version: Int = 1
    ) {
        self.id = id
        self.trainerId = trainerId
        self.assignedStudents = assignedStudents
        self.title = title
        self.description = description
        self.focus = focus
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.intensity = intensity
        self.phases = phases
        self.schedule = schedule
        self.isActive = isActive
        self.createdAt = createdAt
        self.version = version
    }
}

// MARK: - Firebase Workout Phase DTO

/// Represents a phase/section within a trainer workout.
struct FBWorkoutPhase: Codable {
    /// Phase name (e.g., "Warmup", "Main Set", "Cooldown").
    var name: String

    /// Items/exercises in this phase.
    var items: [FBWorkoutItem]

    // MARK: - Initializer

    init(name: String = "", items: [FBWorkoutItem] = []) {
        self.name = name
        self.items = items
    }
}

// MARK: - Firebase Workout Item DTO

/// Represents an individual exercise within a workout phase.
struct FBWorkoutItem: Codable {
    /// Optional exercise ID from Wger or other sources.
    var exerciseId: Int?

    /// Exercise name (always present).
    var exerciseName: String

    /// Number of sets to perform.
    var sets: Int

    /// Rep range as a string (e.g., "8-12" or "10").
    var reps: String

    /// Rest period between sets in seconds.
    var restSeconds: Int

    /// Optional notes or instructions for the exercise.
    var notes: String?

    // MARK: - Initializer

    init(
        exerciseId: Int? = nil,
        exerciseName: String,
        sets: Int = 3,
        reps: String = "10",
        restSeconds: Int = 60,
        notes: String? = nil
    ) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.notes = notes
    }
}

// MARK: - Firebase Workout Schedule DTO

/// Schedule configuration for trainer workouts.
struct FBWorkoutSchedule: Codable {
    /// Schedule type: "once", "recurring", or "weekly".
    var type: String

    /// Specific date for "once" type schedules.
    var scheduledDate: Timestamp?

    /// Day of week (0-6, Sunday-Saturday) for "weekly" type schedules.
    var dayOfWeek: Int?

    // MARK: - Initializer

    init(
        type: String = "once",
        scheduledDate: Timestamp? = nil,
        dayOfWeek: Int? = nil
    ) {
        self.type = type
        self.scheduledDate = scheduledDate
        self.dayOfWeek = dayOfWeek
    }
}
