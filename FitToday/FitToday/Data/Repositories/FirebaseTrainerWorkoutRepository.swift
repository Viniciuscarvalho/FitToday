//
//  FirebaseTrainerWorkoutRepository.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation

// MARK: - Firebase Trainer Workout Repository

/// Firebase implementation of the trainer workout repository.
///
/// Uses `FirebaseTrainerWorkoutService` for Firestore operations and
/// `TrainerWorkoutMapper` for DTO-to-domain conversions.
final class FirebaseTrainerWorkoutRepository: TrainerWorkoutRepository, @unchecked Sendable {

    private let service: FirebaseTrainerWorkoutService

    // MARK: - Initialization

    init(service: FirebaseTrainerWorkoutService = FirebaseTrainerWorkoutService()) {
        self.service = service
    }

    // MARK: - TrainerWorkoutRepository

    func fetchAssignedWorkouts(studentId: String) async throws -> [TrainerWorkout] {
        do {
            let results = try await service.fetchAssignedWorkouts(studentId: studentId)
            return results.map { TrainerWorkoutMapper.toDomain($0.1, id: $0.0) }
        } catch {
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    func observeAssignedWorkouts(studentId: String) -> AsyncStream<[TrainerWorkout]> {
        AsyncStream { continuation in
            Task {
                let stream = await service.observeAssignedWorkouts(studentId: studentId)
                for await results in stream {
                    let workouts = results.map { TrainerWorkoutMapper.toDomain($0.1, id: $0.0) }
                    continuation.yield(workouts)
                }
                continuation.finish()
            }
        }
    }
}
