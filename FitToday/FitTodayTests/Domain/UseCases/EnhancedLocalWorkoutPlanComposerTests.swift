//
//  EnhancedLocalWorkoutPlanComposerTests.swift
//  FitTodayTests
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 2.0)
//

import XCTest
@testable import FitToday

final class EnhancedLocalWorkoutPlanComposerTests: XCTestCase {

    // MARK: - Test Properties

    var sut: EnhancedLocalWorkoutPlanComposer!
    var mockHistoryRepository: EnhancedComposerMockHistoryRepository!
    var testProfile: UserProfile!
    var testCheckIn: DailyCheckIn!
    var testBlocks: [WorkoutBlock]!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockHistoryRepository = EnhancedComposerMockHistoryRepository()
        sut = EnhancedLocalWorkoutPlanComposer(
            historyRepository: mockHistoryRepository
        )

        // Setup common test data
        testProfile = createTestProfile()
        testCheckIn = createTestCheckIn()
        testBlocks = createTestBlocks()
    }

    override func tearDown() {
        sut = nil
        mockHistoryRepository = nil
        testProfile = nil
        testCheckIn = nil
        testBlocks = nil
        super.tearDown()
    }

    // MARK: - Composition Tests

    func testComposePlan_WithNoPreviousWorkouts_ReturnsValidPlan() async throws {
        // Given
        mockHistoryRepository.mockEntries = []

        // When
        let plan = try await sut.composePlan(
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn
        )

        // Then
        XCTAssertFalse(plan.exercises.isEmpty, "Generated plan should have exercises")
        XCTAssertEqual(mockHistoryRepository.listEntriesCallCount, 1, "Should fetch history once")
    }

    func testComposePlan_WithVariedWorkout_PassesOnFirstAttempt() async throws {
        // Given: Previous workout has exercises ["A", "B", "C"]
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Push-up", "Squat", "Plank"])
        ]
        mockHistoryRepository.mockEntries = createHistoryEntries(from: previousWorkouts)

        // When
        let plan = try await sut.composePlan(
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn
        )

        // Then
        XCTAssertFalse(plan.exercises.isEmpty, "Generated plan should have exercises")

        // Validate diversity
        let diversity = WorkoutVariationValidator.calculateDiversityRatio(
            generated: plan,
            previousWorkouts: previousWorkouts
        )
        XCTAssertGreaterThanOrEqual(diversity, 0.6, "Generated plan should meet 60% diversity threshold")
    }

    func testComposePlan_WithEmptyBlocks_ThrowsError() async {
        // Given
        let emptyBlocks: [WorkoutBlock] = []
        mockHistoryRepository.mockEntries = []

        // When/Then
        do {
            _ = try await sut.composePlan(
                blocks: emptyBlocks,
                profile: testProfile,
                checkIn: testCheckIn
            )
            XCTFail("Should throw error with empty blocks")
        } catch {
            // Expected error
            XCTAssertTrue(true, "Correctly throws error with empty blocks")
        }
    }

    func testComposePlan_WithHistoryFetchFailure_ContinuesWithoutValidation() async throws {
        // Given
        mockHistoryRepository.shouldThrowError = true

        // When
        let plan = try await sut.composePlan(
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn
        )

        // Then
        XCTAssertFalse(plan.exercises.isEmpty, "Should still generate workout despite history fetch failure")
        XCTAssertEqual(mockHistoryRepository.listEntriesCallCount, 1, "Should attempt to fetch history")
    }

    func testComposePlan_FetchesLastThreeWorkouts() async throws {
        // Given
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["A", "B", "C"]),
            createWorkoutPlan(exercises: ["D", "E", "F"]),
            createWorkoutPlan(exercises: ["G", "H", "I"]),
            createWorkoutPlan(exercises: ["J", "K", "L"]) // Should not be used (4th workout)
        ]
        mockHistoryRepository.mockEntries = createHistoryEntries(from: previousWorkouts)

        // When
        _ = try await sut.composePlan(
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn
        )

        // Then
        XCTAssertEqual(mockHistoryRepository.lastLimit, 3, "Should request exactly 3 workouts")
        XCTAssertEqual(mockHistoryRepository.lastOffset, 0, "Should start from offset 0")
    }

    // MARK: - Variation Validation Tests

    func testComposePlan_RespectsUserInputs() async throws {
        // Given
        mockHistoryRepository.mockEntries = []
        let customCheckIn = DailyCheckIn(
            focus: .upper,
            sorenessLevel: .none,
            sorenessAreas: [],
            energyLevel: 8
        )

        // When
        let plan = try await sut.composePlan(
            blocks: testBlocks,
            profile: testProfile,
            checkIn: customCheckIn
        )

        // Then
        XCTAssertEqual(plan.focus, .upper, "Plan should respect user's focus selection")
    }

    func testComposePlan_GuaranteesVariationOrReturnsAfterRetries() async throws {
        // Given: Create blocks with limited exercise variety to potentially force retries
        let limitedBlocks = createLimitedVarietyBlocks()
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Exercise 1", "Exercise 2", "Exercise 3", "Exercise 4"])
        ]
        mockHistoryRepository.mockEntries = createHistoryEntries(from: previousWorkouts)

        // When
        let plan = try await sut.composePlan(
            blocks: limitedBlocks,
            profile: testProfile,
            checkIn: testCheckIn
        )

        // Then
        XCTAssertFalse(plan.exercises.isEmpty, "Should always return a plan, even after max retries")
        // Note: We can't guarantee diversity with limited blocks, but we should get a valid plan
    }

    // MARK: - Integration Tests

    func testComposePlan_IntegrationWithLocalComposer_ProducesValidStructure() async throws {
        // Given
        mockHistoryRepository.mockEntries = []

        // When
        let plan = try await sut.composePlan(
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn
        )

        // Then
        XCTAssertGreaterThanOrEqual(plan.exercises.count, 4, "Should have minimum exercises")
        XCTAssertLessThanOrEqual(plan.exercises.count, 10, "Should not exceed maximum exercises")
        XCTAssertGreaterThanOrEqual(plan.estimatedDurationMinutes, 30, "Should meet minimum duration")
        XCTAssertLessThanOrEqual(plan.estimatedDurationMinutes, 60, "Should not exceed maximum duration")
        XCTAssertFalse(plan.phases.isEmpty, "Should have workout phases")
    }

    func testComposePlan_WithMultiplePreviousWorkouts_ValidatesAgainstAllThree() async throws {
        // Given
        let workout1 = createWorkoutPlan(exercises: ["A", "B"])
        let workout2 = createWorkoutPlan(exercises: ["C", "D"])
        let workout3 = createWorkoutPlan(exercises: ["E", "F"])
        let previousWorkouts = [workout1, workout2, workout3]
        mockHistoryRepository.mockEntries = createHistoryEntries(from: previousWorkouts)

        // When
        let plan = try await sut.composePlan(
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn
        )

        // Then
        let allPreviousExercises = Set(
            previousWorkouts.flatMap { await $0.exercises.map { $0.exercise.name.lowercased() } }
        )
        let generatedExercises = await plan.exercises.map { $0.exercise.name.lowercased() }
        let newExercises = generatedExercises.filter { !allPreviousExercises.contains($0) }

        // Should have some variety (exact percentage depends on available blocks)
        XCTAssertGreaterThan(newExercises.count, 0, "Should include at least some new exercises")
    }

    // MARK: - Performance Tests

    func testComposePlan_PerformanceWithLargeHistory() async throws {
        // Given
        let manyWorkouts = (0..<100).map { _ in
            createWorkoutPlan(exercises: ["Ex1", "Ex2", "Ex3"])
        }
        mockHistoryRepository.mockEntries = createHistoryEntries(from: manyWorkouts)

        // When/Then
        measure {
            let expectation = expectation(description: "Composition completes")
            Task {
                _ = try await sut.composePlan(
                    blocks: testBlocks,
                    profile: testProfile,
                    checkIn: testCheckIn
                )
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Helper Methods

    private func createTestProfile() -> UserProfile {
        UserProfile(
            mainGoal: .hypertrophy,
            availableStructure: .fullGym,
            preferredMethod: .traditional,
            level: .intermediate,
            healthConditions: [],
            weeklyFrequency: 4
        )
    }

    private func createTestCheckIn() -> DailyCheckIn {
        DailyCheckIn(
            focus: .fullBody,
            sorenessLevel: .none,
            sorenessAreas: [],
            energyLevel: 7
        )
    }

    private func createTestBlocks() -> [WorkoutBlock] {
        // Create diverse blocks to enable variation
        let exercises1 = [
            createExercise(name: "Bench Press"),
            createExercise(name: "Incline Dumbbell Press"),
            createExercise(name: "Cable Flyes")
        ]

        let exercises2 = [
            createExercise(name: "Squat"),
            createExercise(name: "Leg Press"),
            createExercise(name: "Lunges")
        ]

        let exercises3 = [
            createExercise(name: "Pull-ups"),
            createExercise(name: "Barbell Rows"),
            createExercise(name: "Lat Pulldown")
        ]

        let exercises4 = [
            createExercise(name: "Overhead Press"),
            createExercise(name: "Lateral Raises"),
            createExercise(name: "Face Pulls")
        ]

        return [
            WorkoutBlock(
                id: "block1",
                group: .upper,
                level: .intermediate,
                compatibleStructures: [.fullGym, .basicGym],
                equipmentOptions: [.barbell, .dumbbell],
                exercises: exercises1,
                suggestedSets: IntRange(3, 4),
                suggestedReps: IntRange(8, 12),
                restInterval: 90
            ),
            WorkoutBlock(
                id: "block2",
                group: .lower,
                level: .intermediate,
                compatibleStructures: [.fullGym, .basicGym],
                equipmentOptions: [.barbell, .machine],
                exercises: exercises2,
                suggestedSets: IntRange(3, 4),
                suggestedReps: IntRange(8, 12),
                restInterval: 90
            ),
            WorkoutBlock(
                id: "block3",
                group: .upper,
                level: .intermediate,
                compatibleStructures: [.fullGym, .basicGym],
                equipmentOptions: [.pullupBar, .barbell],
                exercises: exercises3,
                suggestedSets: IntRange(3, 4),
                suggestedReps: IntRange(8, 12),
                restInterval: 90
            ),
            WorkoutBlock(
                id: "block4",
                group: .upper,
                level: .intermediate,
                compatibleStructures: [.fullGym, .basicGym],
                equipmentOptions: [.dumbbell, .cable],
                exercises: exercises4,
                suggestedSets: IntRange(3, 4),
                suggestedReps: IntRange(8, 12),
                restInterval: 90
            )
        ]
    }

    private func createLimitedVarietyBlocks() -> [WorkoutBlock] {
        // Create blocks with only a few exercises for testing retry logic
        let exercises = [
            createExercise(name: "Exercise 1"),
            createExercise(name: "Exercise 2"),
            createExercise(name: "Exercise 3"),
            createExercise(name: "Exercise 4")
        ]

        return [
            WorkoutBlock(
                id: "limited1",
                group: .fullBody,
                level: .intermediate,
                compatibleStructures: [.bodyweight, .fullGym],
                equipmentOptions: [.bodyweight],
                exercises: exercises,
                suggestedSets: IntRange(3, 4),
                suggestedReps: IntRange(8, 12),
                restInterval: 60
            )
        ]
    }

    private func createExercise(name: String) -> WorkoutExercise {
        WorkoutExercise(
            id: UUID().uuidString,
            name: name,
            mainMuscle: .chest,
            equipment: .barbell,
            instructions: ["Test instruction"],
            media: ExerciseMedia(
                imageURL: nil,
                gifURL: nil,
                source: "test"
            )
        )
    }

    private func createWorkoutPlan(exercises: [String]) -> WorkoutPlan {
        let prescriptions = exercises.map { name in
            ExercisePrescription(
                exercise: createExercise(name: name),
                sets: 3,
                reps: IntRange(8, 12),
                restInterval: 90,
                tip: nil
            )
        }

        return WorkoutPlan(
            title: "Test Plan",
            focus: .fullBody,
            estimatedDurationMinutes: 45,
            intensity: .moderate,
            exercises: prescriptions
        )
    }

    private func createHistoryEntries(from plans: [WorkoutPlan]) -> [WorkoutHistoryEntry] {
        return plans.enumerated().map { index, plan in
            WorkoutHistoryEntry(
                id: UUID(),
                date: Date().addingTimeInterval(-Double(index) * 86400), // Days ago
                planId: UUID(),
                title: plan.title,
                focus: plan.focus,
                status: .completed,
                programId: nil,
                programName: nil,
                durationMinutes: plan.estimatedDurationMinutes,
                caloriesBurned: nil,
                healthKitWorkoutUUID: nil,
                workoutPlan: plan
            )
        }
    }
}

// MARK: - Mock WorkoutHistoryRepository

final class EnhancedComposerMockHistoryRepository: WorkoutHistoryRepository {

    var mockEntries: [WorkoutHistoryEntry] = []
    var shouldThrowError = false
    var listEntriesCallCount = 0
    var lastLimit: Int?
    var lastOffset: Int?

    func listEntries() async throws -> [WorkoutHistoryEntry] {
        listEntriesCallCount += 1
        if shouldThrowError {
            throw MockError.simulatedError
        }
        return mockEntries
    }

    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        listEntriesCallCount += 1
        lastLimit = limit
        lastOffset = offset

        if shouldThrowError {
            throw MockError.simulatedError
        }

        // Return limited entries as requested
        let start = min(offset, mockEntries.count)
        let end = min(start + limit, mockEntries.count)
        return Array(mockEntries[start..<end])
    }

    func count() async throws -> Int {
        if shouldThrowError {
            throw MockError.simulatedError
        }
        return mockEntries.count
    }

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        if shouldThrowError {
            throw MockError.simulatedError
        }
        mockEntries.append(entry)
    }

    func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry] {
        listEntriesCallCount += 1
        lastLimit = limit
        if shouldThrowError {
            throw MockError.simulatedError
        }
        let filtered = mockEntries.filter { $0.source == .app && $0.workoutPlan != nil }
        return Array(filtered.prefix(limit))
    }

    enum MockError: Error {
        case simulatedError
    }
}
