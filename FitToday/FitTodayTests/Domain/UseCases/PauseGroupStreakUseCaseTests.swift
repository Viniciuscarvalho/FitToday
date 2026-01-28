//
//  PauseGroupStreakUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 27/01/26.
//

import XCTest
@testable import FitToday

final class PauseGroupStreakUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: PauseGroupStreakUseCase!
    private var mockStreakRepo: MockGroupStreakRepository!
    private var mockGroupRepo: MockGroupRepository!
    private var mockAuthRepo: MockAuthRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockStreakRepo = MockGroupStreakRepository()
        mockGroupRepo = MockGroupRepository()
        mockAuthRepo = MockAuthRepository()

        sut = PauseGroupStreakUseCase(
            groupStreakRepository: mockStreakRepo,
            groupRepository: mockGroupRepo,
            authRepository: mockAuthRepo
        )
    }

    override func tearDown() {
        sut = nil
        mockStreakRepo = nil
        mockGroupRepo = nil
        mockAuthRepo = nil
        super.tearDown()
    }

    // MARK: - Pause Tests

    func testPause_WhenValidAdmin_PausesSuccessfully() async throws {
        // Given
        mockAuthRepo.currentUserToReturn = .fixture(id: "admin1")
        mockGroupRepo.membersToReturn = [.fixture(id: "admin1", role: .admin)]
        mockStreakRepo.streakStatusToReturn = .fixture(streakDays: 14, pauseUsedThisMonth: false)

        // When
        try await sut.pause(groupId: "group1", days: 3)

        // Then
        XCTAssertTrue(mockStreakRepo.pauseStreakCalled)
    }

    func testPause_WhenNotAdmin_ThrowsError() async {
        // Given
        mockAuthRepo.currentUserToReturn = .fixture(id: "member1")
        mockGroupRepo.membersToReturn = [.fixture(id: "member1", role: .member)]

        // When/Then
        do {
            try await sut.pause(groupId: "group1", days: 3)
            XCTFail("Should have thrown notGroupAdmin error")
        } catch let error as GroupStreakError {
            if case .notGroupAdmin = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPause_WhenPauseAlreadyUsed_ThrowsError() async {
        // Given
        mockAuthRepo.currentUserToReturn = .fixture(id: "admin1")
        mockGroupRepo.membersToReturn = [.fixture(id: "admin1", role: .admin)]
        mockStreakRepo.streakStatusToReturn = .fixture(
            streakDays: 14,
            pauseUsedThisMonth: true
        )

        // When/Then
        do {
            try await sut.pause(groupId: "group1", days: 3)
            XCTFail("Should have thrown pauseAlreadyUsedThisMonth error")
        } catch let error as GroupStreakError {
            if case .pauseAlreadyUsedThisMonth = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPause_WhenNoActiveStreak_ThrowsError() async {
        // Given
        mockAuthRepo.currentUserToReturn = .fixture(id: "admin1")
        mockGroupRepo.membersToReturn = [.fixture(id: "admin1", role: .admin)]
        mockStreakRepo.streakStatusToReturn = .fixture(streakDays: 0)

        // When/Then
        do {
            try await sut.pause(groupId: "group1", days: 3)
            XCTFail("Should have thrown streakNotActive error")
        } catch let error as GroupStreakError {
            if case .streakNotActive = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPause_WhenDaysTooLong_ThrowsError() async {
        // Given
        mockAuthRepo.currentUserToReturn = .fixture(id: "admin1")
        mockGroupRepo.membersToReturn = [.fixture(id: "admin1", role: .admin)]
        mockStreakRepo.streakStatusToReturn = .fixture(streakDays: 14)

        // When/Then
        do {
            try await sut.pause(groupId: "group1", days: 10)
            XCTFail("Should have thrown pauseDurationTooLong error")
        } catch let error as GroupStreakError {
            if case .pauseDurationTooLong(let maxDays) = error {
                XCTAssertEqual(maxDays, PauseGroupStreakUseCase.maxPauseDays)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Resume Tests

    func testResume_WhenValidAdmin_ResumesSuccessfully() async throws {
        // Given
        mockAuthRepo.currentUserToReturn = .fixture(id: "admin1")
        mockGroupRepo.membersToReturn = [.fixture(id: "admin1", role: .admin)]
        mockStreakRepo.streakStatusToReturn = .pausedStreak

        // When
        try await sut.resume(groupId: "group1")

        // Then
        XCTAssertTrue(mockStreakRepo.resumeStreakCalled)
    }

    func testResume_WhenNotPaused_ThrowsError() async {
        // Given
        mockAuthRepo.currentUserToReturn = .fixture(id: "admin1")
        mockGroupRepo.membersToReturn = [.fixture(id: "admin1", role: .admin)]
        mockStreakRepo.streakStatusToReturn = .fixture(streakDays: 14, pausedUntil: nil)

        // When/Then
        do {
            try await sut.resume(groupId: "group1")
            XCTFail("Should have thrown streakNotActive error")
        } catch let error as GroupStreakError {
            if case .streakNotActive = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}

// MARK: - Mock Group Repository

private class MockGroupRepository: GroupRepository {
    var membersToReturn: [GroupMember] = []
    var groupToReturn: SocialGroup?
    var shouldThrowError: Error?

    func createGroup(name: String, ownerId: String, ownerDisplayName: String, ownerPhotoURL: URL?) async throws -> SocialGroup {
        if let error = shouldThrowError { throw error }
        return groupToReturn ?? .fixture()
    }

    func getGroup(_ groupId: String) async throws -> SocialGroup? {
        if let error = shouldThrowError { throw error }
        return groupToReturn
    }

    func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws {
        if let error = shouldThrowError { throw error }
    }

    func removeMember(groupId: String, userId: String) async throws {
        if let error = shouldThrowError { throw error }
    }

    func leaveGroup(groupId: String, userId: String) async throws {
        if let error = shouldThrowError { throw error }
    }

    func deleteGroup(_ groupId: String) async throws {
        if let error = shouldThrowError { throw error }
    }

    func getMembers(groupId: String) async throws -> [GroupMember] {
        if let error = shouldThrowError { throw error }
        return membersToReturn
    }
}

// MARK: - Mock Auth Repository

private class MockAuthRepository: AuthenticationRepository {
    var currentUserToReturn: SocialUser?

    func currentUser() async throws -> SocialUser? {
        currentUserToReturn
    }

    func signInWithApple() async throws -> SocialUser {
        currentUserToReturn ?? .fixture()
    }

    func signInWithGoogle() async throws -> SocialUser {
        currentUserToReturn ?? .fixture()
    }

    func signInWithEmail(_ email: String, password: String) async throws -> SocialUser {
        currentUserToReturn ?? .fixture()
    }

    func createAccount(email: String, password: String, displayName: String) async throws -> SocialUser {
        currentUserToReturn ?? .fixture()
    }

    func signOut() async throws {}

    func observeAuthState() -> AsyncStream<SocialUser?> {
        AsyncStream { continuation in
            continuation.yield(currentUserToReturn)
        }
    }
}
