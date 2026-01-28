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

    func incrementCheckIn(challengeId: String, userId: String, displayName: String, photoURL: URL?) async throws {
        try await leaderboardService.incrementCheckIn(
            challengeId: challengeId,
            userId: userId,
            displayName: displayName,
            photoURL: photoURL
        )
    }

    func updateStreak(challengeId: String, userId: String, streakDays: Int, displayName: String, photoURL: URL?) async throws {
        try await leaderboardService.updateStreak(
            challengeId: challengeId,
            userId: userId,
            streakDays: streakDays,
            displayName: displayName,
            photoURL: photoURL
        )
    }

    func updateMemberWeeklyStats(groupId: String, userId: String, workoutMinutes: Int) async throws {
        try await leaderboardService.updateMemberWeeklyStats(
            groupId: groupId,
            userId: userId,
            workoutMinutes: workoutMinutes
        )
    }
}
