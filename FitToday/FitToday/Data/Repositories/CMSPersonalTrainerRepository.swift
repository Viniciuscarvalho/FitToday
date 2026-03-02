//
//  CMSPersonalTrainerRepository.swift
//  FitToday
//
//  CMS-backed implementation of PersonalTrainerRepository.
//  Fetches trainers from the CMS API instead of Firebase.
//

import Foundation

final class CMSPersonalTrainerRepository: PersonalTrainerRepository, @unchecked Sendable {

    private let service: CMSTrainerService

    init(service: CMSTrainerService) {
        self.service = service
    }

    func fetchTrainer(id: String) async throws -> PersonalTrainer {
        let dto = try await service.fetchTrainer(id: id)
        return CMSTrainerMapper.toDomain(dto)
    }

    func searchTrainers(query: String, limit: Int) async throws -> [PersonalTrainer] {
        let response = try await service.fetchTrainers(limit: limit, offset: 0)
        let trainers = response.trainers
            .filter { $0.photoURL != nil && !($0.photoURL?.isEmpty ?? true) }
            .map { CMSTrainerMapper.toDomain($0) }

        guard !query.isEmpty else { return trainers }
        let normalized = query.lowercased()
        return trainers.filter { $0.displayName.lowercased().contains(normalized) }
    }

    func findByInviteCode(_ code: String) async throws -> PersonalTrainer? {
        // CMS doesn't have a dedicated invite code endpoint yet.
        // Fetch all trainers and filter locally as a fallback.
        let response = try await service.fetchTrainers(limit: 100, offset: 0)
        return response.trainers
            .first { $0.inviteCode?.uppercased() == code.uppercased() }
            .map { CMSTrainerMapper.toDomain($0) }
    }
}
