//
//  CreateGroupUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class CreateGroupUseCaseTests: XCTestCase {
    var sut: CreateGroupUseCase!
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

        sut = CreateGroupUseCase(
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

    func test_execute_whenUserAuthenticated_createsGroup() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser

        let createdGroup = SocialGroup.fixture(id: "group1", name: "Test Group", createdBy: "user1")
        mockGroupRepo.createGroupResult = .success(createdGroup)

        // When
        let result = try await sut.execute(name: "Test Group")

        // Then
        XCTAssertEqual(result.id, "group1")
        XCTAssertEqual(result.name, "Test Group")
        XCTAssertTrue(mockGroupRepo.createGroupCalled)
        XCTAssertEqual(mockGroupRepo.capturedGroupName, "Test Group")
        XCTAssertEqual(mockGroupRepo.capturedOwnerId, "user1")
    }

    func test_execute_updatesUserCurrentGroupId() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser

        let createdGroup = SocialGroup.fixture(id: "new-group-id", name: "Test Group", createdBy: "user1")
        mockGroupRepo.createGroupResult = .success(createdGroup)

        // When
        _ = try await sut.execute(name: "Test Group")

        // Then
        XCTAssertTrue(mockUserRepo.updateCurrentGroupCalled)
        XCTAssertEqual(mockUserRepo.capturedCurrentGroupId, "new-group-id")
    }

    func test_execute_passesOwnerInfoToCreateGroup() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", displayName: "João", currentGroupId: nil)
        authenticatedUser.photoURL = URL(string: "https://example.com/photo.jpg")
        mockAuthRepo.currentUserResult = authenticatedUser

        let createdGroup = SocialGroup.fixture(id: "group1", createdBy: "user1")
        mockGroupRepo.createGroupResult = .success(createdGroup)

        // When
        _ = try await sut.execute(name: "Test Group")

        // Then
        XCTAssertTrue(mockGroupRepo.createGroupCalled)
        XCTAssertEqual(mockGroupRepo.capturedOwnerDisplayName, "João")
        // photoURL is passed to createGroup along with member creation
    }

    func test_execute_tracksAnalyticsEvent() async throws {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser

        let createdGroup = SocialGroup.fixture(id: "group1", createdBy: "user1")
        mockGroupRepo.createGroupResult = .success(createdGroup)

        // When
        _ = try await sut.execute(name: "Test Group")

        // Then
        XCTAssertTrue(mockAnalytics.trackGroupCreatedCalled)
        XCTAssertTrue(mockAnalytics.setUserInGroupCalled)
        XCTAssertTrue(mockAnalytics.setUserRoleCalled)
    }

    // MARK: - Error Cases

    func test_execute_whenUserNotAuthenticated_throwsNotAuthenticatedError() async {
        // Given
        mockAuthRepo.currentUserResult = nil

        // When/Then
        do {
            _ = try await sut.execute(name: "Test Group")
            XCTFail("Expected notAuthenticated error")
        } catch let error as DomainError {
            XCTAssertEqual(error, .notAuthenticated)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_whenUserAlreadyInGroup_throwsAlreadyInGroupError() async {
        // Given
        let userInGroup = SocialUser.fixture(id: "user1", currentGroupId: "existing-group")
        mockAuthRepo.currentUserResult = userInGroup

        // When/Then
        do {
            _ = try await sut.execute(name: "Test Group")
            XCTFail("Expected alreadyInGroup error")
        } catch let error as DomainError {
            XCTAssertEqual(error, .alreadyInGroup)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_execute_whenGroupCreationFails_propagatesError() async {
        // Given
        let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = authenticatedUser
        mockGroupRepo.createGroupResult = .failure(DomainError.networkFailure)

        // When/Then
        do {
            _ = try await sut.execute(name: "Test Group")
            XCTFail("Expected error to be thrown")
        } catch {
            // Success - error was propagated
        }
    }
}
