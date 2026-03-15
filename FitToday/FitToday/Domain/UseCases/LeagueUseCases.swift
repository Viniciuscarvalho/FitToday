//
//  LeagueUseCases.swift
//  FitToday
//

import Foundation

// MARK: - Get Current League

/// Fetches the current user's active league, gated by the leagues feature flag.
final class GetCurrentLeagueUseCase: @unchecked Sendable {
    private let repository: LeagueRepository
    private let featureFlags: FeatureFlagChecking

    init(repository: LeagueRepository, featureFlags: FeatureFlagChecking) {
        self.repository = repository
        self.featureFlags = featureFlags
    }

    func execute() async throws -> League? {
        guard await featureFlags.isFeatureEnabled(.leaguesEnabled) else { return nil }
        return try await repository.getCurrentLeague()
    }
}

// MARK: - Observe League

/// Observes real-time updates for a specific league.
/// The caller is responsible for verifying the feature flag before invoking this use case.
final class ObserveLeagueUseCase: @unchecked Sendable {
    private let repository: LeagueRepository

    init(repository: LeagueRepository) {
        self.repository = repository
    }

    func execute(leagueId: String) -> AsyncThrowingStream<League, Error> {
        repository.observeLeague(leagueId: leagueId)
    }
}

// MARK: - Get League History

/// Fetches the user's league history across past season weeks, gated by the leagues feature flag.
final class GetLeagueHistoryUseCase: @unchecked Sendable {
    private let repository: LeagueRepository
    private let featureFlags: FeatureFlagChecking

    init(repository: LeagueRepository, featureFlags: FeatureFlagChecking) {
        self.repository = repository
        self.featureFlags = featureFlags
    }

    func execute() async throws -> [LeagueResult] {
        guard await featureFlags.isFeatureEnabled(.leaguesEnabled) else { return [] }
        return try await repository.getHistory()
    }
}
