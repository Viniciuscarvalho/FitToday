//
//  FirebasePersonalTrainerRepository.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation

// MARK: - Firebase Personal Trainer Repository

/// Firebase implementation of personal trainer and trainer-student repositories.
///
/// Uses `FirebasePersonalTrainerService` for Firestore operations and
/// `PersonalTrainerMapper` for DTO-to-domain conversions.
final class FirebasePersonalTrainerRepository: PersonalTrainerRepository, TrainerStudentRepository, @unchecked Sendable {

    private let service: FirebasePersonalTrainerService

    // MARK: - Initialization

    init(service: FirebasePersonalTrainerService = FirebasePersonalTrainerService()) {
        self.service = service
    }

    // MARK: - PersonalTrainerRepository

    func fetchTrainer(id: String) async throws -> PersonalTrainer {
        do {
            let fbTrainer = try await service.fetchTrainer(id: id)
            return PersonalTrainerMapper.toDomain(fbTrainer, id: id)
        } catch let error as NSError {
            if error.code == 404 {
                throw DomainError.notFound(resource: "Personal Trainer")
            }
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    func searchTrainers(query: String, limit: Int) async throws -> [PersonalTrainer] {
        do {
            let results = try await service.searchTrainers(query: query, limit: limit)
            return results.map { PersonalTrainerMapper.toDomain($0.1, id: $0.0) }
        } catch {
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    func findByInviteCode(_ code: String) async throws -> PersonalTrainer? {
        do {
            guard let result = try await service.findByInviteCode(code) else {
                return nil
            }
            return PersonalTrainerMapper.toDomain(result.1, id: result.0)
        } catch {
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    // MARK: - TrainerStudentRepository

    func requestConnection(
        trainerId: String,
        studentId: String,
        studentDisplayName: String
    ) async throws -> String {
        do {
            return try await service.requestConnection(
                trainerId: trainerId,
                studentId: studentId,
                studentDisplayName: studentDisplayName
            )
        } catch let error as NSError {
            switch error.code {
            case 400:
                throw DomainError.invalidInput(reason: error.localizedDescription)
            case 404:
                throw DomainError.notFound(resource: "Personal Trainer")
            case 409:
                throw DomainError.invalidInput(reason: "Connection already exists with this trainer")
            default:
                throw DomainError.repositoryFailure(reason: error.localizedDescription)
            }
        }
    }

    func cancelConnection(relationshipId: String) async throws {
        do {
            try await service.cancelConnection(relationshipId: relationshipId)
        } catch {
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    func getCurrentRelationship(studentId: String) async throws -> TrainerStudentRelationship? {
        do {
            guard let result = try await service.getCurrentRelationship(studentId: studentId) else {
                return nil
            }
            return PersonalTrainerMapper.toRelationship(result.1, id: result.0)
        } catch {
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    func observeRelationship(studentId: String) -> AsyncStream<TrainerStudentRelationship?> {
        AsyncStream { continuation in
            Task {
                let stream = await service.observeRelationship(studentId: studentId)
                for await result in stream {
                    if let (id, fbRelationship) = result {
                        let relationship = PersonalTrainerMapper.toRelationship(fbRelationship, id: id)
                        continuation.yield(relationship)
                    } else {
                        continuation.yield(nil)
                    }
                }
                continuation.finish()
            }
        }
    }
}
