//
//  WorkoutExecutionTests.swift
//  FitTodayTests
//
//  Testes para tracking de execução de treino.
//

import XCTest
@testable import FitToday

final class WorkoutExecutionTests: XCTestCase {
    
    // MARK: - SetProgress Tests
    
    func testSetProgressInitialState() {
        let set = SetProgress(setNumber: 1)
        
        XCTAssertEqual(set.setNumber, 1)
        XCTAssertFalse(set.isCompleted)
        XCTAssertNil(set.completedAt)
    }
    
    func testSetProgressComplete() {
        var set = SetProgress(setNumber: 1)
        set.complete()
        
        XCTAssertTrue(set.isCompleted)
        XCTAssertNotNil(set.completedAt)
    }
    
    func testSetProgressUncomplete() {
        var set = SetProgress(setNumber: 1, isCompleted: true, completedAt: Date())
        set.uncomplete()
        
        XCTAssertFalse(set.isCompleted)
        XCTAssertNil(set.completedAt)
    }
    
    // MARK: - ExerciseProgress Tests
    
    func testExerciseProgressInitialization() {
        let progress = ExerciseProgress(exerciseId: "ex1", totalSets: 3)
        
        XCTAssertEqual(progress.exerciseId, "ex1")
        XCTAssertEqual(progress.sets.count, 3)
        XCTAssertEqual(progress.completedSetsCount, 0)
        XCTAssertFalse(progress.isFullyCompleted)
    }
    
    func testExerciseProgressCompleteSets() {
        var progress = ExerciseProgress(exerciseId: "ex1", totalSets: 3)
        
        progress.completeSet(at: 0)
        XCTAssertEqual(progress.completedSetsCount, 1)
        XCTAssertFalse(progress.isFullyCompleted)
        
        progress.completeSet(at: 1)
        progress.completeSet(at: 2)
        XCTAssertEqual(progress.completedSetsCount, 3)
        XCTAssertTrue(progress.isFullyCompleted)
    }
    
    func testExerciseProgressToggle() {
        var progress = ExerciseProgress(exerciseId: "ex1", totalSets: 2)
        
        progress.toggleSet(at: 0)
        XCTAssertTrue(progress.sets[0].isCompleted)
        
        progress.toggleSet(at: 0)
        XCTAssertFalse(progress.sets[0].isCompleted)
    }
    
    func testExerciseProgressPercentage() {
        var progress = ExerciseProgress(exerciseId: "ex1", totalSets: 4)
        
        XCTAssertEqual(progress.progressPercentage, 0, accuracy: 0.01)
        
        progress.completeSet(at: 0)
        XCTAssertEqual(progress.progressPercentage, 0.25, accuracy: 0.01)
        
        progress.completeSet(at: 1)
        XCTAssertEqual(progress.progressPercentage, 0.5, accuracy: 0.01)
    }
    
    // MARK: - WorkoutProgress Tests
    
    func testWorkoutProgressInitialization() {
        let exercises = [
            ExerciseProgress(exerciseId: "ex1", totalSets: 3),
            ExerciseProgress(exerciseId: "ex2", totalSets: 4)
        ]
        let progress = WorkoutProgress(planId: UUID(), exercises: exercises)
        
        XCTAssertEqual(progress.exercises.count, 2)
        XCTAssertEqual(progress.totalExercises, 2)
        XCTAssertEqual(progress.completedExercisesCount, 0)
    }
    
    func testWorkoutProgressOverallPercentage() {
        var progress = WorkoutProgress(
            planId: UUID(),
            exercises: [
                ExerciseProgress(exerciseId: "ex1", totalSets: 2),
                ExerciseProgress(exerciseId: "ex2", totalSets: 2)
            ]
        )
        
        // 0/4 sets completed
        XCTAssertEqual(progress.overallProgressPercentage, 0, accuracy: 0.01)
        
        // 1/4 sets completed
        progress.toggleSet(exerciseIndex: 0, setIndex: 0)
        XCTAssertEqual(progress.overallProgressPercentage, 0.25, accuracy: 0.01)
        
        // 2/4 sets completed
        progress.toggleSet(exerciseIndex: 0, setIndex: 1)
        XCTAssertEqual(progress.overallProgressPercentage, 0.5, accuracy: 0.01)
    }
    
    func testWorkoutProgressSkipExercise() {
        var progress = WorkoutProgress(
            planId: UUID(),
            exercises: [
                ExerciseProgress(exerciseId: "ex1", totalSets: 2),
                ExerciseProgress(exerciseId: "ex2", totalSets: 2)
            ]
        )
        
        progress.skipExercise(at: 0)
        
        XCTAssertTrue(progress.exercises[0].isSkipped)
        XCTAssertEqual(progress.completedExercisesCount, 1)
    }
    
    func testWorkoutProgressCompleteAll() {
        var progress = WorkoutProgress(
            planId: UUID(),
            exercises: [
                ExerciseProgress(exerciseId: "ex1", totalSets: 3)
            ]
        )
        
        progress.completeAllSets(exerciseIndex: 0)
        
        XCTAssertTrue(progress.exercises[0].isFullyCompleted)
        XCTAssertEqual(progress.exercises[0].completedSetsCount, 3)
    }
    
    func testWorkoutProgressIsFullyCompleted() {
        var progress = WorkoutProgress(
            planId: UUID(),
            exercises: [
                ExerciseProgress(exerciseId: "ex1", totalSets: 1),
                ExerciseProgress(exerciseId: "ex2", totalSets: 1)
            ]
        )
        
        XCTAssertFalse(progress.isFullyCompleted)
        
        progress.completeAllSets(exerciseIndex: 0)
        XCTAssertFalse(progress.isFullyCompleted)
        
        progress.completeAllSets(exerciseIndex: 1)
        XCTAssertTrue(progress.isFullyCompleted)
    }
    
    // MARK: - Encoding/Decoding Tests
    
    func testWorkoutProgressCodable() throws {
        let original = WorkoutProgress(
            planId: UUID(),
            exercises: [
                ExerciseProgress(exerciseId: "ex1", totalSets: 3)
            ]
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WorkoutProgress.self, from: data)
        
        XCTAssertEqual(decoded.planId, original.planId)
        XCTAssertEqual(decoded.exercises.count, original.exercises.count)
        XCTAssertEqual(decoded.exercises[0].exerciseId, original.exercises[0].exerciseId)
    }
}

// MARK: - RestTimerStore Tests

final class RestTimerStoreTests: XCTestCase {
    
    var timerStore: RestTimerStore!
    
    @MainActor
    override func setUp() {
        super.setUp()
        timerStore = RestTimerStore()
    }
    
    @MainActor
    override func tearDown() {
        timerStore?.stop()
        timerStore = nil
        super.tearDown()
    }
    
    @MainActor
    func testInitialState() {
        XCTAssertEqual(timerStore.remainingSeconds, 0)
        XCTAssertEqual(timerStore.totalSeconds, 0)
        XCTAssertFalse(timerStore.isActive)
        XCTAssertFalse(timerStore.isFinished)
    }
    
    @MainActor
    func testStartTimer() {
        timerStore.start(duration: 60)
        
        XCTAssertEqual(timerStore.totalSeconds, 60)
        XCTAssertEqual(timerStore.remainingSeconds, 60)
        XCTAssertTrue(timerStore.isActive)
        XCTAssertFalse(timerStore.isFinished)
    }
    
    @MainActor
    func testPauseTimer() {
        timerStore.start(duration: 60)
        timerStore.pause()
        
        XCTAssertFalse(timerStore.isActive)
    }
    
    @MainActor
    func testStopTimer() {
        timerStore.start(duration: 60)
        timerStore.stop()
        
        XCTAssertEqual(timerStore.remainingSeconds, 0)
        XCTAssertEqual(timerStore.totalSeconds, 0)
        XCTAssertFalse(timerStore.isActive)
    }
    
    @MainActor
    func testAddTime() {
        timerStore.start(duration: 60)
        timerStore.addTime(30)
        
        XCTAssertEqual(timerStore.totalSeconds, 90)
    }
    
    @MainActor
    func testFormattedTime() {
        timerStore.start(duration: 125) // 2:05
        
        XCTAssertEqual(timerStore.formattedTime, "2:05")
    }
    
    @MainActor
    func testProgressPercentage() {
        timerStore.start(duration: 100)
        
        // No início, progress é 0%
        XCTAssertEqual(timerStore.progressPercentage, 0, accuracy: 0.01)
    }
    
    @MainActor
    func testSkipFinishesTimer() {
        timerStore.start(duration: 60)
        timerStore.skip()
        
        XCTAssertTrue(timerStore.isFinished)
        XCTAssertFalse(timerStore.isActive)
    }
    
    @MainActor
    func testForceFinish() {
        timerStore.start(duration: 60)
        timerStore.forceFinish()
        
        XCTAssertTrue(timerStore.isFinished)
        XCTAssertEqual(timerStore.remainingSeconds, 0)
    }
}

