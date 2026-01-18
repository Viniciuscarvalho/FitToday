//
//  LeaveGroupUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class LeaveGroupUseCaseTests: XCTestCase {
    var sut: LeaveGroupUseCase!
    var mockAuthRepo: MockAuthenticationRepository!
    var mockGroupRepo: MockGroupRepository!
    var mockUserRepo: MockUserRepository!
    var mockAnalytics: MockAnalyticsTracking!

    override func setUp() {
        super.setUp()
        mockAuthRepo = MockAuthenticationRepository()
        mockGroupRepo = MockGroupRepository()
        mockUserRepo = MockUserRepository()
        mockAnalytics = MockAnalyticsTracking()

        sut = LeaveGroupUseCase(
            groupRepository: mockGroupRepo,
            userRepository: mockUserRepo,
            authRepository: mockAuthRepo,
            analytics: mockAnalytics
        )
    }

    override func tearDown() {
        sut = nil
        mockAuthRepo = nil
        mockGroupRepo = nil
        mockUserRepo = nil
        mockAnalytics = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func test_execute_whenUserAuthenticated_leavesGroup() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = authenticatedUser
        mockGroupRepo.getMembersResult = [
            .fixture(id: "user1", joinedAt: Date().addingTimeInterval(-86400 * 5)), // 5 days ago
            .fixture(id: "user2")
        ]

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockGroupRepo.leaveGroupCalled)
        XCTAssertEqual(mockGroupRepo.capturedLeaveGroupId, "group1")
    }

    func test_execute_clearsUserCurrentGroupId() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = authenticatedUser
        mockGroupRepo.getMembersResult = [.fixture(id: "user1"), .fixture(id: "user2")]

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockUserRepo.updateCurrentGroupCalled)
        XCTAssertNil(mockUserRepo.capturedCurrentGroupId)
    }

    func test_execute_tracksAnalyticsEvent() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = authenticatedUser
        mockGroupRepo.getMembersResult = [
            .fixture(id: "user1", joinedAt: Date().addingTimeInterval(-86400 * 10)), // 10 days ago
            .fixture(id: "user2")
        ]

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockAnalytics.trackGroupLeftCalled)
        XCTAssertTrue(mockAnalytics.setUserInGroupCalled)
        XCTAssertTrue(mockAnalytics.setUserRoleCalled)
    }

    func test_execute_whenLastMemberLeaves_deletesGroup() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = authenticatedUser
        mockGroupRepo.getMembersResult = [.fixture(id: "user1")] // Only one member

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockGroupRepo.leaveGroupCalled)
        XCTAssertTrue(mockGroupRepo.deleteGroupCalled)
        XCTAssertEqual(mockGroupRepo.capturedDeleteGroupId, "group1")
    }

    func test_execute_whenMultipleMembers_doesNotDeleteGroup() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = authenticatedUser
        mockGroupRepo.getMembersResult = [.fixture(id: "user1"), .fixture(id: "user2")]

        // When
        try await sut.execute(groupId: "group1")

        // Then
        XCTAssertTrue(mockGroupRepo.leaveGroupCalled)
        XCTAssertFalse(mockGroupRepo.deleteGroupCalled)
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
}
