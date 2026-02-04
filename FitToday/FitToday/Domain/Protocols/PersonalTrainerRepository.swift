//
//  PersonalTrainerRepository.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation

// MARK: - Personal Trainer Repository

/// Repository protocol for personal trainer operations.
///
/// Provides methods to fetch and search for personal trainers.
protocol PersonalTrainerRepository: Sendable {

    /// Fetches a personal trainer by their ID.
    ///
    /// - Parameter id: The trainer's unique identifier.
    /// - Returns: The personal trainer domain model.
    /// - Throws: `DomainError.notFound` if trainer doesn't exist.
    func fetchTrainer(id: String) async throws -> PersonalTrainer

    /// Searches for personal trainers by name.
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - limit: Maximum number of results to return.
    /// - Returns: An array of matching personal trainers.
    func searchTrainers(query: String, limit: Int) async throws -> [PersonalTrainer]

    /// Finds a personal trainer by their unique invite code.
    ///
    /// - Parameter code: The invite code to search for.
    /// - Returns: The personal trainer if found, nil otherwise.
    func findByInviteCode(_ code: String) async throws -> PersonalTrainer?
}

// MARK: - Trainer Student Repository

/// Repository protocol for trainer-student relationship operations.
///
/// Manages the connection lifecycle between trainers and students.
protocol TrainerStudentRepository: Sendable {

    /// Creates a connection request from a student to a trainer.
    ///
    /// - Parameters:
    ///   - trainerId: The trainer's unique identifier.
    ///   - studentId: The student's unique identifier.
    ///   - studentDisplayName: The student's display name (for notifications).
    /// - Returns: The unique identifier of the created relationship.
    /// - Throws: An error if the connection cannot be established.
    func requestConnection(
        trainerId: String,
        studentId: String,
        studentDisplayName: String
    ) async throws -> String

    /// Cancels an existing trainer-student connection.
    ///
    /// - Parameter relationshipId: The relationship's unique identifier.
    /// - Throws: An error if the cancellation fails.
    func cancelConnection(relationshipId: String) async throws

    /// Fetches the current active relationship for a student.
    ///
    /// - Parameter studentId: The student's unique identifier.
    /// - Returns: The current relationship if one exists, nil otherwise.
    func getCurrentRelationship(studentId: String) async throws -> TrainerStudentRelationship?

    /// Observes changes to a student's trainer relationship in real-time.
    ///
    /// - Parameter studentId: The student's unique identifier.
    /// - Returns: An async stream emitting relationship updates or nil.
    func observeRelationship(studentId: String) -> AsyncStream<TrainerStudentRelationship?>
}
