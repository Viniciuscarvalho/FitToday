//
//  FirebasePersonalTrainerRepository.swift
//  FitToday
//
//  Created by Claude on 04/02/26.
//

import Foundation

// MARK: - Firebase Personal Trainer Repository

/// Implementation of personal trainer and trainer-student repositories.
///
/// Uses `CMSTrainerService` for connection API calls (POST/GET connect)
/// and `FirebasePersonalTrainerService` for real-time observation.
final class FirebasePersonalTrainerRepository: PersonalTrainerRepository, TrainerStudentRepository, @unchecked Sendable {

    private let service: FirebasePersonalTrainerService
    private let cmsService: CMSTrainerService?

    // MARK: - Initialization

    init(
        service: FirebasePersonalTrainerService = FirebasePersonalTrainerService(),
        cmsService: CMSTrainerService? = nil
    ) {
        self.service = service
        self.cmsService = cmsService
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
        studentDisplayName: String,
        message: String?
    ) async throws -> String {
        guard let cmsService else {
            throw DomainError.repositoryFailure(reason: "CMS service not available")
        }

        do {
            // Ensure the user has role "student" in the CMS before connecting
            #if DEBUG
            print("[Repository] ensureStudentRole for: \(studentDisplayName)")
            #endif
            try await cmsService.ensureStudentRole(displayName: studentDisplayName)

            #if DEBUG
            print("[Repository] requestConnection to trainer: \(trainerId)")
            #endif
            let request = CMSConnectionRequest(message: message)
            let response = try await cmsService.requestConnection(
                trainerId: trainerId,
                connection: request
            )
            #if DEBUG
            print("[Repository] Connection created with id: \(response.id)")
            #endif
            return response.id
        } catch let error as CMSServiceError {
            #if DEBUG
            print("[Repository] CMSServiceError: \(error)")
            #endif
            switch error {
            case .unexpectedStatus(409):
                throw DomainError.invalidInput(reason: "Connection already exists with this trainer")
            default:
                throw DomainError.repositoryFailure(reason: error.localizedDescription)
            }
        } catch {
            #if DEBUG
            print("[Repository] Unexpected error type: \(type(of: error)) — \(error)")
            #endif
            throw DomainError.repositoryFailure(reason: error.localizedDescription)
        }
    }

    func cancelConnection(connectionId: String, reason: String?) async throws {
        guard let cmsService else {
            // Fallback to Firebase if CMS not available
            do {
                try await service.cancelConnection(relationshipId: connectionId)
            } catch {
                throw DomainError.repositoryFailure(reason: error.localizedDescription)
            }
            return
        }

        do {
            _ = try await cmsService.updateConnection(
                connectionId: connectionId,
                action: "cancel",
                reason: reason
            )
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
