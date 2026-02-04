//
//  CheckInModels.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import Foundation

// MARK: - CheckIn

/// Represents a workout check-in with a photo proof.
/// Used in group challenges for social accountability.
struct CheckIn: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let groupId: String
    let challengeId: String
    let userId: String
    var displayName: String
    var userPhotoURL: URL?
    var checkInPhotoURL: URL // Required photo proof
    let workoutEntryId: UUID
    var workoutDurationMinutes: Int
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        groupId: String,
        challengeId: String,
        userId: String,
        displayName: String,
        userPhotoURL: URL? = nil,
        checkInPhotoURL: URL,
        workoutEntryId: UUID,
        workoutDurationMinutes: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.challengeId = challengeId
        self.userId = userId
        self.displayName = displayName
        self.userPhotoURL = userPhotoURL
        self.checkInPhotoURL = checkInPhotoURL
        self.workoutEntryId = workoutEntryId
        self.workoutDurationMinutes = workoutDurationMinutes
        self.createdAt = createdAt
    }
}

// MARK: - CheckInError

/// Errors that can occur during the check-in process.
enum CheckInError: Error, LocalizedError {
    /// Workout duration is less than the minimum required (30 minutes)
    case workoutTooShort(minutes: Int)

    /// Photo is required but was not provided
    case photoRequired

    /// Failed to upload the photo to storage
    case uploadFailed(underlying: Error)

    /// No network connection available
    case networkUnavailable

    /// User is not a member of any group
    case notInGroup

    /// User has no active challenge
    case noActiveChallenge

    var errorDescription: String? {
        switch self {
        case .workoutTooShort(let minutes):
            return String(localized: "O treino deve ter pelo menos 30 minutos (atual: \(minutes) min)")
        case .photoRequired:
            return String(localized: "Foto é obrigatória para o check-in")
        case .uploadFailed:
            return String(localized: "Falha ao enviar foto. Verifique sua conexão e tente novamente.")
        case .networkUnavailable:
            return String(localized: "Sem conexão com a internet")
        case .notInGroup:
            return String(localized: "Você precisa estar em um grupo para fazer check-in")
        case .noActiveChallenge:
            return String(localized: "Nenhum desafio ativo encontrado")
        }
    }
}

// MARK: - CheckIn Constants

extension CheckIn {
    /// Minimum workout duration in minutes required for a valid check-in
    static let minimumWorkoutMinutes = 30
}
