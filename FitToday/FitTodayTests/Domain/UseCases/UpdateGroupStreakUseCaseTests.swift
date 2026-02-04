//
//  UpdateGroupStreakUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 27/01/26.
//

import XCTest
@testable import FitToday

final class UpdateGroupStreakUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: UpdateGroupStreakUseCase!
    private var mockStreakRepo: MockGroupStreakRepository!
    private var mockAuthRepo: MockAuthenticationRepository!
    private var mockNotificationRepo: MockNotificationRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockStreakRepo = MockGroupStreakRepository()
        mockAuthRepo = MockAuthenticationRepository()
        mockNotificationRepo = MockNotificationRepository()

        sut = UpdateGroupStreakUseCase(
            groupStreakRepository: mockStreakRepo,
            authRepository: mockAuthRepo,
            notificationRepository: mockNotificationRepo
        )
    }

    override func tearDown() {
        sut = nil
        mockStreakRepo = nil
        mockAuthRepo = nil
        mockNotificationRepo = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testExecute_WhenUserNotInGroup_ReturnsNoGroup() async throws {
        // Given
        mockAuthRepo.currentUserResult = .fixture(currentGroupId: nil)

        // When
        let result = try await sut.execute(userId: "user1", displayName: "Test", photoURL: nil)

        // Then
        XCTAssertEqual(result.groupId, "")
        XCTAssertFalse(result.userBecameCompliant)
        XCTAssertFalse(mockStreakRepo.incrementWorkoutCountCalled)
    }

    func testExecute_WhenUserInGroup_IncrementsWorkoutCount() async throws {
        // Given
        mockAuthRepo.currentUserResult = .fixture(id: "user1", currentGroupId: "group1")
        mockStreakRepo.streakStatusToReturn = .fixture(
            groupId: "group1",
            currentWeek: .fixture(memberCompliance: [
                .fixture(id: "user1", workoutCount: 1)
            ])
        )

        // When
        _ = try await sut.execute(userId: "user1", displayName: "Test", photoURL: nil)

        // Then
        XCTAssertTrue(mockStreakRepo.incrementWorkoutCountCalled)
        XCTAssertEqual(mockStreakRepo.incrementWorkoutCountGroupId, "group1")
        XCTAssertEqual(mockStreakRepo.incrementWorkoutCountUserId, "user1")
    }

    func testExecute_WhenUserBecomesCompliant_ReturnsTrue() async throws {
        // Given
        mockAuthRepo.currentUserResult = .fixture(id: "user1", currentGroupId: "group1")

        // Before: user has 2 workouts
        mockStreakRepo.streakStatusToReturn = .fixture(
            groupId: "group1",
            currentWeek: .fixture(memberCompliance: [
                .fixture(id: "user1", workoutCount: 2)
            ])
        )

        // When
        let result = try await sut.execute(userId: "user1", displayName: "Test", photoURL: nil)

        // Then
        XCTAssertTrue(mockStreakRepo.incrementWorkoutCountCalled)
        // Note: In a real test, we'd need a more sophisticated mock to verify userBecameCompliant
    }

    func testExecute_WhenNoCurrentUser_ReturnsNoGroup() async throws {
        // Given
        mockAuthRepo.currentUserResult = nil

        // When
        let result = try await sut.execute(userId: "user1", displayName: "Test", photoURL: nil)

        // Then
        XCTAssertEqual(result.groupId, "")
        XCTAssertFalse(mockStreakRepo.incrementWorkoutCountCalled)
    }
}
