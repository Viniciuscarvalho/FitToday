//
//  LeagueMapper.swift
//  FitToday
//

import Foundation
import FirebaseFirestore

// MARK: - FBLeague to Domain

extension FBLeague {
    /// Maps a Firestore league document and its members to a domain `League`.
    /// Ranks are computed by sorting members by weeklyXP descending.
    func toDomain(members: [FBLeagueMember], currentUserId: String) -> League {
        let sortedMembers = members
            .sorted { $0.weeklyXP > $1.weeklyXP }
            .enumerated()
            .map { index, fbMember in
                fbMember.toDomain(rank: index + 1, currentUserId: currentUserId)
            }

        return League(
            id: id ?? "",
            tier: LeagueTier(rawValue: tier) ?? .bronze,
            seasonWeek: seasonWeek,
            members: sortedMembers,
            startDate: startDate?.dateValue() ?? Date(),
            endDate: endDate?.dateValue() ?? Date()
        )
    }
}

// MARK: - FBLeagueMember to Domain

extension FBLeagueMember {
    /// Maps a Firestore league member to a domain `LeagueMember` with a computed rank.
    func toDomain(rank: Int, currentUserId: String) -> LeagueMember {
        LeagueMember(
            userId: userId,
            displayName: displayName,
            avatarURL: avatarURL.flatMap { URL(string: $0) },
            weeklyXP: weeklyXP,
            rank: rank,
            isCurrentUser: userId == currentUserId
        )
    }
}
