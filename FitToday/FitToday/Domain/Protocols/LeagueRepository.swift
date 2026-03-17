//
//  LeagueRepository.swift
//  FitToday
//

import Foundation

// MARK: - League Repository

/// Repository protocol for league data access.
protocol LeagueRepository: Sendable {

    /// Fetches the current user's active league, if any.
    func getCurrentLeague() async throws -> League?

    /// Observes real-time updates for a specific league.
    /// - Parameter leagueId: The identifier of the league to observe.
    /// - Returns: An async stream emitting league updates.
    func observeLeague(leagueId: String) -> AsyncThrowingStream<League, Error>

    /// Fetches the user's league history across past season weeks.
    func getHistory() async throws -> [LeagueResult]
}
