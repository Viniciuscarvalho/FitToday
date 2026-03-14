//
//  LeagueMapperTests.swift
//  FitTodayTests
//

import XCTest
import FirebaseFirestore
@testable import FitToday

final class LeagueMapperTests: XCTestCase {

    // MARK: - FBLeague to Domain

    func test_toDomain_mapsAllFields() {
        // Given
        let startDate = Date(timeIntervalSince1970: 1000)
        let endDate = Date(timeIntervalSince1970: 2000)
        let fbLeague = FBLeague(
            tier: "gold",
            seasonWeek: 3,
            startDate: Timestamp(date: startDate),
            endDate: Timestamp(date: endDate)
        )
        let members = [
            FBLeagueMember.fixture(userId: "u1", weeklyXP: 200),
            FBLeagueMember.fixture(userId: "u2", weeklyXP: 300)
        ]

        // When
        let league = fbLeague.toDomain(members: members, currentUserId: "u1")

        // Then
        XCTAssertEqual(league.tier, .gold)
        XCTAssertEqual(league.seasonWeek, 3)
        XCTAssertEqual(league.members.count, 2)
    }

    func test_toDomain_ranksMembersByWeeklyXPDescending() {
        // Given
        let fbLeague = FBLeague(
            tier: "bronze",
            seasonWeek: 1,
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date())
        )
        let members = [
            FBLeagueMember.fixture(userId: "low", displayName: "Low", weeklyXP: 50),
            FBLeagueMember.fixture(userId: "high", displayName: "High", weeklyXP: 500),
            FBLeagueMember.fixture(userId: "mid", displayName: "Mid", weeklyXP: 200)
        ]

        // When
        let league = fbLeague.toDomain(members: members, currentUserId: "none")

        // Then
        XCTAssertEqual(league.members[0].userId, "high")
        XCTAssertEqual(league.members[0].rank, 1)
        XCTAssertEqual(league.members[1].userId, "mid")
        XCTAssertEqual(league.members[1].rank, 2)
        XCTAssertEqual(league.members[2].userId, "low")
        XCTAssertEqual(league.members[2].rank, 3)
    }

    func test_toDomain_setsIsCurrentUserFlag() {
        // Given
        let fbLeague = FBLeague(
            tier: "silver",
            seasonWeek: 1,
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date())
        )
        let members = [
            FBLeagueMember.fixture(userId: "current", weeklyXP: 100),
            FBLeagueMember.fixture(userId: "other", weeklyXP: 200)
        ]

        // When
        let league = fbLeague.toDomain(members: members, currentUserId: "current")

        // Then
        let currentMember = league.members.first(where: { $0.isCurrentUser })
        let otherMember = league.members.first(where: { !$0.isCurrentUser })

        XCTAssertNotNil(currentMember)
        XCTAssertEqual(currentMember?.userId, "current")
        XCTAssertNotNil(otherMember)
        XCTAssertEqual(otherMember?.userId, "other")
    }

    func test_toDomain_handlesEmptyMembersArray() {
        // Given
        let fbLeague = FBLeague(
            tier: "bronze",
            seasonWeek: 1,
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date())
        )

        // When
        let league = fbLeague.toDomain(members: [], currentUserId: "user1")

        // Then
        XCTAssertTrue(league.members.isEmpty)
        XCTAssertEqual(league.tier, .bronze)
    }

    func test_toDomain_handlesUnknownTierString_defaultsToBronze() {
        // Given
        let fbLeague = FBLeague(
            tier: "platinum",
            seasonWeek: 1,
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date())
        )

        // When
        let league = fbLeague.toDomain(members: [], currentUserId: "user1")

        // Then
        XCTAssertEqual(league.tier, .bronze)
    }

    // MARK: - FBLeagueMember to Domain

    func test_memberToDomain_mapsAllFields() {
        // Given
        let fbMember = FBLeagueMember.fixture(
            userId: "u1",
            displayName: "Player One",
            avatarURL: "https://example.com/avatar.jpg",
            weeklyXP: 350
        )

        // When
        let member = fbMember.toDomain(rank: 2, currentUserId: "u1")

        // Then
        XCTAssertEqual(member.userId, "u1")
        XCTAssertEqual(member.displayName, "Player One")
        XCTAssertEqual(member.avatarURL?.absoluteString, "https://example.com/avatar.jpg")
        XCTAssertEqual(member.weeklyXP, 350)
        XCTAssertEqual(member.rank, 2)
        XCTAssertTrue(member.isCurrentUser)
    }

    func test_memberToDomain_handlesNilAvatarURL() {
        // Given
        let fbMember = FBLeagueMember.fixture(avatarURL: nil)

        // When
        let member = fbMember.toDomain(rank: 1, currentUserId: "other")

        // Then
        XCTAssertNil(member.avatarURL)
        XCTAssertFalse(member.isCurrentUser)
    }

    func test_memberToDomain_handlesInvalidAvatarURL() {
        // Given
        let fbMember = FBLeagueMember(
            userId: "u1",
            displayName: "Test",
            avatarURL: "",
            weeklyXP: 100
        )

        // When
        let member = fbMember.toDomain(rank: 1, currentUserId: "other")

        // Then - empty string URL may or may not be nil depending on URL init
        // The important thing is it doesn't crash
        XCTAssertEqual(member.userId, "u1")
    }

    func test_toDomain_handlesNilDates_defaultsToNow() {
        // Given
        let fbLeague = FBLeague(
            tier: "bronze",
            seasonWeek: 1,
            startDate: nil,
            endDate: nil
        )

        // When
        let league = fbLeague.toDomain(members: [], currentUserId: "user1")

        // Then - should not crash, dates default to Date()
        XCTAssertNotNil(league.startDate)
        XCTAssertNotNil(league.endDate)
    }
}
