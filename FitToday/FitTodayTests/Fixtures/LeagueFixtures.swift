//
//  LeagueFixtures.swift
//  FitTodayTests
//

import Foundation
import FirebaseFirestore
@testable import FitToday

// MARK: - League Fixtures

extension League {
    static func fixture(
        id: String = "league1",
        tier: LeagueTier = .bronze,
        seasonWeek: Int = 1,
        members: [LeagueMember] = [],
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
    ) -> League {
        League(
            id: id,
            tier: tier,
            seasonWeek: seasonWeek,
            members: members,
            startDate: startDate,
            endDate: endDate
        )
    }

    static func fixtureWithMembers(
        tier: LeagueTier = .bronze,
        memberCount: Int = 10
    ) -> League {
        let members = (1...memberCount).map { index in
            LeagueMember.fixture(
                userId: "user\(index)",
                displayName: "User \(index)",
                weeklyXP: (memberCount - index + 1) * 100,
                rank: index
            )
        }
        return .fixture(tier: tier, members: members)
    }
}

// MARK: - LeagueMember Fixtures

extension LeagueMember {
    static func fixture(
        userId: String = "user1",
        displayName: String = "Test User",
        avatarURL: URL? = nil,
        weeklyXP: Int = 100,
        rank: Int = 1,
        isCurrentUser: Bool = false
    ) -> LeagueMember {
        LeagueMember(
            userId: userId,
            displayName: displayName,
            avatarURL: avatarURL,
            weeklyXP: weeklyXP,
            rank: rank,
            isCurrentUser: isCurrentUser
        )
    }
}

// MARK: - LeagueResult Fixtures

extension LeagueResult {
    static func fixture(
        id: String = "result1",
        seasonWeek: Int = 1,
        tier: LeagueTier = .bronze,
        finalRank: Int = 5,
        promoted: Bool = false,
        demoted: Bool = false,
        xpEarned: Int = 500
    ) -> LeagueResult {
        LeagueResult(
            id: id,
            seasonWeek: seasonWeek,
            tier: tier,
            finalRank: finalRank,
            promoted: promoted,
            demoted: demoted,
            xpEarned: xpEarned
        )
    }
}

// MARK: - FBLeague Fixtures

extension FBLeague {
    static func fixture(
        tier: String = "bronze",
        seasonWeek: Int = 1,
        startDate: Timestamp? = Timestamp(date: Date()),
        endDate: Timestamp? = Timestamp(date: Date().addingTimeInterval(7 * 24 * 3600))
    ) -> FBLeague {
        FBLeague(
            tier: tier,
            seasonWeek: seasonWeek,
            startDate: startDate,
            endDate: endDate
        )
    }
}

// MARK: - FBLeagueMember Fixtures

extension FBLeagueMember {
    static func fixture(
        userId: String = "user1",
        displayName: String = "Test User",
        avatarURL: String? = nil,
        weeklyXP: Int = 100
    ) -> FBLeagueMember {
        FBLeagueMember(
            userId: userId,
            displayName: displayName,
            avatarURL: avatarURL,
            weeklyXP: weeklyXP
        )
    }
}
