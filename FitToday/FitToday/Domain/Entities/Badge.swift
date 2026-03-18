//
//  Badge.swift
//  FitToday
//

import Foundation

// MARK: - Badge Rarity

enum BadgeRarity: String, Sendable, Codable, CaseIterable, Comparable {
    case common
    case rare
    case epic
    case legendary

    var displayName: String {
        NSLocalizedString("badge.rarity.\(rawValue)", comment: "Badge rarity display name")
    }

    var color: String {
        switch self {
        case .common: return "#6B7280"
        case .rare: return "#3B82F6"
        case .epic: return "#8B5CF6"
        case .legendary: return "#F59E0B"
        }
    }

    var sortOrder: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 3
        }
    }

    static func < (lhs: BadgeRarity, rhs: BadgeRarity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Badge Type

enum BadgeType: String, Sendable, Codable, CaseIterable {
    case firstWorkout
    case workouts50
    case workouts100
    case streak7
    case streak30
    case streak100
    case earlyBird
    case weekWarrior
    case monthlyConsistency

    var displayName: String {
        NSLocalizedString("badge.type.\(rawValue)", comment: "Badge type display name")
    }

    var description: String {
        NSLocalizedString("badge.type.\(rawValue).description", comment: "Badge type criteria description")
    }

    var icon: String {
        switch self {
        case .firstWorkout: return "figure.run"
        case .workouts50: return "flame"
        case .workouts100: return "flame.fill"
        case .streak7: return "bolt"
        case .streak30: return "bolt.fill"
        case .streak100: return "bolt.circle.fill"
        case .earlyBird: return "sunrise.fill"
        case .weekWarrior: return "calendar.badge.checkmark"
        case .monthlyConsistency: return "repeat.circle.fill"
        }
    }

    var defaultRarity: BadgeRarity {
        switch self {
        case .firstWorkout, .streak7: return .common
        case .workouts50, .streak30, .earlyBird, .monthlyConsistency: return .rare
        case .workouts100, .weekWarrior: return .epic
        case .streak100: return .legendary
        }
    }
}

// MARK: - Badge

struct Badge: Sendable, Identifiable, Codable, Equatable {
    let id: String
    let type: BadgeType
    let rarity: BadgeRarity
    let unlockedAt: Date?
    let isPublic: Bool

    var isUnlocked: Bool { unlockedAt != nil }

    init(
        id: String? = nil,
        type: BadgeType,
        rarity: BadgeRarity? = nil,
        unlockedAt: Date? = nil,
        isPublic: Bool = true
    ) {
        self.id = id ?? type.rawValue
        self.type = type
        self.rarity = rarity ?? type.defaultRarity
        self.unlockedAt = unlockedAt
        self.isPublic = isPublic
    }

    static func locked(type: BadgeType) -> Badge {
        Badge(type: type, unlockedAt: nil, isPublic: false)
    }

    static func unlocked(type: BadgeType, at date: Date = Date()) -> Badge {
        Badge(type: type, unlockedAt: date, isPublic: true)
    }
}
