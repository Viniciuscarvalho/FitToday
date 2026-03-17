//
//  MockLeagueRepository.swift
//  FitTodayTests
//

import Foundation
@testable import FitToday

final class MockLeagueRepository: LeagueRepository, @unchecked Sendable {
    var currentLeague: League?
    var history: [LeagueResult] = []
    var observeStream: AsyncThrowingStream<League, Error>?
    var shouldThrowError = false

    var getCurrentLeagueCalled = false
    var getHistoryCalled = false
    var observeLeagueCalled = false

    func getCurrentLeague() async throws -> League? {
        getCurrentLeagueCalled = true
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return currentLeague
    }

    func observeLeague(leagueId: String) -> AsyncThrowingStream<League, Error> {
        observeLeagueCalled = true
        return observeStream ?? AsyncThrowingStream { $0.finish() }
    }

    func getHistory() async throws -> [LeagueResult] {
        getHistoryCalled = true
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return history
    }
}
