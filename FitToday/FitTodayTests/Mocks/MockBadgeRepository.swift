//
//  MockBadgeRepository.swift
//  FitTodayTests
//

import Foundation
@testable import FitToday

final class MockBadgeRepository: BadgeRepository, @unchecked Sendable {
    var badges: [Badge] = []
    var savedBadges: [Badge] = []
    var shouldThrowError = false
    var updatedVisibility: [(badgeId: String, isPublic: Bool)] = []

    var getUserBadgesCalled = false
    var saveBadgeCalled = false
    var updateBadgeVisibilityCalled = false

    func getUserBadges(userId: String) async throws -> [Badge] {
        getUserBadgesCalled = true
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return badges
    }

    func saveBadge(_ badge: Badge, userId: String) async throws {
        saveBadgeCalled = true
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        savedBadges.append(badge)
        badges.append(badge)
    }

    func updateBadgeVisibility(_ badgeId: String, isPublic: Bool, userId: String) async throws {
        updateBadgeVisibilityCalled = true
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        updatedVisibility.append((badgeId, isPublic))
    }
}
