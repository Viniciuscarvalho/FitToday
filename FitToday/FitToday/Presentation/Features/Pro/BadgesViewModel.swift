//
//  BadgesViewModel.swift
//  FitToday
//

import Foundation

@MainActor @Observable
final class BadgesViewModel {
    private(set) var badges: [Badge] = []
    private(set) var isLoading = false
    private(set) var newlyUnlockedBadges: [Badge] = []
    var selectedBadge: Badge?

    private let evaluationUseCase: BadgeEvaluationUseCase
    private let badgeRepository: BadgeRepository
    private let authService: FirebaseAuthService

    init(
        evaluationUseCase: BadgeEvaluationUseCase,
        badgeRepository: BadgeRepository,
        authService: FirebaseAuthService
    ) {
        self.evaluationUseCase = evaluationUseCase
        self.badgeRepository = badgeRepository
        self.authService = authService
    }

    func loadBadges() async {
        guard let user = try? await authService.getCurrentUser() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let newBadges = try await evaluationUseCase.evaluate(userId: user.id)
            newlyUnlockedBadges = newBadges
            badges = try await evaluationUseCase.getAllBadges(userId: user.id)
        } catch {
            #if DEBUG
            print("[BadgesVM] Error loading badges: \(error)")
            #endif
        }
    }

    func updateVisibility(badgeId: String, isPublic: Bool) async {
        guard let user = try? await authService.getCurrentUser() else { return }
        do {
            try await badgeRepository.updateBadgeVisibility(badgeId, isPublic: isPublic, userId: user.id)
            if let index = badges.firstIndex(where: { $0.id == badgeId }) {
                let old = badges[index]
                badges[index] = Badge(
                    id: old.id,
                    type: old.type,
                    rarity: old.rarity,
                    unlockedAt: old.unlockedAt,
                    isPublic: isPublic
                )
            }
        } catch {
            #if DEBUG
            print("[BadgesVM] Error updating visibility: \(error)")
            #endif
        }
    }

    func clearNewlyUnlocked() {
        newlyUnlockedBadges = []
    }
}
