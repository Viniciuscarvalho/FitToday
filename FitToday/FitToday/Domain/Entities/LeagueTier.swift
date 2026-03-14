//
//  LeagueTier.swift
//  FitToday
//

import Foundation

// MARK: - League Tier

/// Represents the competitive tiers in the league system, from bronze to legend.
enum LeagueTier: String, Sendable, Codable, CaseIterable, Comparable {
    case bronze
    case silver
    case gold
    case diamond
    case legend

    // MARK: - Display

    /// Localized display name for the tier.
    var displayName: String {
        NSLocalizedString("league.tier.\(rawValue)", comment: "League tier display name")
    }

    /// SF Symbol icon name for the tier.
    var icon: String {
        switch self {
        case .bronze: return "shield"
        case .silver: return "shield.fill"
        case .gold: return "star.circle.fill"
        case .diamond: return "diamond.fill"
        case .legend: return "crown.fill"
        }
    }

    /// Hex color string representing the tier.
    var color: String {
        switch self {
        case .bronze: return "#CD7F32"
        case .silver: return "#C0C0C0"
        case .gold: return "#FFD700"
        case .diamond: return "#B9F2FF"
        case .legend: return "#9B59B6"
        }
    }

    /// Numeric sort order used for comparison (0 = lowest).
    var sortOrder: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .diamond: return 3
        case .legend: return 4
        }
    }

    /// Minimum subscription tier required to participate in this league tier.
    var requiredTier: SubscriptionTier {
        switch self {
        case .bronze: return .free
        case .silver, .gold, .diamond: return .pro
        case .legend: return .elite
        }
    }

    // MARK: - Comparable

    static func < (lhs: LeagueTier, rhs: LeagueTier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
