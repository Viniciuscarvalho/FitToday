//
//  UserProfileUseCasesTests.swift
//  FitTodayTests
//
//  Created by AI on 15/01/26.
//

import XCTest
@testable import FitToday

// 💡 Learn: Testes para os UseCases de perfil do usuário
// Validam criação, atualização e recuperação de perfis
final class UserProfileUseCasesTests: XCTestCase {

    // MARK: - CreateOrUpdateProfileUseCase Tests

    func testCreateOrUpdateProfile_withValidProfile_savesSuccessfully() async throws {
        // Given
        let mockRepo = MockUserProfileRepository()
        let sut = CreateOrUpdateProfileUseCase(repository: mockRepo)
        let validProfile = UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: 4
        )

        // When
        try await sut.execute(validProfile)

        // Then
        XCTAssertTrue(mockRepo.saveProfileCalled)
        XCTAssertEqual(mockRepo.savedProfile?.mainGoal, .hypertrophy)
        XCTAssertEqual(mockRepo.savedProfile?.weeklyFrequency, 4)
    }

    func testUserProfile_withZeroFrequency_clampedToMinimum() {
        // Given
        let profile = UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: 0 // Will be clamped to 1
        )

        // Then
        XCTAssertEqual(profile.weeklyFrequency, 1, "weeklyFrequency should be clamped to minimum of 1")
    }

    func testUserProfile_withNegativeFrequency_clampedToMinimum() {
        // Given
        let profile = UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: -1 // Will be clamped to 1
        )

        // Then
        XCTAssertEqual(profile.weeklyFrequency, 1, "weeklyFrequency should be clamped to minimum of 1")
    }

    // MARK: - GetUserProfileUseCase Tests

    func testGetUserProfile_whenProfileExists_returnsProfile() async throws {
        // Given
        let existingProfile = UserProfile(
            mainGoal: .conditioning,
            availableStructure: .basicGym,
            preferredMethod: .circuit,
            level: .beginner,
            healthConditions: [.none],
            weeklyFrequency: 3
        )
        let mockRepo = MockUserProfileRepository(storedProfile: existingProfile)
        let sut = GetUserProfileUseCase(repository: mockRepo)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.mainGoal, .conditioning)
        XCTAssertEqual(result?.weeklyFrequency, 3)
        XCTAssertTrue(mockRepo.loadProfileCalled)
    }

    func testGetUserProfile_whenNoProfile_returnsNil() async throws {
        // Given
        let mockRepo = MockUserProfileRepository(storedProfile: nil)
        let sut = GetUserProfileUseCase(repository: mockRepo)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNil(result)
        XCTAssertTrue(mockRepo.loadProfileCalled)
    }

    // MARK: - ValidateDailyCheckInUseCase Tests

    func testValidateDailyCheckIn_withValidCheckIn_returnsCheckIn() throws {
        // Given
        let sut = ValidateDailyCheckInUseCase()
        let validCheckIn = DailyCheckIn(
            focus: .fullBody,
            sorenessLevel: .none,
            sorenessAreas: [],
            energyLevel: 7
        )

        // When
        let result = try sut.execute(validCheckIn)

        // Then
        XCTAssertEqual(result.focus, .fullBody)
        XCTAssertEqual(result.energyLevel, 7)
    }

    func testValidateDailyCheckIn_withStrongSorenessButNoAreas_throwsError() {
        // Given
        let sut = ValidateDailyCheckInUseCase()
        let invalidCheckIn = DailyCheckIn(
            focus: .fullBody,
            sorenessLevel: .strong,
            sorenessAreas: [], // Empty when strong soreness
            energyLevel: 5
        )

        // When/Then
        XCTAssertThrowsError(try sut.execute(invalidCheckIn)) { error in
            guard let domainError = error as? DomainError else {
                XCTFail("Wrong error type")
                return
            }
            if case .invalidInput(let reason) = domainError {
                XCTAssertTrue(reason.contains("doloridas"))
            } else {
                XCTFail("Wrong error case")
            }
        }
    }

    func testValidateDailyCheckIn_withStrongSorenessAndAreas_succeeds() throws {
        // Given
        let sut = ValidateDailyCheckInUseCase()
        let validCheckIn = DailyCheckIn(
            focus: .upper,
            sorenessLevel: .strong,
            sorenessAreas: [.chest, .shoulders],
            energyLevel: 4
        )

        // When
        let result = try sut.execute(validCheckIn)

        // Then
        XCTAssertEqual(result.sorenessLevel, .strong)
        XCTAssertEqual(result.sorenessAreas.count, 2)
    }

    func testValidateDailyCheckIn_withLightSorenessAndNoAreas_succeeds() throws {
        // Given
        let sut = ValidateDailyCheckInUseCase()
        let validCheckIn = DailyCheckIn(
            focus: .lower,
            sorenessLevel: .light,
            sorenessAreas: [], // OK for light soreness
            energyLevel: 6
        )

        // When
        let result = try sut.execute(validCheckIn)

        // Then
        XCTAssertEqual(result.sorenessLevel, .light)
        XCTAssertTrue(result.sorenessAreas.isEmpty)
    }
}

// MARK: - Mock Repository

private final class MockUserProfileRepository: UserProfileRepository, @unchecked Sendable {
    var storedProfile: UserProfile?
    var saveProfileCalled = false
    var loadProfileCalled = false
    var savedProfile: UserProfile?

    init(storedProfile: UserProfile? = nil) {
        self.storedProfile = storedProfile
    }

    func loadProfile() async throws -> UserProfile? {
        loadProfileCalled = true
        return storedProfile
    }

    func saveProfile(_ profile: UserProfile) async throws {
        saveProfileCalled = true
        savedProfile = profile
        storedProfile = profile
    }
}
