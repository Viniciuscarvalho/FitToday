//
//  SyncWorkoutCompletionUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class SyncWorkoutCompletionUseCaseTests: XCTestCase {
    var sut: SyncWorkoutCompletionUseCase!
    var mockAuthRepo: MockAuthenticationRepository!
    var mockUserRepo: MockUserRepository!
    var mockLeaderboardRepo: MockLeaderboardRepository!
    var mockHistoryRepo: SocialMockWorkoutHistoryRepository!
    var mockAnalytics: MockAnalyticsTracking!

    override func setUp() {
        super.setUp()
        mockAuthRepo = MockAuthenticationRepository()
        mockUserRepo = MockUserRepository()
        mockLeaderboardRepo = MockLeaderboardRepository()
        mockHistoryRepo = SocialMockWorkoutHistoryRepository()
        mockAnalytics = MockAnalyticsTracking()

        sut = SyncWorkoutCompletionUseCase(
            leaderboardRepository: mockLeaderboardRepo,
            userRepository: mockUserRepo,
            authRepository: mockAuthRepo,
            historyRepository: mockHistoryRepo,
            pendingQueue: nil,
            analytics: mockAnalytics
        )
    }

    override func tearDown() {
        sut = nil
        mockAuthRepo = nil
        mockUserRepo = nil
        mockLeaderboardRepo = nil
        mockHistoryRepo = nil
        mockAnalytics = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func test_execute_whenValidWorkout_incrementsCheckIn() async throws {
        // Given
        let userInGroup = SocialUser.fixture(id: "user1", currentGroupId: "group1", shareWorkoutData: true)
        mockAuthRepo.currentUserResult = userInGroup

        let checkInsChallenge = Challenge.fixture(id: "challenge1", type: .checkIns)
        mockLeaderboardRepo.getCurrentWeekChallengesResult = [checkInsChallenge]

        let completedEntry = createCompletedWorkoutEntry()
        mockHistoryRepo.listEntriesResult = [completedEntry]

        // When
        try await sut.performSync(entry: completedEntry)

        // Then
        XCTAssertTrue(mockLeaderboardRepo.incrementCheckInCalled)
        XCTAssertEqual(mockLeaderboardRepo.capturedChallengeId, "challenge1")
    }

    func test_execute_whenValidWorkout_updatesStreak() async throws {
        // Given
        let userInGroup = SocialUser.fixture(id: "user1", currentGroupId: "group1", shareWorkoutData: true)
        mockAuthRepo.currentUserResult = userInGroup

        let streakChallenge = Challenge.fixture(id: "challenge2", type: .streak)
        mockLeaderboardRepo.getCurrentWeekChallengesResult = [streakChallenge]

        let completedEntry = createCompletedWorkoutEntry()
        mockHistoryRepo.listEntriesResult = [completedEntry]

        // When
        try await sut.performSync(entry: completedEntry)

        // Then
        XCTAssertTrue(mockLeaderboardRepo.updateStreakCalled)
        XCTAssertEqual(mockLeaderboardRepo.capturedChallengeId, "challenge2")
    }

    func test_execute_tracksAnalyticsEvents() async throws {
        // Given
        let userInGroup = SocialUser.fixture(id: "user1", currentGroupId: "group1", shareWorkoutData: true)
        mockAuthRepo.currentUserResult = userInGroup

        let challenges = [Challenge.checkIns, Challenge.streak]
        mockLeaderboardRepo.getCurrentWeekChallengesResult = challenges

        let completedEntry = createCompletedWorkoutEntry()
        mockHistoryRepo.listEntriesResult = [completedEntry]

        // When
        try await sut.performSync(entry: completedEntry)

        // Then
        XCTAssertTrue(mockAnalytics.trackWorkoutSyncedCalled)
    }

    // MARK: - Skip Conditions

    func test_execute_whenWorkoutSkipped_doesNotSync() async throws {
        // Given
        let skippedEntry = createSkippedWorkoutEntry()

        // When
        try await sut.performSync(entry: skippedEntry)

        // Then
        XCTAssertFalse(mockAuthRepo.currentUserCalled)
        XCTAssertFalse(mockLeaderboardRepo.incrementCheckInCalled)
    }

    func test_execute_whenUserNotAuthenticated_doesNotSync() async throws {
        // Given
        mockAuthRepo.currentUserResult = nil
        let completedEntry = createCompletedWorkoutEntry()

        // When
        try await sut.performSync(entry: completedEntry)

        // Then
        XCTAssertFalse(mockLeaderboardRepo.incrementCheckInCalled)
    }

    func test_execute_whenUserNotInGroup_doesNotSync() async throws {
        // Given
        let userNotInGroup = SocialUser.fixture(id: "user1", currentGroupId: nil)
        mockAuthRepo.currentUserResult = userNotInGroup

        let completedEntry = createCompletedWorkoutEntry()

        // When
        try await sut.performSync(entry: completedEntry)

        // Then
        XCTAssertFalse(mockLeaderboardRepo.incrementCheckInCalled)
    }

    func test_execute_whenPrivacyDisabled_doesNotSync() async throws {
        // Given
        let privateUser = SocialUser.fixture(id: "user1", currentGroupId: "group1", shareWorkoutData: false)
        mockAuthRepo.currentUserResult = privateUser

        let completedEntry = createCompletedWorkoutEntry()

        // When
        try await sut.performSync(entry: completedEntry)

        // Then
        XCTAssertFalse(mockLeaderboardRepo.incrementCheckInCalled)
    }

    // MARK: - Helpers

    private func createCompletedWorkoutEntry() -> WorkoutHistoryEntry {
        WorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Test Workout",
            focus: .upper,
            status: .completed,
            durationMinutes: 30,
            caloriesBurned: 200
        )
    }

    private func createSkippedWorkoutEntry() -> WorkoutHistoryEntry {
        WorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Test Workout",
            focus: .upper,
            status: .skipped,
            durationMinutes: 0,
            caloriesBurned: 0
        )
    }
}

// MARK: - SocialMockWorkoutHistoryRepository

final class SocialMockWorkoutHistoryRepository: WorkoutHistoryRepository, @unchecked Sendable {
    var listEntriesResult: [WorkoutHistoryEntry] = []
    var saveEntryCalled = false

    func listEntries() async throws -> [WorkoutHistoryEntry] {
        return listEntriesResult
    }

    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        let start = min(offset, listEntriesResult.count)
        let end = min(start + limit, listEntriesResult.count)
        return Array(listEntriesResult[start..<end])
    }

    func count() async throws -> Int {
        return listEntriesResult.count
    }

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        saveEntryCalled = true
    }

    func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry] {
        let filtered = listEntriesResult.filter { $0.source == .app && $0.workoutPlan != nil }
        return Array(filtered.prefix(limit))
    }
}
