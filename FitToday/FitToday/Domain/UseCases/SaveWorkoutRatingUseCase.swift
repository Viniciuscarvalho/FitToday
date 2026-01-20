//
//  SaveWorkoutRatingUseCase.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

/// Use case for saving a user's rating to a completed workout entry.
/// The rating is saved by updating the most recent entry matching the planId.
struct SaveWorkoutRatingUseCase: Sendable {
    private let historyRepository: WorkoutHistoryRepository

    init(historyRepository: WorkoutHistoryRepository) {
        self.historyRepository = historyRepository
    }

    /// Saves the user rating to the most recent workout entry with the given planId.
    /// - Parameters:
    ///   - rating: The user's rating for the workout (or nil to clear)
    ///   - planId: The ID of the workout plan to update
    /// - Throws: DomainError if the entry is not found or save fails
    func execute(rating: WorkoutRating?, planId: UUID) async throws {
        // Fetch recent entries to find the one with matching planId
        let recentEntries = try await historyRepository.listEntries(limit: 20, offset: 0)

        guard let index = recentEntries.firstIndex(where: { $0.planId == planId }) else {
            throw DomainError.notFound(resource: "Workout entry for planId: \(planId)")
        }

        var updatedEntry = recentEntries[index]
        updatedEntry.userRating = rating

        try await historyRepository.saveEntry(updatedEntry)
    }

    /// Saves the user rating along with completed exercises to the workout entry.
    /// - Parameters:
    ///   - rating: The user's rating for the workout
    ///   - completedExercises: List of exercises completed during the workout
    ///   - planId: The ID of the workout plan to update
    func execute(
        rating: WorkoutRating?,
        completedExercises: [CompletedExercise]?,
        planId: UUID
    ) async throws {
        let recentEntries = try await historyRepository.listEntries(limit: 20, offset: 0)

        guard let index = recentEntries.firstIndex(where: { $0.planId == planId }) else {
            throw DomainError.notFound(resource: "Workout entry for planId: \(planId)")
        }

        var updatedEntry = recentEntries[index]
        updatedEntry.userRating = rating
        updatedEntry.completedExercises = completedExercises

        try await historyRepository.saveEntry(updatedEntry)
    }
}
