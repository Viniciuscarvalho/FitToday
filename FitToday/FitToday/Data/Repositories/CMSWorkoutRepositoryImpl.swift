//
//  CMSWorkoutRepositoryImpl.swift
//  FitToday
//
//  Implementation of CMSWorkoutRepository using CMSWorkoutService.
//

import Foundation

// MARK: - CMS Workout Repository Implementation

/// Concrete implementation of CMSWorkoutRepository.
///
/// Uses CMSWorkoutService for API calls and CMSWorkoutMapper for
/// converting DTOs to domain models.
final class CMSWorkoutRepositoryImpl: CMSWorkoutRepository, @unchecked Sendable {

    // MARK: - Properties

    private let service: CMSWorkoutService

    // MARK: - Initialization

    init(service: CMSWorkoutService) {
        self.service = service
    }

    // MARK: - Fetch Operations

    func fetchWorkouts(
        studentId: String,
        trainerId: String?,
        page: Int,
        limit: Int
    ) async throws -> (workouts: [TrainerWorkout], hasMore: Bool) {
        let response = try await service.fetchWorkouts(
            studentId: studentId,
            trainerId: trainerId,
            page: page,
            limit: limit
        )

        let workouts = response.workouts.map(CMSWorkoutMapper.toDomain)
        return (workouts: workouts, hasMore: response.hasMore)
    }

    func fetchWorkout(id: String) async throws -> TrainerWorkout {
        let cms = try await service.fetchWorkout(id: id)
        return CMSWorkoutMapper.toDomain(cms)
    }

    func fetchWorkoutPlan(id: String) async throws -> WorkoutPlan {
        let cms = try await service.fetchWorkout(id: id)
        return CMSWorkoutMapper.toWorkoutPlan(cms)
    }

    // MARK: - Progress Operations

    func fetchProgress(workoutId: String) async throws -> CMSWorkoutProgress {
        try await service.fetchProgress(workoutId: workoutId)
    }

    // MARK: - Feedback Operations

    func fetchFeedback(workoutId: String) async throws -> [CMSWorkoutFeedback] {
        try await service.fetchFeedback(workoutId: workoutId)
    }

    func postFeedback(
        workoutId: String,
        type: CMSFeedbackType,
        message: String,
        rating: Int?
    ) async throws -> CMSWorkoutFeedback {
        let request = CMSFeedbackRequest(type: type, message: message, rating: rating)
        return try await service.postFeedback(workoutId: workoutId, feedback: request)
    }

    // MARK: - Update Operations

    func markWorkoutCompleted(id: String) async throws {
        let update = CMSWorkoutUpdateRequest(status: .completed)
        _ = try await service.updateWorkout(id: id, update: update)
    }

    func archiveWorkout(id: String) async throws {
        let update = CMSWorkoutUpdateRequest(status: .archived)
        _ = try await service.updateWorkout(id: id, update: update)
    }
}
