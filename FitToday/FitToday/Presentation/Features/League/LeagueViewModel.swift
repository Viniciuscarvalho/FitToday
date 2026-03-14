//
//  LeagueViewModel.swift
//  FitToday
//

import Foundation
import Swinject

@MainActor
@Observable
final class LeagueViewModel {
    // MARK: - State

    private(set) var league: League?
    private(set) var history: [LeagueResult] = []
    private(set) var isLoading = false
    private(set) var error: String?

    var showPromotionAnimation = false
    var showDemotionAnimation = false

    // MARK: - Dependencies

    private let resolver: Resolver
    private var observationTask: Task<Void, Never>?

    // MARK: - Computed

    var currentUserRank: Int? {
        league?.members.first(where: { $0.isCurrentUser })?.rank
    }

    var isInPromotionZone: Bool {
        guard let rank = currentUserRank else { return false }
        return rank <= 3
    }

    var isInDemotionZone: Bool {
        guard let rank = currentUserRank, let count = league?.members.count else { return false }
        return rank > count - 3
    }

    var countdownText: String {
        guard let endDate = league?.endDate else { return "" }
        let remaining = endDate.timeIntervalSince(Date())
        guard remaining > 0 else { return "league.season_ended".localized }
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        if days > 0 { return "\(days)d \(hours)h" }
        return "\(hours)h"
    }

    // MARK: - Init

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: - Actions

    func loadLeague() async {
        isLoading = true
        error = nil
        do {
            if let useCase = resolver.resolve(GetCurrentLeagueUseCase.self) {
                league = try await useCase.execute()
                if let leagueId = league?.id {
                    startObservation(leagueId: leagueId)
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadHistory() async {
        do {
            if let useCase = resolver.resolve(GetLeagueHistoryUseCase.self) {
                history = try await useCase.execute()
            }
        } catch {
            // History loading is non-critical
        }
    }

    // MARK: - Private

    private func startObservation(leagueId: String) {
        observationTask?.cancel()
        observationTask = Task {
            guard let useCase = resolver.resolve(ObserveLeagueUseCase.self) else { return }
            do {
                for try await updatedLeague in useCase.execute(leagueId: leagueId) {
                    guard !Task.isCancelled else { break }
                    self.league = updatedLeague
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }
}
