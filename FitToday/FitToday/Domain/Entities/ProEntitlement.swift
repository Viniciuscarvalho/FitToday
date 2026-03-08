//
//  ProEntitlement.swift
//  FitToday
//

import Foundation

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, Hashable, Sendable, CaseIterable {
    case free
    case pro
    case elite

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .elite: return "Elite"
        }
    }

    /// Higher tier wins during conflict resolution
    var level: Int {
        switch self {
        case .free: return 0
        case .pro: return 1
        case .elite: return 2
        }
    }
}

// MARK: - Entitlement Source

enum EntitlementSource: String, Codable, Sendable {
    case none
    case storeKit
    case promo
    case enterprise
}

// MARK: - Pro Entitlement

struct ProEntitlement: Codable, Hashable, Sendable {
    var tier: SubscriptionTier
    var source: EntitlementSource
    var expirationDate: Date?

    // MARK: - Convenience

    var isPro: Bool { tier != .free }
    var isElite: Bool { tier == .elite }

    // MARK: - Statics

    static let free = ProEntitlement(tier: .free, source: .none, expirationDate: nil)
}
