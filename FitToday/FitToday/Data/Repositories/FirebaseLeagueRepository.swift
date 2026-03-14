//
//  FirebaseLeagueRepository.swift
//  FitToday
//

import Foundation

// MARK: - FirebaseLeagueRepository

final class FirebaseLeagueRepository: LeagueRepository, @unchecked Sendable {
    private let service: FirebaseLeagueService
    private let authService: FirebaseAuthService

    init(
        service: FirebaseLeagueService = FirebaseLeagueService(),
        authService: FirebaseAuthService = FirebaseAuthService()
    ) {
        self.service = service
        self.authService = authService
    }

    // MARK: - LeagueRepository

    func getCurrentLeague() async throws -> League? {
        guard let user = try await authService.getCurrentUser() else { return nil }

        guard let (fbLeague, fbMembers) = try await service.fetchCurrentLeague(userId: user.id) else {
            return nil
        }

        return fbLeague.toDomain(members: fbMembers, currentUserId: user.id)
    }

    func observeLeague(leagueId: String) -> AsyncThrowingStream<League, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [service, authService] in
                do {
                    guard let user = try await authService.getCurrentUser() else {
                        continuation.finish()
                        return
                    }

                    let stream = service.observeLeague(leagueId: leagueId)

                    for try await (fbLeague, fbMembers) in stream {
                        let league = fbLeague.toDomain(members: fbMembers, currentUserId: user.id)
                        continuation.yield(league)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func getHistory() async throws -> [LeagueResult] {
        guard let user = try await authService.getCurrentUser() else { return [] }

        let history = try await service.fetchLeagueHistory(userId: user.id)

        return history.map { fbLeague, fbMembers in
            let league = fbLeague.toDomain(members: fbMembers, currentUserId: user.id)
            let currentMember = league.members.first { $0.isCurrentUser }
            let memberCount = league.members.count
            let rank = currentMember?.rank ?? memberCount

            return LeagueResult(
                id: league.id,
                seasonWeek: league.seasonWeek,
                tier: league.tier,
                finalRank: rank,
                promoted: rank <= max(1, memberCount / 5),
                demoted: rank > memberCount - max(1, memberCount / 5),
                xpEarned: currentMember?.weeklyXP ?? 0
            )
        }
    }
}
