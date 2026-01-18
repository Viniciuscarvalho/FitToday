//
//  JoinGroupUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class JoinGroupUseCaseTests: XCTestCase {
    var sut: JoinGroupUseCase!
    var mockAuthRepo: MockAuthenticationRepository!
    var mockGroupRepo: MockGroupRepository!
    var mockUserRepo: MockUserRepository!
    var mockNotificationRepo: MockNotificationRepository!
    var mockAnalytics: MockAnalyticsTracking!

    override func setUp() {
        super.setUp()
        mockAuthRepo = MockAuthenticationRepository()
        mockGroupRepo = MockGroupRepository()
        mockUserRepo = MockUserRepository()
        mockNotificationRepo = MockNotificationRepository()
        mockAnalytics = MockAnalyticsTracking()

        sut = JoinGroupUseCase(
            groupRepository: mockGroupRepo,
            userRepository: mockUserRepo,
            authRepository: mockAuthRepo,
            notificationRepository: mockNotificationRepo,
            analytics: mockAnalytics
        )
    }

    override func tearDown() {
        sut = nil
        mockAuthRepo = nil
        mockGroupRepo = nil
        mockUserRepo = nil
        mockNotificationRepo = nil
        mockAnalytics = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func test_execute_whenUserAuthenticated_joinsGroup() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser

        let group = SocialGroup.fixture(id: "group1", memberCount: 3)
        mockGroupRepo.getGroupResult = group
        mockGroupRepo.getMembersResult = [.member, .admin]

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockGroupRepo.addMemberCalled)
        XCTAssertEqual(mockGroupRepo.capturedAddMemberGroupId, "group1")
        XCTAssertEqual(mockGroupRepo.capturedAddMemberUserId, "user1")
    }

    func test_execute_updatesUserCurrentGroupId() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser

        let group = SocialGroup.fixture(id: "group1", memberCount: 3)
        mockGroupRepo.getGroupResult = group
        mockGroupRepo.getMembersResult = []

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockUserRepo.updateCurrentGroupCalled)
        XCTAssertEqual(mockUserRepo.capturedCurrentGroupId, "group1")
    }

    func test_execute_tracksAnalyticsEvent() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser

        let group = SocialGroup.fixture(id: "group1", memberCount: 3)
        mockGroupRepo.getGroupResult = group
        mockGroupRepo.getMembersResult = []

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockAnalytics.trackGroupJoinedCalled)
        XCTAssertTrue(mockAnalytics.setUserInGroupCalled)
        XCTAssertTrue(mockAnalytics.setUserRoleCalled)
    }

    func test_execute_notifiesExistingMembers() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "new-user", displayName: "New User", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser

        let group = SocialGroup.fixture(id: "group1", memberCount: 2)
        mockGroupRepo.getGroupResult = group
        mockGroupRepo.getMembersResult = [
            .fixture(id: "existing1", isActive: true),
            .fixture(id: "existing2", isActive: true)
        ]

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockNotificationRepo.createNotificationCalled)
    }

    // MARK: - Error Cases

    func test_execute_whenUserNotAuthenticated_throwsNotAuthenticatedError() async {
        // Given
        mockAuthRepo.currentUserResult = nil

        // When/Then
        do {
            try await sut.execute(groupId: "group1")
            XCTFail("Expected notAuthenticated error")
        } catch let error as DomainError {
            XCTAssertEqual(error, .notAuthenticated)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_whenUserAlreadyInGroup_throwsAlreadyInGroupError() async {
        // Given
        let userInGroup = SocialUser.fixture(id: "user1", currentGroupId: "other-group")
        mockAuthRepo.currentUserResult = userInGroup

        // When/Then
        do {
            try await sut.execute(groupId: "group1")
            XCTFail("Expected alreadyInGroup error")
        } catch let error as DomainError {
            XCTAssertEqual(error, .alreadyInGroup)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_whenGroupNotFound_throwsGroupNotFoundError() async {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser
        mockGroupRepo.getGroupResult = nil

        // When/Then
        do {
            try await sut.execute(groupId: "nonexistent-group")
            XCTFail("Expected groupNotFound error")
        } catch let error as DomainError {
            XCTAssertEqual(error, .groupNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_whenGroupFull_throwsGroupFullError() async {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser

        let fullGroup = SocialGroup.fixture(id: "group1", memberCount: 10)
        mockGroupRepo.getGroupResult = fullGroup

        // When/Then
        do {
            try await sut.execute(groupId: "group1")
            XCTFail("Expected groupFull error")
        } catch let error as DomainError {
            XCTAssertEqual(error, .groupFull)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
