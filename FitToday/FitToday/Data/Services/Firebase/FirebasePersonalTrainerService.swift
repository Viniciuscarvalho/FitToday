//
//  FirebasePersonalTrainerService.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import FirebaseFirestore
import Foundation

// MARK: - FirebasePersonalTrainerService

/// Actor-based service for Firebase personal trainer operations.
///
/// Handles all Firestore interactions for personal trainers and
/// trainer-student relationships.
actor FirebasePersonalTrainerService {
    private let db = Firestore.firestore()

    // MARK: - Collection References

    private var trainersCollection: CollectionReference {
        db.collection("personalTrainers")
    }

    private var relationshipsCollection: CollectionReference {
        db.collection("trainerStudents")
    }

    // MARK: - Fetch Trainer

    /// Fetches a personal trainer by their ID.
    ///
    /// - Parameter id: The trainer's document ID.
    /// - Returns: The Firebase trainer DTO.
    /// - Throws: An error if the trainer is not found or fetch fails.
    func fetchTrainer(id: String) async throws -> FBPersonalTrainer {
        let snapshot = try await trainersCollection.document(id).getDocument()

        guard snapshot.exists else {
            throw NSError(
                domain: "FirebasePersonalTrainerService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Personal trainer not found"]
            )
        }

        return try snapshot.data(as: FBPersonalTrainer.self)
    }

    // MARK: - Search Trainers

    /// Searches for personal trainers by display name.
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - limit: Maximum number of results to return.
    /// - Returns: An array of tuples containing document IDs and trainer DTOs.
    func searchTrainers(query: String, limit: Int) async throws -> [(String, FBPersonalTrainer)] {
        // Use Firestore's prefix query for display name search
        let normalizedQuery = query.lowercased()
        let endQuery = normalizedQuery + "\u{f8ff}"

        let snapshot = try await trainersCollection
            .whereField("isActive", isEqualTo: true)
            .whereField("displayName", isGreaterThanOrEqualTo: normalizedQuery)
            .whereField("displayName", isLessThanOrEqualTo: endQuery)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { doc -> (String, FBPersonalTrainer)? in
            let trainer = try doc.data(as: FBPersonalTrainer.self)
            return (doc.documentID, trainer)
        }
    }

    // MARK: - Find by Invite Code

    /// Finds a personal trainer by their unique invite code.
    ///
    /// - Parameter code: The invite code to search for.
    /// - Returns: A tuple containing the document ID and trainer DTO, or nil if not found.
    func findByInviteCode(_ code: String) async throws -> (String, FBPersonalTrainer)? {
        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let snapshot = try await trainersCollection
            .whereField("inviteCode", isEqualTo: normalizedCode)
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else {
            return nil
        }

        let trainer = try doc.data(as: FBPersonalTrainer.self)
        return (doc.documentID, trainer)
    }

    // MARK: - Request Connection

    /// Creates a connection request from a student to a trainer.
    ///
    /// - Parameters:
    ///   - trainerId: The trainer's document ID.
    ///   - studentId: The student's user ID.
    ///   - studentDisplayName: The student's display name (for notifications).
    /// - Returns: The document ID of the created relationship.
    /// - Throws: An error if the trainer is not found or cannot accept students.
    func requestConnection(
        trainerId: String,
        studentId: String,
        studentDisplayName: String
    ) async throws -> String {
        // Verify trainer exists and can accept students
        let trainer = try await fetchTrainer(id: trainerId)

        guard trainer.isActive else {
            throw NSError(
                domain: "FirebasePersonalTrainerService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Trainer is not currently accepting students"]
            )
        }

        guard trainer.currentStudentCount < trainer.maxStudents else {
            throw NSError(
                domain: "FirebasePersonalTrainerService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Trainer has reached maximum student capacity"]
            )
        }

        // Check if relationship already exists
        let existingRelationship = try await getCurrentRelationship(studentId: studentId)
        if let existing = existingRelationship {
            if existing.1.trainerId == trainerId && existing.1.status != TrainerConnectionStatus.cancelled.rawValue {
                throw NSError(
                    domain: "FirebasePersonalTrainerService",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: "Connection already exists with this trainer"]
                )
            }
        }

        // Create new relationship
        let relationshipRef = relationshipsCollection.document()
        let relationship = FBTrainerStudent(
            id: relationshipRef.documentID,
            trainerId: trainerId,
            studentId: studentId,
            status: TrainerConnectionStatus.pending.rawValue,
            requestedBy: RequestedBy.student.rawValue,
            requestedAt: nil, // ServerTimestamp will set this
            acceptedAt: nil,
            subscriptionStatus: TrainerSubscriptionStatus.trial.rawValue,
            subscriptionExpiresAt: nil,
            createdAt: nil
        )

        try relationshipRef.setData(from: relationship)

        #if DEBUG
        print("[PersonalTrainerService] Created connection request from \(studentDisplayName) to trainer \(trainerId)")
        #endif

        return relationshipRef.documentID
    }

    // MARK: - Cancel Connection

    /// Cancels an existing trainer-student connection.
    ///
    /// - Parameter relationshipId: The document ID of the relationship to cancel.
    func cancelConnection(relationshipId: String) async throws {
        try await relationshipsCollection.document(relationshipId).updateData([
            "status": TrainerConnectionStatus.cancelled.rawValue
        ])

        #if DEBUG
        print("[PersonalTrainerService] Cancelled connection \(relationshipId)")
        #endif
    }

    // MARK: - Observe Relationship

    /// Observes changes to a student's trainer relationship in real-time.
    ///
    /// - Parameter studentId: The student's user ID.
    /// - Returns: An async stream emitting relationship updates or nil.
    func observeRelationship(studentId: String) -> AsyncStream<(String, FBTrainerStudent)?> {
        AsyncStream { continuation in
            let listener = relationshipsCollection
                .whereField("studentId", isEqualTo: studentId)
                .whereField("status", in: [
                    TrainerConnectionStatus.pending.rawValue,
                    TrainerConnectionStatus.active.rawValue,
                    TrainerConnectionStatus.paused.rawValue
                ])
                .limit(to: 1)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        #if DEBUG
                        print("[PersonalTrainerService] Observe error: \(error.localizedDescription)")
                        #endif
                        return
                    }

                    guard let snapshot = snapshot,
                          let doc = snapshot.documents.first else {
                        continuation.yield(nil)
                        return
                    }

                    do {
                        let relationship = try doc.data(as: FBTrainerStudent.self)
                        continuation.yield((doc.documentID, relationship))
                    } catch {
                        #if DEBUG
                        print("[PersonalTrainerService] Parse error: \(error.localizedDescription)")
                        #endif
                        continuation.yield(nil)
                    }
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Get Current Relationship

    /// Fetches the current active relationship for a student.
    ///
    /// - Parameter studentId: The student's user ID.
    /// - Returns: A tuple containing the document ID and relationship DTO, or nil.
    func getCurrentRelationship(studentId: String) async throws -> (String, FBTrainerStudent)? {
        let snapshot = try await relationshipsCollection
            .whereField("studentId", isEqualTo: studentId)
            .whereField("status", in: [
                TrainerConnectionStatus.pending.rawValue,
                TrainerConnectionStatus.active.rawValue,
                TrainerConnectionStatus.paused.rawValue
            ])
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else {
            return nil
        }

        let relationship = try doc.data(as: FBTrainerStudent.self)
        return (doc.documentID, relationship)
    }
}
