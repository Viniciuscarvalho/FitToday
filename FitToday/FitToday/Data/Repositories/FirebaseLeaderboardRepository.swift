//
//  FirebaseLeaderboardRepository.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation

// MARK: - FirebaseLeaderboardRepository

final class FirebaseLeaderboardRepository: LeaderboardRepository, @unchecked Sendable {
    private let leaderboardService: FirebaseLeaderboardService

    init(leaderboardService: FirebaseLeaderboardService = FirebaseLeaderboardService()) {
        self.leaderboardService = leaderboardService
    }

    // MARK: - LeaderboardRepository

    func getCurrentWeekChallenges(groupId: String) async throws -> [Challenge] {
        let fbChallenges = try await leaderboardService.getCurrentWeekChallenges(groupId: groupId)
        return fbChallenges.map { $0.toDomain() }
    }

    func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot> {
        leaderboardService.observeLeaderboard(groupId: groupId, type: type)
    }

    func incrementCheckIn(challengeId: String, userId: String) async throws {
        // Note: In a real implementation, we'd need to get user info from AuthRepository
        // For MVP, using minimal info
        try await leaderboardService.incrementCheckIn(
            challengeId: challengeId,
            userId: userId,
            displayName: "User", // TODO: Get from AuthRepository
            photoURL: nil
        )
    }

    func updateStreak(challengeId: String, userId: String, streakDays: Int) async throws {
        // Note: In a real implementation, we'd need to get user info from AuthRepository
        // For MVP, using minimal info
        try await leaderboardService.updateStreak(
            challengeId: challengeId,
            userId: userId,
            streakDays: streakDays,
            displayName: "User", // TODO: Get from AuthRepository
            photoURL: nil
        )
    }
}
