//
//  LeaderboardViewModel.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation
import Swinject

// MARK: - LeaderboardViewModel

@MainActor
@Observable final class LeaderboardViewModel {
    // MARK: - Properties

    private(set) var checkInsLeaderboard: LeaderboardSnapshot?
    private(set) var streakLeaderboard: LeaderboardSnapshot?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    nonisolated(unsafe) private var leaderboardTask: Task<Void, Never>?
    private let resolver: Resolver

    // MARK: - Initialization

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: - Methods

    func startListening(groupId: String) {
        guard let repo = resolver.resolve(LeaderboardRepository.self) else {
            errorMessage = "Leaderboard repository not available"
            return
        }

        isLoading = true
        errorMessage = nil

        leaderboardTask = Task {
            await withTaskGroup(of: Void.self) { group in
                // Listen to check-ins leaderboard
                group.addTask {
                    for await snapshot in repo.observeLeaderboard(groupId: groupId, type: .checkIns) {
                        await MainActor.run {
                            self.checkInsLeaderboard = snapshot
                            self.isLoading = false
                        }
                    }
                }

                // Listen to streak leaderboard
                group.addTask {
                    for await snapshot in repo.observeLeaderboard(groupId: groupId, type: .streak) {
                        await MainActor.run {
                            self.streakLeaderboard = snapshot
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }

    nonisolated func stopListening() {
        leaderboardTask?.cancel()
        leaderboardTask = nil
    }

    deinit {
        stopListening()
    }
}
