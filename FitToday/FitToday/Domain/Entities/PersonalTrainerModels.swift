//
//  PersonalTrainerModels.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation

// MARK: - Personal Trainer

/// Represents a personal trainer in the CMS integration system.
///
/// Personal trainers can create workout plans through the CMS portal and
/// connect with students (app users) to deliver personalized training programs.
struct PersonalTrainer: Sendable, Identifiable, Hashable, Codable {
    /// Unique identifier for the trainer (Firebase UID).
    let id: String

    /// Display name shown to students.
    var displayName: String

    /// Trainer's email address.
    var email: String

    /// URL to the trainer's profile photo.
    var photoURL: URL?

    /// Areas of expertise (e.g., "strength", "weight_loss", "flexibility").
    var specializations: [String]

    /// Short biography or description.
    var bio: String?

    /// Whether the trainer is currently accepting new students.
    var isActive: Bool

    /// Unique invite code students can use to connect.
    var inviteCode: String?

    /// Maximum number of students this trainer can manage.
    var maxStudents: Int

    /// Current number of connected students.
    var currentStudentCount: Int

    /// Whether the trainer can accept more students.
    var canAcceptStudents: Bool {
        isActive && currentStudentCount < maxStudents
    }
}

// MARK: - Trainer Student Relationship

/// Represents the connection between a personal trainer and a student.
///
/// This relationship tracks the lifecycle from initial request through
/// active training to potential cancellation.
struct TrainerStudentRelationship: Sendable, Identifiable, Hashable, Codable {
    /// Unique identifier for this relationship.
    let id: String

    /// The personal trainer's identifier.
    let trainerId: String

    /// The student's identifier (app user).
    let studentId: String

    /// Current status of the connection.
    var status: TrainerConnectionStatus

    /// Who initiated the connection request.
    let requestedBy: RequestedBy

    /// When the connection was requested.
    let requestedAt: Date

    /// When the connection was accepted (nil if still pending).
    var acceptedAt: Date?

    /// Current subscription status for this relationship.
    var subscriptionStatus: TrainerSubscriptionStatus

    /// When the subscription expires (nil for unlimited).
    var subscriptionExpiresAt: Date?

    /// Whether the relationship is currently active and valid.
    var isValid: Bool {
        status == .active && (subscriptionStatus == .active || subscriptionStatus == .trial)
    }
}

// MARK: - Connection Status

/// Status of the trainer-student connection.
enum TrainerConnectionStatus: String, Sendable, CaseIterable, Codable {
    /// Connection request is pending approval.
    case pending

    /// Connection is active and trainer can assign workouts.
    case active

    /// Connection is temporarily paused.
    case paused

    /// Connection has been cancelled by either party.
    case cancelled
}

// MARK: - Subscription Status

/// Subscription status for the trainer-student relationship.
enum TrainerSubscriptionStatus: String, Sendable, CaseIterable, Codable {
    /// Student is in trial period.
    case trial

    /// Subscription is active and paid.
    case active

    /// Subscription has expired.
    case expired
}

// MARK: - Request Initiator

/// Who initiated the trainer-student connection request.
enum RequestedBy: String, Sendable, CaseIterable, Codable {
    /// Student requested connection with trainer.
    case student

    /// Trainer invited the student.
    case trainer
}

// MARK: - Trainer Workout

/// Represents a workout assigned by a personal trainer to a student.
///
/// This is a domain model that wraps trainer-created workout data with
/// attribution and scheduling information. It can be converted to a
/// `WorkoutPlan` for execution in the app.
struct TrainerWorkout: Sendable, Identifiable, Hashable, Codable {
    /// Unique identifier for this workout.
    let id: String

    /// The trainer who created this workout.
    let trainerId: String

    /// Workout title/name.
    var title: String

    /// Optional description of the workout.
    var description: String?

    /// Focus area of the workout.
    var focus: DailyFocus

    /// Estimated duration in minutes.
    var estimatedDurationMinutes: Int

    /// Workout intensity level.
    var intensity: WorkoutIntensity

    /// Workout phases containing exercises.
    var phases: [TrainerWorkoutPhase]

    /// Schedule configuration for the workout.
    var schedule: TrainerWorkoutSchedule

    /// Whether the workout is currently active.
    var isActive: Bool

    /// When the workout was created.
    var createdAt: Date

    /// Version number for tracking updates.
    var version: Int

    /// Optional PDF URL for the workout attachment.
    var pdfUrl: String?
}

// MARK: - Trainer Workout Phase

/// Represents a phase/section within a trainer workout.
struct TrainerWorkoutPhase: Sendable, Hashable, Codable {
    /// Phase name (e.g., "Warmup", "Main Set", "Cooldown").
    var name: String

    /// Items/exercises in this phase.
    var items: [TrainerWorkoutItem]
}

// MARK: - Trainer Workout Item

/// Represents an individual exercise within a trainer workout phase.
struct TrainerWorkoutItem: Sendable, Hashable, Codable {
    /// Optional exercise ID from external sources.
    var exerciseId: Int?

    /// Exercise name.
    var exerciseName: String

    /// Number of sets to perform.
    var sets: Int

    /// Rep range (e.g., lower: 8, upper: 12).
    var reps: IntRange

    /// Rest period between sets in seconds.
    var restSeconds: Int

    /// Optional notes or instructions.
    var notes: String?
}

// MARK: - Trainer Workout Schedule

/// Schedule configuration for trainer workouts.
struct TrainerWorkoutSchedule: Sendable, Hashable, Codable {
    /// Schedule type.
    var type: TrainerWorkoutScheduleType

    /// Specific date for "once" type schedules.
    var scheduledDate: Date?

    /// Day of week (0-6, Sunday-Saturday) for "weekly" type schedules.
    var dayOfWeek: Int?
}

// MARK: - Trainer Workout Schedule Type

/// Type of schedule for trainer workouts.
enum TrainerWorkoutScheduleType: String, Sendable, CaseIterable, Codable {
    /// One-time scheduled workout.
    case once

    /// Recurring workout.
    case recurring

    /// Weekly scheduled workout.
    case weekly
}
