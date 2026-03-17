//
//  FBBadge.swift
//  FitToday
//

import FirebaseFirestore
import Foundation

struct FBBadge: Codable, Sendable {
    @DocumentID var id: String?
    let type: String
    let rarity: String
    let unlockedAt: Timestamp?
    let isPublic: Bool
}

// MARK: - Domain Mapping

extension FBBadge {
    func toDomain() -> Badge {
        Badge(
            id: id ?? type,
            type: BadgeType(rawValue: type) ?? .firstWorkout,
            rarity: BadgeRarity(rawValue: rarity) ?? .common,
            unlockedAt: unlockedAt?.dateValue(),
            isPublic: isPublic
        )
    }

    static func fromDomain(_ badge: Badge) -> FBBadge {
        FBBadge(
            type: badge.type.rawValue,
            rarity: badge.rarity.rawValue,
            unlockedAt: badge.unlockedAt.map { Timestamp(date: $0) },
            isPublic: badge.isPublic
        )
    }
}
