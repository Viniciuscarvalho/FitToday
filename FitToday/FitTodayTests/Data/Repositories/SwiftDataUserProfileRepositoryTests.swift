//
//  SwiftDataUserProfileRepositoryTests.swift
//  FitTodayTests
//
//  Created by AI on 15/01/26.
//

import XCTest
import SwiftData
@testable import FitToday

// 💡 Learn: Testes para o repositório SwiftData de perfis de usuário
// Usa ModelContainer em memória para isolar os testes
@MainActor
final class SwiftDataUserProfileRepositoryTests: XCTestCase {

    var container: ModelContainer!
    var sut: SwiftDataUserProfileRepository!

    override func setUp() async throws {
        // 💡 Learn: Cria ModelContainer em memória para testes isolados
        let schema = Schema([SDUserProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        sut = SwiftDataUserProfileRepository(modelContainer: container)
    }

    override func tearDown() async throws {
        container = nil
        sut = nil
    }

    // MARK: - Load Profile Tests

    func testLoadProfile_whenNoProfileExists_returnsNil() async throws {
        // When
        let result = try await sut.loadProfile()

        // Then
        XCTAssertNil(result)
    }

    func testLoadProfile_whenProfileExists_returnsProfile() async throws {
        // Given
        let profile = createValidProfile()
        try await sut.saveProfile(profile)

        // When
        let result = try await sut.loadProfile()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, profile.id)
        XCTAssertEqual(result?.mainGoal, profile.mainGoal)
        XCTAssertEqual(result?.weeklyFrequency, profile.weeklyFrequency)
    }

    func testLoadProfile_whenMultipleProfilesExist_returnsMostRecent() async throws {
        // Given
        let oldProfile = UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: 3,
            createdAt: Date().addingTimeInterval(-86400) // 1 day ago
        )

        let newProfile = UserProfile(
            mainGoal: .conditioning,
            availableStructure: .basicGym,
            preferredMethod: .circuit,
            level: .beginner,
            healthConditions: [.none],
            weeklyFrequency: 4,
            createdAt: Date() // Now
        )

        try await sut.saveProfile(oldProfile)
        try await sut.saveProfile(newProfile)

        // When
        let result = try await sut.loadProfile()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, newProfile.id)
        XCTAssertEqual(result?.mainGoal, .conditioning)
    }

    // MARK: - Save Profile Tests

    func testSaveProfile_insertsNewProfile() async throws {
        // Given
        let profile = createValidProfile()

        // When
        try await sut.saveProfile(profile)

        // Then
        let loaded = try await sut.loadProfile()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, profile.id)
    }

    func testSaveProfile_updatesExistingProfile() async throws {
        // Given
        var profile = createValidProfile()
        try await sut.saveProfile(profile)

        // When - Update the same profile
        profile.weeklyFrequency = 5
        profile.mainGoal = .conditioning
        try await sut.saveProfile(profile)

        // Then
        let loaded = try await sut.loadProfile()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, profile.id)
        XCTAssertEqual(loaded?.weeklyFrequency, 5)
        XCTAssertEqual(loaded?.mainGoal, .conditioning)
    }

    func testSaveProfile_persistsAllFields() async throws {
        // Given
        let profile = UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .advanced,
            healthConditions: [.lowerBackPain, .shoulder],
            weeklyFrequency: 6
        )

        // When
        try await sut.saveProfile(profile)

        // Then
        let loaded = try await sut.loadProfile()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.mainGoal, .hypertrophy)
        XCTAssertEqual(loaded?.availableStructure, .fullGym)
        XCTAssertEqual(loaded?.preferredMethod, .traditional)
        XCTAssertEqual(loaded?.level, .advanced)
        XCTAssertEqual(loaded?.healthConditions.count, 2)
        XCTAssertTrue(loaded?.healthConditions.contains(.lowerBackPain) ?? false)
        XCTAssertTrue(loaded?.healthConditions.contains(.shoulder) ?? false)
        XCTAssertEqual(loaded?.weeklyFrequency, 6)
    }

    // MARK: - Helper Methods

    private func createValidProfile() -> UserProfile {
        UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [.none],
            weeklyFrequency: 4
        )
    }
}
