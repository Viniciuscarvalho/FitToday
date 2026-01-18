//
//  WorkoutRatingTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class WorkoutRatingTests: XCTestCase {

    // MARK: - WorkoutRating Enum Tests

    func test_workoutRating_rawValues() {
        XCTAssertEqual(WorkoutRating.tooEasy.rawValue, "too_easy")
        XCTAssertEqual(WorkoutRating.adequate.rawValue, "adequate")
        XCTAssertEqual(WorkoutRating.tooHard.rawValue, "too_hard")
    }

    func test_workoutRating_displayNames() {
        XCTAssertEqual(WorkoutRating.tooEasy.displayName, "Muito Fácil")
        XCTAssertEqual(WorkoutRating.adequate.displayName, "Adequado")
        XCTAssertEqual(WorkoutRating.tooHard.displayName, "Muito Difícil")
    }

    func test_workoutRating_emojis() {
        XCTAssertEqual(WorkoutRating.tooEasy.emoji, "😅")
        XCTAssertEqual(WorkoutRating.adequate.emoji, "💪")
        XCTAssertEqual(WorkoutRating.tooHard.emoji, "🔥")
    }

    func test_workoutRating_initFromRawString_validValues() {
        XCTAssertEqual(WorkoutRating(rawString: "too_easy"), .tooEasy)
        XCTAssertEqual(WorkoutRating(rawString: "adequate"), .adequate)
        XCTAssertEqual(WorkoutRating(rawString: "too_hard"), .tooHard)
    }

    func test_workoutRating_initFromRawString_invalidValue_returnsNil() {
        XCTAssertNil(WorkoutRating(rawString: "invalid"))
        XCTAssertNil(WorkoutRating(rawString: ""))
        XCTAssertNil(WorkoutRating(rawString: nil))
    }

    func test_workoutRating_codable() throws {
        // Given
        let rating = WorkoutRating.adequate

        // When
        let encoded = try JSONEncoder().encode(rating)
        let decoded = try JSONDecoder().decode(WorkoutRating.self, from: encoded)

        // Then
        XCTAssertEqual(decoded, rating)
    }

    func test_workoutRating_allCases() {
        XCTAssertEqual(WorkoutRating.allCases.count, 3)
        XCTAssertTrue(WorkoutRating.allCases.contains(.tooEasy))
        XCTAssertTrue(WorkoutRating.allCases.contains(.adequate))
        XCTAssertTrue(WorkoutRating.allCases.contains(.tooHard))
    }

    // MARK: - CompletedExercise Tests

    func test_completedExercise_init() {
        // Given/When
        let exercise = CompletedExercise(
            exerciseId: "ex123",
            exerciseName: "Bench Press",
            muscleGroup: "chest",
            completed: true
        )

        // Then
        XCTAssertEqual(exercise.exerciseId, "ex123")
        XCTAssertEqual(exercise.exerciseName, "Bench Press")
        XCTAssertEqual(exercise.muscleGroup, "chest")
        XCTAssertTrue(exercise.completed)
    }

    func test_completedExercise_defaultCompleted() {
        // Given/When
        let exercise = CompletedExercise(
            exerciseId: "ex123",
            exerciseName: "Squat",
            muscleGroup: "quads"
        )

        // Then
        XCTAssertTrue(exercise.completed)
    }

    func test_completedExercise_codable() throws {
        // Given
        let exercises = [
            CompletedExercise(exerciseId: "1", exerciseName: "Bench Press", muscleGroup: "chest"),
            CompletedExercise(exerciseId: "2", exerciseName: "Squat", muscleGroup: "quads", completed: false)
        ]

        // When
        let encoded = try JSONEncoder().encode(exercises)
        let decoded = try JSONDecoder().decode([CompletedExercise].self, from: encoded)

        // Then
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].exerciseId, "1")
        XCTAssertTrue(decoded[0].completed)
        XCTAssertEqual(decoded[1].exerciseId, "2")
        XCTAssertFalse(decoded[1].completed)
    }

    func test_completedExercise_hashable() {
        // Given
        let exercise1 = CompletedExercise(exerciseId: "1", exerciseName: "Bench", muscleGroup: "chest")
        let exercise2 = CompletedExercise(exerciseId: "1", exerciseName: "Bench", muscleGroup: "chest")
        let exercise3 = CompletedExercise(exerciseId: "2", exerciseName: "Squat", muscleGroup: "quads")

        // Then
        XCTAssertEqual(exercise1, exercise2)
        XCTAssertNotEqual(exercise1, exercise3)

        // Set behavior
        let set: Set<CompletedExercise> = [exercise1, exercise2, exercise3]
        XCTAssertEqual(set.count, 2)
    }
}
