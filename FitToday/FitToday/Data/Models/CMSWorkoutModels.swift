//
//  CMSWorkoutModels.swift
//  FitToday
//
//  DTOs for CMS Personal Trainer API integration.
//  Supports endpoints: /api/workouts, /api/workouts/[id], progress, feedback
//

import Foundation

// MARK: - CMS Workout Response

/// Response wrapper for paginated workout lists from CMS API.
struct CMSWorkoutListResponse: Codable, Sendable {
    let workouts: [CMSWorkout]
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case workouts
        case total
        case page
        case limit
        case hasMore = "has_more"
    }
}

// MARK: - CMS Workout DTO

/// DTO for workout data from CMS API.
/// Matches: GET /api/workouts and GET /api/workouts/[id]
struct CMSWorkout: Codable, Sendable, Identifiable {
    let id: String
    let trainerId: String
    let studentId: String
    let title: String
    let description: String?
    let focus: String
    let estimatedDurationMinutes: Int
    let intensity: String
    let phases: [CMSWorkoutPhase]
    let schedule: CMSWorkoutSchedule?
    let status: CMSWorkoutStatus
    let pdfUrl: String?
    let version: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case trainerId = "trainer_id"
        case studentId = "student_id"
        case title
        case description
        case focus
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case intensity
        case phases
        case schedule
        case status
        case pdfUrl = "pdf_url"
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - CMS Workout Phase

/// Phase/section within a CMS workout.
struct CMSWorkoutPhase: Codable, Sendable {
    let name: String
    let order: Int
    let items: [CMSWorkoutItem]
}

// MARK: - CMS Workout Item

/// Individual exercise within a workout phase.
struct CMSWorkoutItem: Codable, Sendable {
    let id: String
    let exerciseId: Int?
    let exerciseName: String
    let sets: Int
    let reps: String
    let weight: String?
    let restSeconds: Int
    let notes: String?
    let order: Int
    let mediaUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case sets
        case reps
        case weight
        case restSeconds = "rest_seconds"
        case notes
        case order
        case mediaUrl = "media_url"
    }
}

// MARK: - CMS Workout Schedule

/// Schedule configuration for CMS workouts.
struct CMSWorkoutSchedule: Codable, Sendable {
    let type: String
    let scheduledDate: Date?
    let dayOfWeek: Int?
    let recurrence: String?

    enum CodingKeys: String, CodingKey {
        case type
        case scheduledDate = "scheduled_date"
        case dayOfWeek = "day_of_week"
        case recurrence
    }
}

// MARK: - CMS Workout Status

/// Status of a workout in the CMS system.
enum CMSWorkoutStatus: String, Codable, Sendable {
    case draft
    case active
    case completed
    case archived
    case deleted
}

// MARK: - CMS Workout Progress

/// Progress data for a workout.
/// Matches: GET /api/workouts/[id]/progress
struct CMSWorkoutProgress: Codable, Sendable {
    let workoutId: String
    let studentId: String
    let completedSessions: Int
    let totalSessions: Int
    let lastSessionDate: Date?
    let exerciseProgress: [CMSExerciseProgress]
    let overallProgress: Double

    enum CodingKeys: String, CodingKey {
        case workoutId = "workout_id"
        case studentId = "student_id"
        case completedSessions = "completed_sessions"
        case totalSessions = "total_sessions"
        case lastSessionDate = "last_session_date"
        case exerciseProgress = "exercise_progress"
        case overallProgress = "overall_progress"
    }
}

// MARK: - CMS Exercise Progress

/// Progress for an individual exercise.
struct CMSExerciseProgress: Codable, Sendable {
    let exerciseId: String
    let exerciseName: String
    let completedSets: Int
    let targetSets: Int
    let maxWeight: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case completedSets = "completed_sets"
        case targetSets = "target_sets"
        case maxWeight = "max_weight"
        case notes
    }
}

// MARK: - CMS Feedback

/// Feedback data for a workout.
/// Matches: GET/POST /api/workouts/[id]/feedback
struct CMSWorkoutFeedback: Codable, Sendable, Identifiable {
    let id: String
    let workoutId: String
    let studentId: String
    let trainerId: String?
    let type: CMSFeedbackType
    let message: String
    let rating: Int?
    let createdAt: Date
    let repliedAt: Date?
    let replyMessage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case workoutId = "workout_id"
        case studentId = "student_id"
        case trainerId = "trainer_id"
        case type
        case message
        case rating
        case createdAt = "created_at"
        case repliedAt = "replied_at"
        case replyMessage = "reply_message"
    }
}

// MARK: - CMS Feedback Type

/// Type of feedback in the CMS system.
enum CMSFeedbackType: String, Codable, Sendable {
    case general
    case difficulty
    case exercise
    case completion
    case question
}

// MARK: - CMS Feedback Request

/// Request body for posting feedback.
/// Matches: POST /api/workouts/[id]/feedback
struct CMSFeedbackRequest: Codable, Sendable {
    let type: CMSFeedbackType
    let message: String
    let rating: Int?

    init(type: CMSFeedbackType, message: String, rating: Int? = nil) {
        self.type = type
        self.message = message
        self.rating = rating
    }
}

// MARK: - CMS Workout Update Request

/// Request body for updating a workout.
/// Matches: PATCH /api/workouts/[id]
struct CMSWorkoutUpdateRequest: Codable, Sendable {
    let status: CMSWorkoutStatus?
    let title: String?
    let description: String?

    init(status: CMSWorkoutStatus? = nil, title: String? = nil, description: String? = nil) {
        self.status = status
        self.title = title
        self.description = description
    }
}

// MARK: - CMS API Error Response

/// Error response from CMS API.
struct CMSAPIError: Codable, Sendable, LocalizedError {
    let code: String
    let message: String
    let details: String?

    var errorDescription: String? { message }
}
