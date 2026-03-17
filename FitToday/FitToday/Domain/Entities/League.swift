//
//  League.swift
//  FitToday
//

import Foundation

// MARK: - League

/// Represents a weekly league competition grouping users by tier.
struct League: Sendable, Identifiable {
    let id: String
    let tier: LeagueTier
    let seasonWeek: Int
    let members: [LeagueMember]
    let startDate: Date
    let endDate: Date

    /// Maximum number of members allowed in a single league.
    static let maxMembers = 30
}

// MARK: - League Member

/// A participant in a league with their weekly XP and rank.
struct LeagueMember: Sendable, Identifiable {
    let userId: String
    let displayName: String
    let avatarURL: URL?
    let weeklyXP: Int
    let rank: Int
    let isCurrentUser: Bool

    var id: String { userId }
}

// MARK: - League Result

/// The outcome of a completed league season week for the current user.
struct LeagueResult: Sendable, Identifiable {
    let id: String
    let seasonWeek: Int
    let tier: LeagueTier
    let finalRank: Int
    let promoted: Bool
    let demoted: Bool
    let xpEarned: Int
}
