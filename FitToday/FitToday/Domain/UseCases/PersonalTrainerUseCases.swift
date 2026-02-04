//
//  PersonalTrainerUseCases.swift
//  FitToday
//
//  Created by AI on 04/02/26.
//

import Foundation

// MARK: - Errors

enum PersonalTrainerError: LocalizedError {
    case featureDisabled
    case trainerNotFound
    case invalidInviteCode
    case alreadyConnected
    case connectionNotFound
    case unauthorized
    case networkError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "Esta funcionalidade ainda nao esta disponivel."
        case .trainerNotFound:
            return "Personal trainer nao encontrado."
        case .invalidInviteCode:
            return "Codigo de convite invalido ou expirado."
        case .alreadyConnected:
            return "Voce ja esta conectado a um personal trainer."
        case .connectionNotFound:
            return "Conexao nao encontrada."
        case .unauthorized:
            return "Voce precisa estar logado para usar esta funcionalidade."
        case .networkError(let error):
            return "Erro de conexao: \(error.localizedDescription)"
        }
    }
}

// MARK: - Discover Trainers Use Case

protocol DiscoverTrainersUseCaseProtocol: Sendable {
    func searchByName(_ query: String, limit: Int) async throws -> [PersonalTrainer]
    func findByInviteCode(_ code: String) async throws -> PersonalTrainer?
}

final class DiscoverTrainersUseCase: DiscoverTrainersUseCaseProtocol, @unchecked Sendable {
    private let repository: PersonalTrainerRepository
    private let featureFlagChecker: FeatureFlagChecking

    init(repository: PersonalTrainerRepository, featureFlagChecker: FeatureFlagChecking) {
        self.repository = repository
        self.featureFlagChecker = featureFlagChecker
    }

    func searchByName(_ query: String, limit: Int = 20) async throws -> [PersonalTrainer] {
        guard await featureFlagChecker.isFeatureEnabled(.personalTrainerEnabled) else {
            throw PersonalTrainerError.featureDisabled
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        return try await repository.searchTrainers(query: trimmedQuery, limit: limit)
    }

    func findByInviteCode(_ code: String) async throws -> PersonalTrainer? {
        guard await featureFlagChecker.isFeatureEnabled(.personalTrainerEnabled) else {
            throw PersonalTrainerError.featureDisabled
        }

        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedCode.isEmpty else {
            return nil
        }

        return try await repository.findByInviteCode(trimmedCode)
    }
}

// MARK: - Request Trainer Connection Use Case

protocol RequestTrainerConnectionUseCaseProtocol: Sendable {
    func execute(trainerId: String) async throws -> String
}

final class RequestTrainerConnectionUseCase: RequestTrainerConnectionUseCaseProtocol, @unchecked Sendable {
    private let trainerStudentRepository: TrainerStudentRepository
    private let authRepository: AuthenticationRepository
    private let featureFlagChecker: FeatureFlagChecking

    init(
        trainerStudentRepository: TrainerStudentRepository,
        authRepository: AuthenticationRepository,
        featureFlagChecker: FeatureFlagChecking
    ) {
        self.trainerStudentRepository = trainerStudentRepository
        self.authRepository = authRepository
        self.featureFlagChecker = featureFlagChecker
    }

    func execute(trainerId: String) async throws -> String {
        guard await featureFlagChecker.isFeatureEnabled(.personalTrainerEnabled) else {
            throw PersonalTrainerError.featureDisabled
        }

        guard let currentUser = try await authRepository.currentUser() else {
            throw PersonalTrainerError.unauthorized
        }

        // Check if already has an active connection
        if let existingRelationship = try await trainerStudentRepository.getCurrentRelationship(studentId: currentUser.id) {
            if existingRelationship.status == .active || existingRelationship.status == .pending {
                throw PersonalTrainerError.alreadyConnected
            }
        }

        let relationshipId = try await trainerStudentRepository.requestConnection(
            trainerId: trainerId,
            studentId: currentUser.id,
            studentDisplayName: currentUser.displayName
        )

        return relationshipId
    }
}

// MARK: - Cancel Trainer Connection Use Case

protocol CancelTrainerConnectionUseCaseProtocol: Sendable {
    func execute(relationshipId: String) async throws
}

final class CancelTrainerConnectionUseCase: CancelTrainerConnectionUseCaseProtocol, @unchecked Sendable {
    private let trainerStudentRepository: TrainerStudentRepository
    private let authRepository: AuthenticationRepository
    private let featureFlagChecker: FeatureFlagChecking

    init(
        trainerStudentRepository: TrainerStudentRepository,
        authRepository: AuthenticationRepository,
        featureFlagChecker: FeatureFlagChecking
    ) {
        self.trainerStudentRepository = trainerStudentRepository
        self.authRepository = authRepository
        self.featureFlagChecker = featureFlagChecker
    }

    func execute(relationshipId: String) async throws {
        guard await featureFlagChecker.isFeatureEnabled(.personalTrainerEnabled) else {
            throw PersonalTrainerError.featureDisabled
        }

        guard try await authRepository.currentUser() != nil else {
            throw PersonalTrainerError.unauthorized
        }

        try await trainerStudentRepository.cancelConnection(relationshipId: relationshipId)
    }
}

// MARK: - Get Current Trainer Use Case

protocol GetCurrentTrainerUseCaseProtocol: Sendable {
    func execute() async throws -> (trainer: PersonalTrainer, relationship: TrainerStudentRelationship)?
    func observeRelationship() -> AsyncStream<TrainerStudentRelationship?>
}

final class GetCurrentTrainerUseCase: GetCurrentTrainerUseCaseProtocol, @unchecked Sendable {
    private let trainerRepository: PersonalTrainerRepository
    private let trainerStudentRepository: TrainerStudentRepository
    private let authRepository: AuthenticationRepository
    private let featureFlagChecker: FeatureFlagChecking

    init(
        trainerRepository: PersonalTrainerRepository,
        trainerStudentRepository: TrainerStudentRepository,
        authRepository: AuthenticationRepository,
        featureFlagChecker: FeatureFlagChecking
    ) {
        self.trainerRepository = trainerRepository
        self.trainerStudentRepository = trainerStudentRepository
        self.authRepository = authRepository
        self.featureFlagChecker = featureFlagChecker
    }

    func execute() async throws -> (trainer: PersonalTrainer, relationship: TrainerStudentRelationship)? {
        guard await featureFlagChecker.isFeatureEnabled(.personalTrainerEnabled) else {
            return nil
        }

        guard let currentUser = try await authRepository.currentUser() else {
            return nil
        }

        guard let relationship = try await trainerStudentRepository.getCurrentRelationship(studentId: currentUser.id) else {
            return nil
        }

        guard relationship.status == .active || relationship.status == .pending else {
            return nil
        }

        guard let trainer = try? await trainerRepository.fetchTrainer(id: relationship.trainerId) else {
            return nil
        }

        return (trainer, relationship)
    }

    func observeRelationship() -> AsyncStream<TrainerStudentRelationship?> {
        AsyncStream { continuation in
            Task {
                guard await featureFlagChecker.isFeatureEnabled(.personalTrainerEnabled) else {
                    continuation.yield(nil)
                    continuation.finish()
                    return
                }

                guard let currentUser = try? await authRepository.currentUser() else {
                    continuation.yield(nil)
                    continuation.finish()
                    return
                }

                for await relationship in trainerStudentRepository.observeRelationship(studentId: currentUser.id) {
                    continuation.yield(relationship)
                }

                continuation.finish()
            }
        }
    }
}

// MARK: - Fetch Assigned Workouts Use Case

protocol FetchAssignedWorkoutsUseCaseProtocol: Sendable {
    func execute() async throws -> [TrainerWorkout]
    func observe() -> AsyncStream<[TrainerWorkout]>
}

final class FetchAssignedWorkoutsUseCase: FetchAssignedWorkoutsUseCaseProtocol, @unchecked Sendable {
    private let trainerWorkoutRepository: TrainerWorkoutRepository
    private let authRepository: AuthenticationRepository
    private let featureFlagChecker: FeatureFlagChecking

    init(
        trainerWorkoutRepository: TrainerWorkoutRepository,
        authRepository: AuthenticationRepository,
        featureFlagChecker: FeatureFlagChecking
    ) {
        self.trainerWorkoutRepository = trainerWorkoutRepository
        self.authRepository = authRepository
        self.featureFlagChecker = featureFlagChecker
    }

    func execute() async throws -> [TrainerWorkout] {
        guard await featureFlagChecker.isFeatureEnabled(.cmsWorkoutSyncEnabled) else {
            return []
        }

        guard let currentUser = try await authRepository.currentUser() else {
            return []
        }

        return try await trainerWorkoutRepository.fetchAssignedWorkouts(studentId: currentUser.id)
    }

    func observe() -> AsyncStream<[TrainerWorkout]> {
        AsyncStream { continuation in
            Task {
                guard await featureFlagChecker.isFeatureEnabled(.cmsWorkoutSyncEnabled) else {
                    continuation.yield([])
                    continuation.finish()
                    return
                }

                guard let currentUser = try? await authRepository.currentUser() else {
                    continuation.yield([])
                    continuation.finish()
                    return
                }

                for await workouts in trainerWorkoutRepository.observeAssignedWorkouts(studentId: currentUser.id) {
                    continuation.yield(workouts)
                }

                continuation.finish()
            }
        }
    }
}
