//
//  FirebaseTrainerWorkoutService.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import FirebaseFirestore
import Foundation

// MARK: - FirebaseTrainerWorkoutService

/// Actor-based service for Firebase trainer workout operations.
///
/// Handles all Firestore interactions for trainer-created workouts
/// assigned to students.
actor FirebaseTrainerWorkoutService {
    private let db = Firestore.firestore()

    // MARK: - Collection References

    private var workoutsCollection: CollectionReference {
        db.collection("trainerWorkouts")
    }

    // MARK: - Fetch Assigned Workouts

    /// Fetches all active workouts assigned to a student.
    ///
    /// - Parameter studentId: The student's user ID.
    /// - Returns: An array of tuples containing document IDs and workout DTOs.
    /// - Throws: An error if the fetch operation fails.
    func fetchAssignedWorkouts(studentId: String) async throws -> [(String, FBTrainerWorkout)] {
        let snapshot = try await workoutsCollection
            .whereField("assignedStudents", arrayContains: studentId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc -> (String, FBTrainerWorkout)? in
            let workout = try doc.data(as: FBTrainerWorkout.self)
            return (doc.documentID, workout)
        }
    }

    // MARK: - Observe Assigned Workouts

    /// Observes changes to workouts assigned to a student in real-time.
    ///
    /// - Parameter studentId: The student's user ID.
    /// - Returns: An async stream emitting arrays of assigned workouts.
    func observeAssignedWorkouts(studentId: String) -> AsyncStream<[(String, FBTrainerWorkout)]> {
        AsyncStream { continuation in
            let listener = workoutsCollection
                .whereField("assignedStudents", arrayContains: studentId)
                .whereField("isActive", isEqualTo: true)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        #if DEBUG
                        print("[TrainerWorkoutService] Observe error: \(error.localizedDescription)")
                        #endif
                        return
                    }

                    guard let snapshot = snapshot else {
                        continuation.yield([])
                        return
                    }

                    let workouts: [(String, FBTrainerWorkout)] = snapshot.documents.compactMap { doc in
                        do {
                            let workout = try doc.data(as: FBTrainerWorkout.self)
                            return (doc.documentID, workout)
                        } catch {
                            #if DEBUG
                            print("[TrainerWorkoutService] Parse error for doc \(doc.documentID): \(error.localizedDescription)")
                            #endif
                            return nil
                        }
                    }

                    continuation.yield(workouts)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Fetch Single Workout

    /// Fetches a single trainer workout by its ID.
    ///
    /// - Parameter id: The workout's document ID.
    /// - Returns: A tuple containing the document ID and workout DTO.
    /// - Throws: An error if the workout is not found or fetch fails.
    func fetchWorkout(id: String) async throws -> (String, FBTrainerWorkout) {
        let snapshot = try await workoutsCollection.document(id).getDocument()

        guard snapshot.exists else {
            throw NSError(
                domain: "FirebaseTrainerWorkoutService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Trainer workout not found"]
            )
        }

        let workout = try snapshot.data(as: FBTrainerWorkout.self)
        return (snapshot.documentID, workout)
    }

    // MARK: - Fetch Workouts by Trainer

    /// Fetches all workouts created by a specific trainer.
    ///
    /// - Parameters:
    ///   - trainerId: The trainer's user ID.
    ///   - activeOnly: Whether to filter for active workouts only.
    /// - Returns: An array of tuples containing document IDs and workout DTOs.
    func fetchWorkoutsByTrainer(trainerId: String, activeOnly: Bool = true) async throws -> [(String, FBTrainerWorkout)] {
        var query: Query = workoutsCollection.whereField("trainerId", isEqualTo: trainerId)

        if activeOnly {
            query = query.whereField("isActive", isEqualTo: true)
        }

        let snapshot = try await query
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc -> (String, FBTrainerWorkout)? in
            let workout = try doc.data(as: FBTrainerWorkout.self)
            return (doc.documentID, workout)
        }
    }
}
