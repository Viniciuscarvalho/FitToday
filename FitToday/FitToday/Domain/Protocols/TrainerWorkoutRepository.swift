//
//  TrainerWorkoutRepository.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation

// MARK: - Trainer Workout Repository

/// Repository protocol for trainer workout operations.
///
/// Provides methods to fetch and observe workouts assigned by personal
/// trainers to students.
protocol TrainerWorkoutRepository: Sendable {

    /// Fetches all active workouts assigned to a student.
    ///
    /// - Parameter studentId: The student's unique identifier.
    /// - Returns: An array of trainer workouts assigned to the student.
    /// - Throws: An error if the fetch operation fails.
    func fetchAssignedWorkouts(studentId: String) async throws -> [TrainerWorkout]

    /// Observes changes to workouts assigned to a student in real-time.
    ///
    /// - Parameter studentId: The student's unique identifier.
    /// - Returns: An async stream emitting arrays of assigned trainer workouts.
    func observeAssignedWorkouts(studentId: String) -> AsyncStream<[TrainerWorkout]>
}
