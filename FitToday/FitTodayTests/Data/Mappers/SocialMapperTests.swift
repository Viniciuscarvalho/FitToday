//
//  SocialMapperTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
import FirebaseFirestore
@testable import FitToday

final class SocialMapperTests: XCTestCase {

    // MARK: - SocialUser Mapper Tests

    func test_FBUser_toDomain_mapsAllFields() {
        // Given
        let fbUser = FBUser(
            id: "user123",
            displayName: "João Silva",
            email: "joao@example.com",
            photoURL: "https://example.com/photo.jpg",
            authProvider: "apple",
            currentGroupId: "group1",
            privacySettings: FBPrivacySettings(shareWorkoutData: true),
            createdAt: Timestamp(date: Date(timeIntervalSince1970: 1000))
        )

        // When
        let domain = fbUser.toDomain()

        // Then
        XCTAssertEqual(domain.id, "user123")
        XCTAssertEqual(domain.displayName, "João Silva")
        XCTAssertEqual(domain.email, "joao@example.com")
        XCTAssertEqual(domain.photoURL?.absoluteString, "https://example.com/photo.jpg")
        XCTAssertEqual(domain.authProvider, .apple)
        XCTAssertEqual(domain.currentGroupId, "group1")
        XCTAssertTrue(domain.privacySettings.shareWorkoutData)
    }

    func test_FBUser_toDomain_handlesNilPhotoURL() {
        // Given
        let fbUser = FBUser(
            id: "user123",
            displayName: "Test",
            email: nil,
            photoURL: nil,
            authProvider: "email",
            currentGroupId: nil,
            privacySettings: FBPrivacySettings(shareWorkoutData: false),
            createdAt: nil
        )

        // When
        let domain = fbUser.toDomain()

        // Then
        XCTAssertNil(domain.photoURL)
        XCTAssertNil(domain.email)
        XCTAssertNil(domain.currentGroupId)
        XCTAssertFalse(domain.privacySettings.shareWorkoutData)
    }

    func test_FBUser_toDomain_handlesInvalidAuthProvider() {
        // Given
        let fbUser = FBUser(
            id: "user123",
            displayName: "Test",
            email: nil,
            photoURL: nil,
            authProvider: "unknown_provider",
            currentGroupId: nil,
            privacySettings: FBPrivacySettings(shareWorkoutData: true),
            createdAt: nil
        )

        // When
        let domain = fbUser.toDomain()

        // Then
        XCTAssertEqual(domain.authProvider, .email) // Falls back to email
    }

    func test_SocialUser_toFirestore_mapsAllFields() {
        // Given
        let domain = SocialUser.fixture(
            id: "user123",
            displayName: "Maria",
            email: "maria@test.com",
            currentGroupId: "group1",
            shareWorkoutData: true
        )

        // When
        let fbUser = domain.toFirestore()

        // Then
        XCTAssertEqual(fbUser.id, "user123")
        XCTAssertEqual(fbUser.displayName, "Maria")
        XCTAssertEqual(fbUser.email, "maria@test.com")
        XCTAssertEqual(fbUser.currentGroupId, "group1")
        XCTAssertTrue(fbUser.privacySettings.shareWorkoutData)
    }

    // MARK: - SocialGroup Mapper Tests

    func test_FBGroup_toDomain_mapsAllFields() {
        // Given
        let fbGroup = FBGroup(
            id: "group123",
            name: "Galera da Academia",
            createdAt: Timestamp(date: Date(timeIntervalSince1970: 1000)),
            createdBy: "user1",
            memberCount: 5,
            isActive: true
        )

        // When
        let domain = fbGroup.toDomain()

        // Then
        XCTAssertEqual(domain.id, "group123")
        XCTAssertEqual(domain.name, "Galera da Academia")
        XCTAssertEqual(domain.createdBy, "user1")
        XCTAssertEqual(domain.memberCount, 5)
        XCTAssertTrue(domain.isActive)
    }

    func test_FBGroup_toDomain_handlesNilId() {
        // Given
        let fbGroup = FBGroup(
            id: nil,
            name: "Test",
            createdAt: nil,
            createdBy: "user1",
            memberCount: 1,
            isActive: true
        )

        // When
        let domain = fbGroup.toDomain()

        // Then
        XCTAssertEqual(domain.id, "") // Empty string for nil ID
    }

    // MARK: - GroupMember Mapper Tests

    func test_FBMember_toDomain_mapsAdminRole() {
        // Given
        let fbMember = FBMember(
            id: "member1",
            displayName: "Admin User",
            photoURL: nil,
            joinedAt: Timestamp(date: Date()),
            role: "admin",
            isActive: true
        )

        // When
        let domain = fbMember.toDomain()

        // Then
        XCTAssertEqual(domain.role, .admin)
    }

    func test_FBMember_toDomain_mapsMemberRole() {
        // Given
        let fbMember = FBMember(
            id: "member1",
            displayName: "Regular User",
            photoURL: nil,
            joinedAt: Timestamp(date: Date()),
            role: "member",
            isActive: true
        )

        // When
        let domain = fbMember.toDomain()

        // Then
        XCTAssertEqual(domain.role, .member)
    }

    func test_FBMember_toDomain_handlesUnknownRole() {
        // Given
        let fbMember = FBMember(
            id: "member1",
            displayName: "User",
            photoURL: nil,
            joinedAt: nil,
            role: "unknown_role",
            isActive: true
        )

        // When
        let domain = fbMember.toDomain()

        // Then
        XCTAssertEqual(domain.role, .member) // Falls back to member
    }

    // MARK: - Challenge Mapper Tests

    func test_FBChallenge_toDomain_mapsCheckInsType() {
        // Given
        let fbChallenge = FBChallenge(
            id: "challenge1",
            groupId: "group1",
            type: "check-ins",
            weekStartDate: Timestamp(date: Date()),
            weekEndDate: Timestamp(date: Date()),
            isActive: true,
            createdAt: Timestamp(date: Date())
        )

        // When
        let domain = fbChallenge.toDomain()

        // Then
        XCTAssertEqual(domain.type, .checkIns)
    }

    func test_FBChallenge_toDomain_mapsStreakType() {
        // Given
        let fbChallenge = FBChallenge(
            id: "challenge1",
            groupId: "group1",
            type: "streak",
            weekStartDate: Timestamp(date: Date()),
            weekEndDate: Timestamp(date: Date()),
            isActive: true,
            createdAt: Timestamp(date: Date())
        )

        // When
        let domain = fbChallenge.toDomain()

        // Then
        XCTAssertEqual(domain.type, .streak)
    }

    // MARK: - LeaderboardEntry Mapper Tests

    func test_FBChallengeEntry_toDomain_mapsAllFields() {
        // Given
        let fbEntry = FBChallengeEntry(
            id: "user1",
            displayName: "Leader",
            photoURL: "https://example.com/leader.jpg",
            value: 10,
            rank: 1,
            lastUpdated: Timestamp(date: Date())
        )

        // When
        let domain = fbEntry.toDomain()

        // Then
        XCTAssertEqual(domain.id, "user1")
        XCTAssertEqual(domain.displayName, "Leader")
        XCTAssertEqual(domain.photoURL?.absoluteString, "https://example.com/leader.jpg")
        XCTAssertEqual(domain.value, 10)
        XCTAssertEqual(domain.rank, 1)
    }

    // MARK: - Notification Mapper Tests

    func test_FBNotification_toDomain_mapsNewMemberType() {
        // Given
        let fbNotification = FBNotification(
            id: "notif1",
            userId: "user1",
            groupId: "group1",
            type: "new_member",
            message: "Test message",
            isRead: false,
            createdAt: Timestamp(date: Date())
        )

        // When
        let domain = fbNotification.toDomain()

        // Then
        XCTAssertEqual(domain.type, .newMember)
        XCTAssertFalse(domain.isRead)
    }

    func test_FBNotification_toDomain_mapsRankChangeType() {
        // Given
        let fbNotification = FBNotification(
            id: "notif1",
            userId: "user1",
            groupId: "group1",
            type: "rank_change",
            message: "Você subiu!",
            isRead: true,
            createdAt: Timestamp(date: Date())
        )

        // When
        let domain = fbNotification.toDomain()

        // Then
        XCTAssertEqual(domain.type, .rankChange)
        XCTAssertTrue(domain.isRead)
    }

    func test_GroupNotification_toFirestore_mapsCorrectly() {
        // Given
        let domain = GroupNotification.fixture(
            id: "notif1",
            userId: "user1",
            groupId: "group1",
            type: .weekEnded,
            message: "Desafio encerrado!",
            isRead: false
        )

        // When
        let fbNotification = domain.toFirestore()

        // Then
        XCTAssertEqual(fbNotification.id, "notif1")
        XCTAssertEqual(fbNotification.userId, "user1")
        XCTAssertEqual(fbNotification.groupId, "group1")
        XCTAssertEqual(fbNotification.type, "week_ended")
        XCTAssertEqual(fbNotification.message, "Desafio encerrado!")
        XCTAssertFalse(fbNotification.isRead)
    }
}
