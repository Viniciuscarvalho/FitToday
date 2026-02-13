//
//  WorkoutPlanUseCasesTests.swift
//  FitTodayTests
//
//  Created by AI on 15/01/26.
//

import XCTest
@testable import FitToday

// 💡 Learn: Testes para os UseCases de planos de treino
// Validam geração, início e conclusão de workouts
final class WorkoutPlanUseCasesTests: XCTestCase {

    // MARK: - GenerateWorkoutPlanUseCase Tests

    func testGenerateWorkoutPlan_withValidInputs_returnsWorkoutPlan() async throws {
        // Given
        let mockBlocksRepo = MockWorkoutBlocksRepository()
        let mockComposer = MockWorkoutPlanComposer()
        let sut = GenerateWorkoutPlanUseCase(
            blocksRepository: mockBlocksRepo,
            composer: mockComposer
        )

        let profile = createValidProfile()
        let checkIn = createValidCheckIn()

        // When
        let result = try await sut.execute(profile: profile, checkIn: checkIn)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result.title, "Mock Workout Plan")
        XCTAssertTrue(mockBlocksRepo.loadBlocksCalled)
        XCTAssertTrue(mockComposer.composePlanCalled)
    }

    func testGenerateWorkoutPlan_withNoBlocks_throwsError() async {
        // Given
        let mockBlocksRepo = MockWorkoutBlocksRepository(shouldFail: true)
        let mockComposer = MockWorkoutPlanComposer()
        let sut = GenerateWorkoutPlanUseCase(
            blocksRepository: mockBlocksRepo,
            composer: mockComposer
        )

        let profile = createValidProfile()
        let checkIn = createValidCheckIn()

        // When/Then
        do {
            _ = try await sut.execute(profile: profile, checkIn: checkIn)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected
            XCTAssertTrue(mockBlocksRepo.loadBlocksCalled)
            XCTAssertFalse(mockComposer.composePlanCalled)
        }
    }

    func testGenerateAlternativePlans_withValidInputs_returnsMultiplePlans() async throws {
        // Given
        let mockBlocksRepo = MockWorkoutBlocksRepository()
        let mockComposer = MockWorkoutPlanComposer()
        let sut = GenerateWorkoutPlanUseCase(
            blocksRepository: mockBlocksRepo,
            composer: mockComposer
        )

        let profile = createValidProfile()
        let checkIn = createValidCheckIn()

        // When
        let plans = try await sut.generateAlternativePlans(
            count: 3,
            profile: profile,
            checkIn: checkIn
        )

        // Then
        XCTAssertEqual(plans.count, 3)
        XCTAssertEqual(mockComposer.composePlanCallCount, 3)
    }

    // MARK: - StartWorkoutSessionUseCase Tests

    func testStartWorkoutSession_createsSession() {
        // Given
        let sut = StartWorkoutSessionUseCase()
        let plan = createMockWorkoutPlan()

        // When
        let session = sut.execute(plan: plan)

        // Then
        XCTAssertEqual(session.plan.id, plan.id)
        XCTAssertEqual(session.plan.title, plan.title)
    }

    // MARK: - CompleteWorkoutSessionUseCase Tests

    func testCompleteWorkoutSession_withCompletedStatus_savesToHistory() async throws {
        // Given
        let mockHistoryRepo = MockWorkoutHistoryRepository()
        let sut = CompleteWorkoutSessionUseCase(historyRepository: mockHistoryRepo)
        let plan = createMockWorkoutPlan()
        let session = WorkoutSession(plan: plan)

        // When
        try await sut.execute(session: session, status: .completed)

        // Then
        XCTAssertTrue(mockHistoryRepo.saveEntryCalled)
        XCTAssertEqual(mockHistoryRepo.savedEntry?.status, .completed)
        XCTAssertEqual(mockHistoryRepo.savedEntry?.planId, plan.id)
    }

    func testCompleteWorkoutSession_withSkippedStatus_doesNotSaveToHistory() async throws {
        // Given
        let mockHistoryRepo = MockWorkoutHistoryRepository()
        let sut = CompleteWorkoutSessionUseCase(historyRepository: mockHistoryRepo)
        let plan = createMockWorkoutPlan()
        let session = WorkoutSession(plan: plan)

        // When
        try await sut.execute(session: session, status: .skipped)

        // Then
        XCTAssertFalse(mockHistoryRepo.saveEntryCalled)
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

    private func createValidCheckIn() -> DailyCheckIn {
        DailyCheckIn(
            focus: .fullBody,
            sorenessLevel: .none,
            sorenessAreas: [],
            energyLevel: 7
        )
    }

    private func createMockWorkoutPlan() -> WorkoutPlan {
        WorkoutPlan(
            id: UUID(),
            title: "Test Workout",
            focus: .fullBody,
            estimatedDurationMinutes: 45,
            intensity: .moderate,
            phases: []
        )
    }
}

// MARK: - Mock Repositories

private final class MockWorkoutBlocksRepository: WorkoutBlocksRepository, @unchecked Sendable {
    var loadBlocksCalled = false
    var shouldFail = false

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func loadBlocks() async throws -> [WorkoutBlock] {
        loadBlocksCalled = true
        if shouldFail {
            throw DomainError.repositoryFailure(reason: "No blocks available")
        }
        return [
            WorkoutBlock(
                id: "mock-block-1",
                group: .upper,
                level: .intermediate,
                compatibleStructures: [.fullGym],
                equipmentOptions: [.barbell, .dumbbell],
                exercises: [],
                suggestedSets: IntRange(3, 4),
                suggestedReps: IntRange(8, 12),
                restInterval: 90
            )
        ]
    }
}

private final class MockWorkoutPlanComposer: WorkoutPlanComposing, @unchecked Sendable {
    var composePlanCalled = false
    var composePlanCallCount = 0

    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        composePlanCalled = true
        composePlanCallCount += 1

        return WorkoutPlan(
            id: UUID(),
            title: "Mock Workout Plan",
            focus: checkIn.focus,
            estimatedDurationMinutes: 45,
            intensity: .moderate,
            phases: []
        )
    }
}

private final class MockWorkoutHistoryRepository: WorkoutHistoryRepository, @unchecked Sendable {
    var saveEntryCalled = false
    var savedEntry: WorkoutHistoryEntry?

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        saveEntryCalled = true
        savedEntry = entry
    }

    func listEntries() async throws -> [WorkoutHistoryEntry] {
        []
    }

    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        []
    }

    func count() async throws -> Int {
        0
    }

    func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry] {
        []
    }
}
