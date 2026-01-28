//
//  CheckInUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 25/01/26.
//

import XCTest
@testable import FitToday

@MainActor
final class CheckInUseCaseTests: XCTestCase {
    var sut: CheckInUseCase!
    var mockCheckInRepo: MockCheckInRepository!
    var mockAuthRepo: MockAuthenticationRepository!
    var mockLeaderboardRepo: MockLeaderboardRepository!
    var mockImageCompressor: MockImageCompressor!

    override func setUp() {
        super.setUp()
        mockCheckInRepo = MockCheckInRepository()
        mockAuthRepo = MockAuthenticationRepository()
        mockLeaderboardRepo = MockLeaderboardRepository()
        mockImageCompressor = MockImageCompressor()

        sut = CheckInUseCase(
            checkInRepository: mockCheckInRepo,
            authRepository: mockAuthRepo,
            leaderboardRepository: mockLeaderboardRepo,
            imageCompressor: mockImageCompressor
        )
    }

    override func tearDown() {
        sut = nil
        mockCheckInRepo = nil
        mockAuthRepo = nil
        mockLeaderboardRepo = nil
        mockImageCompressor = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func test_execute_success_createsCheckIn() async throws {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = user

        let challenge = Challenge.fixture(id: "challenge1", groupId: "group1", type: .checkIns)
        mockLeaderboardRepo.getCurrentWeekChallengesResult = [challenge]

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // Fake JPEG header

        // When
        let result = try await sut.execute(
            workoutEntry: workoutEntry,
            photoData: photoData,
            isConnected: true
        )

        // Then
        XCTAssertEqual(result.groupId, "group1")
        XCTAssertEqual(result.challengeId, "challenge1")
        XCTAssertEqual(result.userId, "user1")
        XCTAssertTrue(mockCheckInRepo.createCheckInCalled)
        XCTAssertTrue(mockCheckInRepo.uploadPhotoCalled)
    }

    func test_execute_success_compressesImage() async throws {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = user

        let challenge = Challenge.fixture(id: "challenge1", groupId: "group1", type: .checkIns)
        mockLeaderboardRepo.getCurrentWeekChallengesResult = [challenge]

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When
        _ = try await sut.execute(
            workoutEntry: workoutEntry,
            photoData: photoData,
            isConnected: true
        )

        // Then
        XCTAssertTrue(mockImageCompressor.compressCalled)
        XCTAssertEqual(mockImageCompressor.capturedData, photoData)
        XCTAssertEqual(mockImageCompressor.capturedMaxBytes, 500_000)
    }

    func test_execute_success_incrementsLeaderboard() async throws {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = user

        let challenge = Challenge.fixture(id: "challenge1", groupId: "group1", type: .checkIns)
        mockLeaderboardRepo.getCurrentWeekChallengesResult = [challenge]

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When
        _ = try await sut.execute(
            workoutEntry: workoutEntry,
            photoData: photoData,
            isConnected: true
        )

        // Then
        XCTAssertTrue(mockLeaderboardRepo.incrementCheckInCalled)
        XCTAssertEqual(mockLeaderboardRepo.capturedChallengeId, "challenge1")
    }

    // MARK: - Error Cases

    func test_execute_networkUnavailable_throwsError() async {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = user

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When/Then
        do {
            _ = try await sut.execute(
                workoutEntry: workoutEntry,
                photoData: photoData,
                isConnected: false
            )
            XCTFail("Expected networkUnavailable error")
        } catch let error as CheckInError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_userNotInGroup_throwsNotInGroupError() async {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: nil) // No group
        mockAuthRepo.currentUserResult = user

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When/Then
        do {
            _ = try await sut.execute(
                workoutEntry: workoutEntry,
                photoData: photoData,
                isConnected: true
            )
            XCTFail("Expected notInGroup error")
        } catch let error as CheckInError {
            XCTAssertEqual(error, .notInGroup)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_userNotAuthenticated_throwsNotInGroupError() async {
        // Given
        mockAuthRepo.currentUserResult = nil

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When/Then
        do {
            _ = try await sut.execute(
                workoutEntry: workoutEntry,
                photoData: photoData,
                isConnected: true
            )
            XCTFail("Expected notInGroup error")
        } catch let error as CheckInError {
            XCTAssertEqual(error, .notInGroup)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_workoutTooShort_throwsWorkoutTooShortError() async {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = user

        let workoutEntry = WorkoutHistoryEntry.tooShortForCheckIn // 20 minutes
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When/Then
        do {
            _ = try await sut.execute(
                workoutEntry: workoutEntry,
                photoData: photoData,
                isConnected: true
            )
            XCTFail("Expected workoutTooShort error")
        } catch let error as CheckInError {
            if case .workoutTooShort(let minutes) = error {
                XCTAssertEqual(minutes, 20)
            } else {
                XCTFail("Expected workoutTooShort error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_noActiveChallenge_throwsNoActiveChallengeError() async {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = user

        mockLeaderboardRepo.getCurrentWeekChallengesResult = [] // No challenges

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When/Then
        do {
            _ = try await sut.execute(
                workoutEntry: workoutEntry,
                photoData: photoData,
                isConnected: true
            )
            XCTFail("Expected noActiveChallenge error")
        } catch let error as CheckInError {
            XCTAssertEqual(error, .noActiveChallenge)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_uploadFailed_throwsUploadFailedError() async {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = user

        let challenge = Challenge.fixture(id: "challenge1", groupId: "group1", type: .checkIns)
        mockLeaderboardRepo.getCurrentWeekChallengesResult = [challenge]

        // Make upload fail
        mockCheckInRepo.uploadPhotoResult = .failure(NSError(domain: "test", code: -1))

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When/Then
        do {
            _ = try await sut.execute(
                workoutEntry: workoutEntry,
                photoData: photoData,
                isConnected: true
            )
            XCTFail("Expected uploadFailed error")
        } catch let error as CheckInError {
            if case .uploadFailed = error {
                // Success
            } else {
                XCTFail("Expected uploadFailed error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_compressionFailed_throwsUploadFailedError() async {
        // Given
        let user = SocialUser.fixture(id: "user1", currentGroupId: "group1")
        mockAuthRepo.currentUserResult = user

        let challenge = Challenge.fixture(id: "challenge1", groupId: "group1", type: .checkIns)
        mockLeaderboardRepo.getCurrentWeekChallengesResult = [challenge]

        // Make compression fail
        mockImageCompressor.compressResult = .failure(ImageCompressor.CompressionError.invalidImage)

        let workoutEntry = WorkoutHistoryEntry.validForCheckIn
        let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When/Then
        do {
            _ = try await sut.execute(
                workoutEntry: workoutEntry,
                photoData: photoData,
                isConnected: true
            )
            XCTFail("Expected uploadFailed error")
        } catch let error as CheckInError {
            if case .uploadFailed = error {
                // Success - compression failure is wrapped as uploadFailed
            } else {
                XCTFail("Expected uploadFailed error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - CheckInError Equatable

extension CheckInError: Equatable {
    public static func == (lhs: CheckInError, rhs: CheckInError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable),
             (.notInGroup, .notInGroup),
             (.photoRequired, .photoRequired),
             (.noActiveChallenge, .noActiveChallenge):
            return true
        case (.workoutTooShort(let lhsMin), .workoutTooShort(let rhsMin)):
            return lhsMin == rhsMin
        case (.uploadFailed, .uploadFailed):
            return true
        default:
            return false
        }
    }
}
