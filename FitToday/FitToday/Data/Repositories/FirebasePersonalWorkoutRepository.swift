//
//  FirebasePersonalWorkoutRepository.swift
//  FitToday
//
//  Implementação Firebase do PersonalWorkoutRepository.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Implementação Firebase do repositório de treinos do Personal.
actor FirebasePersonalWorkoutRepository: PersonalWorkoutRepository {
    private let firestore: Firestore
    private let collectionName = "personalWorkouts"

    init(firestore: Firestore = .firestore()) {
        self.firestore = firestore
    }

    // MARK: - PersonalWorkoutRepository

    func fetchWorkouts(for userId: String) async throws -> [PersonalWorkout] {
        let snapshot = try await firestore
            .collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            try? decodeWorkout(from: document)
        }
    }

    func markAsViewed(_ workoutId: String) async throws {
        try await firestore
            .collection(collectionName)
            .document(workoutId)
            .updateData([
                "viewedAt": FieldValue.serverTimestamp()
            ])
    }

    nonisolated func observeWorkouts(for userId: String) -> AsyncStream<[PersonalWorkout]> {
        AsyncStream { continuation in
            let listener = Firestore.firestore()
                .collection("personalWorkouts")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else {
                        if let error {
                            #if DEBUG
                            print("[PersonalWorkoutRepository] Snapshot error: \(error)")
                            #endif
                        }
                        return
                    }

                    let workouts = documents.compactMap { document -> PersonalWorkout? in
                        Self.decodeWorkoutStatic(from: document)
                    }

                    continuation.yield(workouts)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Private Helpers

    private func decodeWorkout(from document: QueryDocumentSnapshot) throws -> PersonalWorkout {
        let data = document.data()

        guard let trainerId = data["trainerId"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let fileURL = data["fileURL"] as? String,
              let fileTypeRaw = data["fileType"] as? String,
              let fileType = PersonalWorkout.FileType(rawValue: fileTypeRaw),
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            throw PersonalWorkoutRepositoryError.decodingFailed
        }

        let description = data["description"] as? String
        let viewedAtTimestamp = data["viewedAt"] as? Timestamp

        return PersonalWorkout(
            id: document.documentID,
            trainerId: trainerId,
            userId: userId,
            title: title,
            description: description,
            fileURL: fileURL,
            fileType: fileType,
            createdAt: createdAtTimestamp.dateValue(),
            viewedAt: viewedAtTimestamp?.dateValue()
        )
    }

    /// Static version for use in nonisolated context.
    private static func decodeWorkoutStatic(from document: QueryDocumentSnapshot) -> PersonalWorkout? {
        let data = document.data()

        guard let trainerId = data["trainerId"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let fileURL = data["fileURL"] as? String,
              let fileTypeRaw = data["fileType"] as? String,
              let fileType = PersonalWorkout.FileType(rawValue: fileTypeRaw),
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }

        let description = data["description"] as? String
        let viewedAtTimestamp = data["viewedAt"] as? Timestamp

        return PersonalWorkout(
            id: document.documentID,
            trainerId: trainerId,
            userId: userId,
            title: title,
            description: description,
            fileURL: fileURL,
            fileType: fileType,
            createdAt: createdAtTimestamp.dateValue(),
            viewedAt: viewedAtTimestamp?.dateValue()
        )
    }
}

// MARK: - Errors

enum PersonalWorkoutRepositoryError: LocalizedError {
    case decodingFailed
    case workoutNotFound

    var errorDescription: String? {
        switch self {
        case .decodingFailed:
            return "Erro ao decodificar treino do Personal."
        case .workoutNotFound:
            return "Treino não encontrado."
        }
    }
}
