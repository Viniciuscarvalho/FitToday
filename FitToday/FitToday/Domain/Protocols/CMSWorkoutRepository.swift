//
//  CMSWorkoutRepository.swift
//  FitToday
//
//  Protocol for CMS workout data access.
//

import Foundation

// MARK: - CMS Workout Repository Protocol

/// Protocol for accessing CMS workout data.
///
/// Provides methods for fetching, updating, and managing trainer workouts
/// from the CMS Personal Trainer system.
protocol CMSWorkoutRepository: Sendable {

    // MARK: - Fetch Operations

    /// Fetches workouts for a student from the CMS.
    ///
    /// - Parameters:
    ///   - studentId: The student's user ID.
    ///   - trainerId: Optional trainer ID to filter by.
    ///   - page: Page number for pagination.
    ///   - limit: Number of items per page.
    /// - Returns: A tuple containing the workouts and pagination info.
    func fetchWorkouts(
        studentId: String,
        trainerId: String?,
        page: Int,
        limit: Int
    ) async throws -> (workouts: [TrainerWorkout], hasMore: Bool)

    /// Fetches a single workout by ID.
    ///
    /// - Parameter id: The workout ID.
    /// - Returns: The TrainerWorkout if found.
    func fetchWorkout(id: String) async throws -> TrainerWorkout

    /// Fetches a workout as an executable WorkoutPlan.
    ///
    /// - Parameter id: The workout ID.
    /// - Returns: A WorkoutPlan ready for workout execution.
    func fetchWorkoutPlan(id: String) async throws -> WorkoutPlan

    // MARK: - Progress Operations

    /// Fetches the student's progress for a workout.
    ///
    /// - Parameter workoutId: The workout ID.
    /// - Returns: The progress data.
    func fetchProgress(workoutId: String) async throws -> CMSWorkoutProgress

    // MARK: - Feedback Operations

    /// Fetches all feedback for a workout.
    ///
    /// - Parameter workoutId: The workout ID.
    /// - Returns: An array of feedback items.
    func fetchFeedback(workoutId: String) async throws -> [CMSWorkoutFeedback]

    /// Posts new feedback for a workout.
    ///
    /// - Parameters:
    ///   - workoutId: The workout ID.
    ///   - type: The feedback type.
    ///   - message: The feedback message.
    ///   - rating: Optional rating (1-5).
    /// - Returns: The created feedback.
    func postFeedback(
        workoutId: String,
        type: CMSFeedbackType,
        message: String,
        rating: Int?
    ) async throws -> CMSWorkoutFeedback

    // MARK: - Student Registration

    /// Registers the current user as a student in the CMS for a trainer.
    ///
    /// - Parameters:
    ///   - firebaseUid: The student's Firebase UID.
    ///   - trainerId: The trainer's ID.
    ///   - displayName: The student's display name.
    ///   - email: The student's email (optional).
    func registerStudent(
        firebaseUid: String,
        trainerId: String,
        displayName: String,
        email: String?
    ) async throws

    // MARK: - Update Operations

    /// Marks a workout as completed.
    ///
    /// - Parameter id: The workout ID.
    func markWorkoutCompleted(id: String) async throws

    /// Archives a workout (soft delete from student view).
    ///
    /// - Parameter id: The workout ID.
    func archiveWorkout(id: String) async throws
}
