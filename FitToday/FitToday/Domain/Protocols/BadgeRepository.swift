//
//  BadgeRepository.swift
//  FitToday
//

import Foundation

protocol BadgeRepository: Sendable {
    func getUserBadges(userId: String) async throws -> [Badge]
    func saveBadge(_ badge: Badge, userId: String) async throws
    func updateBadgeVisibility(_ badgeId: String, isPublic: Bool, userId: String) async throws
}
