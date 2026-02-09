//
//  WorkoutExecutionViewModelTests.swift
//  FitTodayTests
//
//  Tests for WorkoutExecutionViewModel composition and state derivation.
//

@testable import FitToday
import XCTest
import Swinject

@MainActor
final class WorkoutExecutionViewModelTests: XCTestCase {
    var sut: WorkoutExecutionViewModel!
    var sessionStore: WorkoutSessionStore!
    var restTimer: RestTimerStore!
    var workoutTimer: WorkoutTimerStore!
    var mockResolver: Resolver!

    override func setUp() async throws {
        try await super.setUp()

        // Create mock resolver with required dependencies
        let container = Container()

        // Mock WorkoutHistoryRepository
        let mockHistoryRepo = MockWorkoutHistoryRepository()
        container.register(WorkoutHistoryRepository.self) { _ in mockHistoryRepo }

        mockResolver = container

        // Create stores
        sessionStore = WorkoutSessionStore(resolver: mockResolver)
        restTimer = RestTimerStore()
        workoutTimer = WorkoutTimerStore()

        // Create SUT
        sut = WorkoutExecutionViewModel(
            sessionStore: sessionStore,
            restTimer: restTimer,
            workoutTimer: workoutTimer
        )
    }

    override func tearDown() {
        sut = nil
        sessionStore = nil
        restTimer = nil
        workoutTimer = nil
        mockResolver = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Then
        XCTAssertEqual(sut.currentExerciseIndex, 0)
        XCTAssertNil(sut.currentPrescription)
        XCTAssertEqual(sut.overallProgress, 0.0)
        XCTAssertEqual(sut.workoutElapsedTime, 0)
        XCTAssertFalse(sut.isPaused)
        XCTAssertFalse(sut.isResting)
        XCTAssertFalse(sut.showCompletionScreen)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Workout Lifecycle Tests

    func testStartWorkout() {
        // Given
        let plan = makeTestWorkoutPlan()

        // When
        sut.startWorkout(with: plan)

        // Then
        XCTAssertNotNil(sessionStore.session)
        XCTAssertTrue(workoutTimer.isRunning)
        XCTAssertTrue(workoutTimer.hasStarted)
        XCTAssertEqual(sut.currentExerciseIndex, 0)
    }

    func testPauseWorkout() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When
        sut.pauseWorkout()

        // Then
        XCTAssertFalse(workoutTimer.isRunning)
        XCTAssertTrue(sut.isPaused)
    }

    func testResumeWorkout() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)
        sut.pauseWorkout()

        // When
        sut.resumeWorkout()

        // Then
        XCTAssertTrue(workoutTimer.isRunning)
        XCTAssertFalse(sut.isPaused)
    }

    func testTogglePause() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When - pause
        sut.togglePause()

        // Then
        XCTAssertFalse(workoutTimer.isRunning)

        // When - resume
        sut.togglePause()

        // Then
        XCTAssertTrue(workoutTimer.isRunning)
    }

    // MARK: - Exercise Navigation Tests

    func testNextExercise() {
        // Given
        let plan = makeTestWorkoutPlan(exerciseCount: 3)
        sut.startWorkout(with: plan)
        XCTAssertEqual(sut.currentExerciseIndex, 0)

        // When
        let isComplete1 = sut.nextExercise()

        // Then
        XCTAssertFalse(isComplete1)
        XCTAssertEqual(sut.currentExerciseIndex, 1)

        // When
        let isComplete2 = sut.nextExercise()

        // Then
        XCTAssertFalse(isComplete2)
        XCTAssertEqual(sut.currentExerciseIndex, 2)

        // When - last exercise
        let isComplete3 = sut.nextExercise()

        // Then
        XCTAssertTrue(isComplete3)
        XCTAssertTrue(sut.showCompletionScreen)
    }

    func testSkipExercise() {
        // Given
        let plan = makeTestWorkoutPlan(exerciseCount: 2)
        sut.startWorkout(with: plan)

        // When
        let isComplete = sut.skipExercise()

        // Then
        XCTAssertFalse(isComplete)
        XCTAssertEqual(sut.currentExerciseIndex, 1)
    }

    func testSelectExercise() {
        // Given
        let plan = makeTestWorkoutPlan(exerciseCount: 3)
        sut.startWorkout(with: plan)

        // When
        sut.selectExercise(at: 2)

        // Then
        XCTAssertEqual(sut.currentExerciseIndex, 2)
    }

    // MARK: - Set Completion Tests

    func testToggleSet() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When
        sut.toggleSet(at: 0)

        // Then
        let progress = sut.currentExerciseProgress
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress!.sets[0].isCompleted)
    }

    func testCompleteAllSets() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When
        sut.completeAllSets()

        // Then
        let progress = sut.currentExerciseProgress
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress!.isFullyCompleted)
        XCTAssertTrue(sut.isCurrentExerciseComplete)
    }

    func testToggleSetStartsRestTimer() async {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When
        sut.toggleSet(at: 0)

        // Wait a moment for rest timer to start
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Then
        XCTAssertTrue(sut.isResting)
        XCTAssertGreaterThan(sut.restTimeRemaining, 0)
    }

    // MARK: - Rest Timer Tests

    func testStartRestTimer() async {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When
        sut.startRestTimer()

        // Wait a moment
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Then
        XCTAssertTrue(sut.isResting)
        XCTAssertTrue(restTimer.isActive)
    }

    func testStartRestTimerWithCustomDuration() async {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When
        sut.startRestTimer(duration: 30)

        // Wait a moment
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Then
        XCTAssertTrue(sut.isResting)
        XCTAssertEqual(restTimer.totalSeconds, 30)
    }

    func testSkipRest() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)
        sut.startRestTimer()

        // When
        sut.skipRest()

        // Then
        XCTAssertFalse(sut.isResting)
        XCTAssertEqual(sut.restTimeRemaining, 0)
    }

    func testAddRestTime() async {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)
        sut.startRestTimer(duration: 30)

        // Wait a moment
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        let initialTotal = restTimer.totalSeconds

        // When
        sut.addRestTime(30)

        // Then
        XCTAssertEqual(restTimer.totalSeconds, initialTotal + 30)
    }

    // MARK: - Derived State Tests

    func testCurrentExerciseName() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // Then
        XCTAssertEqual(sut.currentExerciseName, "Bench Press")
    }

    func testCurrentSetNumber() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // Then
        XCTAssertEqual(sut.currentSetNumber, 1) // 1-indexed

        // When - complete first set
        sut.toggleSet(at: 0)

        // Then
        XCTAssertEqual(sut.currentSetNumber, 2)
    }

    func testTotalSets() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // Then
        XCTAssertEqual(sut.totalSets, 3)
    }

    func testOverallProgress() {
        // Given
        let plan = makeTestWorkoutPlan(exerciseCount: 2)
        sut.startWorkout(with: plan)

        // Then
        XCTAssertEqual(sut.overallProgress, 0.0)

        // When - complete first exercise
        sut.completeAllSets()
        sut.nextExercise()

        // Then
        XCTAssertGreaterThan(sut.overallProgress, 0.0)
    }

    func testFormattedWorkoutTime() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // Then
        XCTAssertEqual(sut.formattedWorkoutTime, "00:00")
    }

    func testFormattedRestTime() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)
        sut.startRestTimer(duration: 90)

        // Then
        XCTAssertEqual(sut.formattedRestTime, "1:30")
    }

    // MARK: - Exercise Substitution Tests

    func testShowSubstitution() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When
        sut.showSubstitution()

        // Then
        XCTAssertTrue(sut.showExerciseSubstitution)
    }

    func testHideSubstitution() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)
        sut.showSubstitution()

        // When
        sut.hideSubstitution()

        // Then
        XCTAssertFalse(sut.showExerciseSubstitution)
    }

    func testSubstituteExercise() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)
        let alternative = AlternativeExercise(
            id: "alt-1",
            name: "Dumbbell Press",
            reason: "Better for your situation"
        )

        // When
        sut.substituteExercise(with: alternative)

        // Then
        XCTAssertTrue(sut.hasSubstitution)
        XCTAssertEqual(sut.currentExerciseName, "Dumbbell Press")
        XCTAssertFalse(sut.showExerciseSubstitution)
    }

    func testRemoveSubstitution() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)
        let alternative = AlternativeExercise(
            id: "alt-1",
            name: "Dumbbell Press",
            reason: "Better"
        )
        sut.substituteExercise(with: alternative)

        // When
        sut.removeSubstitution()

        // Then
        XCTAssertFalse(sut.hasSubstitution)
        XCTAssertEqual(sut.currentExerciseName, "Bench Press")
    }

    // MARK: - Completion Tests

    func testFinishWorkout() async {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)

        // When
        await sut.finishWorkout(status: .completed)

        // Then
        XCTAssertTrue(sut.showCompletionScreen)
        XCTAssertFalse(workoutTimer.isRunning)
        XCTAssertFalse(restTimer.isActive)
    }

    func testDismissCompletion() {
        // Given
        let plan = makeTestWorkoutPlan()
        sut.startWorkout(with: plan)
        Task { await sut.finishWorkout(status: .completed) }

        // When
        sut.dismissCompletion()

        // Then
        XCTAssertFalse(sut.showCompletionScreen)
        XCTAssertNil(sessionStore.session)
        XCTAssertEqual(workoutTimer.elapsedSeconds, 0)
    }

    // MARK: - Error Handling Tests

    func testClearError() {
        // Given
        sut.errorMessage = "Test error"

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Helpers

    private func makeTestWorkoutPlan(exerciseCount: Int = 1) -> WorkoutPlan {
        var exercises: [ExercisePrescription] = []

        for i in 0..<exerciseCount {
            let exercise = WorkoutExercise(
                id: "exercise-\(i)",
                name: i == 0 ? "Bench Press" : "Exercise \(i)",
                mainMuscle: .chest,
                equipment: .barbell,
                instructions: ["Test instruction"],
                media: nil
            )

            let prescription = ExercisePrescription(
                exercise: exercise,
                sets: 3,
                reps: IntRange(min: 10, max: 10),
                restInterval: 60,
                tip: nil
            )

            exercises.append(prescription)
        }

        let phase = WorkoutPhase(
            type: .main,
            title: "Main",
            items: exercises.map { .exercise($0) }
        )

        return WorkoutPlan(
            id: UUID(),
            title: "Test Workout",
            structure: .fullGym,
            focus: .hypertrophy,
            level: .intermediate,
            goal: .strength,
            type: .exercise,
            phases: [phase],
            estimatedDurationMinutes: 45,
            intensity: .medium
        )
    }
}

// MARK: - Mock Repository

private class MockWorkoutHistoryRepository: WorkoutHistoryRepository {
    var savedEntries: [WorkoutHistoryEntry] = []

    func save(_ entry: WorkoutHistoryEntry) async throws {
        savedEntries.append(entry)
    }

    func fetchAll(limit: Int?) async throws -> [WorkoutHistoryEntry] {
        return Array(savedEntries.prefix(limit ?? savedEntries.count))
    }

    func fetchRecent(days: Int) async throws -> [WorkoutHistoryEntry] {
        return savedEntries
    }

    func delete(id: UUID) async throws {
        savedEntries.removeAll { $0.id == id }
    }

    func clear() async throws {
        savedEntries.removeAll()
    }
}
