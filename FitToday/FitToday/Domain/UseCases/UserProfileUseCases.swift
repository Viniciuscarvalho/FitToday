//
//  UserProfileUseCases.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

struct CreateOrUpdateProfileUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute(_ profile: UserProfile) async throws {
        guard profile.weeklyFrequency > 0 else {
            throw DomainError.invalidInput(reason: "Frequência semanal deve ser maior que zero.")
        }
        try await repository.saveProfile(profile)
    }
}

struct GetUserProfileUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute() async throws -> UserProfile? {
        try await repository.loadProfile()
    }
}

struct ValidateDailyCheckInUseCase {
    func execute(_ checkIn: DailyCheckIn) throws -> DailyCheckIn {
        guard !checkIn.sorenessAreas.isEmpty || checkIn.sorenessLevel != .strong else {
            throw DomainError.invalidInput(reason: "Informe quais áreas estão doloridas quando selecionar dor forte.")
        }
        return checkIn
    }
}




