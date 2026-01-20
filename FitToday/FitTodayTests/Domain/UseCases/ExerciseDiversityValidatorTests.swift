//
//  ExerciseDiversityValidatorTests.swift
//  FitTodayTests
//
//  Created by Claude on 20/01/26.
//

import XCTest
@testable import FitToday

final class ExerciseDiversityValidatorTests: XCTestCase {

    private var sut: ExerciseDiversityValidator!

    override func setUp() {
        super.setUp()
        sut = ExerciseDiversityValidator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Edge Cases

    func testCalculateDiversityScore_whenNoNewExercises_shouldReturnFullScore() {
        // Given
        let newExercises: [String] = []
        let previousExercises: [[String]] = [["Bench Press", "Squat"]]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then
        XCTAssertEqual(result.score, 1.0)
        XCTAssertEqual(result.uniqueCount, 0)
        XCTAssertEqual(result.totalCount, 0)
        XCTAssertTrue(result.repeatedExercises.isEmpty)
        XCTAssertTrue(result.isValid)
    }

    func testCalculateDiversityScore_whenNoPreviousExercises_shouldReturnFullScore() {
        // Given
        let newExercises = ["Bench Press", "Squat", "Deadlift"]
        let previousExercises: [[String]] = []

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then
        XCTAssertEqual(result.score, 1.0)
        XCTAssertEqual(result.uniqueCount, 3)
        XCTAssertEqual(result.totalCount, 3)
        XCTAssertTrue(result.repeatedExercises.isEmpty)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - 100% Diversity (All Unique)

    func testCalculateDiversityScore_whenAllExercisesAreUnique_shouldReturn100Percent() {
        // Given
        let newExercises = ["Bench Press", "Squat", "Deadlift"]
        let previousExercises = [
            ["Lat Pulldown", "Bicep Curl"],
            ["Leg Press", "Calf Raise"],
            ["Shoulder Press", "Tricep Dip"]
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then
        XCTAssertEqual(result.score, 1.0)
        XCTAssertEqual(result.uniqueCount, 3)
        XCTAssertEqual(result.totalCount, 3)
        XCTAssertTrue(result.repeatedExercises.isEmpty)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - 0% Diversity (All Repeated)

    func testCalculateDiversityScore_whenAllExercisesAreRepeated_shouldReturn0Percent() {
        // Given
        let newExercises = ["Bench Press", "Squat", "Deadlift"]
        let previousExercises = [
            ["Bench Press", "Squat", "Deadlift"]
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then
        XCTAssertEqual(result.score, 0.0)
        XCTAssertEqual(result.uniqueCount, 0)
        XCTAssertEqual(result.totalCount, 3)
        XCTAssertEqual(result.repeatedExercises.count, 3)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Threshold Tests

    func testCalculateDiversityScore_whenExactly80Percent_shouldBeValid() {
        // Given - 5 exercises, 4 unique = 80%
        let newExercises = ["Bench Press", "Squat", "Deadlift", "Shoulder Press", "Lat Pulldown"]
        let previousExercises = [
            ["Lat Pulldown"] // Only one repeated
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then
        XCTAssertEqual(result.score, 0.8, accuracy: 0.001)
        XCTAssertEqual(result.uniqueCount, 4)
        XCTAssertEqual(result.totalCount, 5)
        XCTAssertEqual(result.repeatedExercises, ["Lat Pulldown"])
        XCTAssertTrue(result.isValid)
    }

    func testCalculateDiversityScore_whenBelow80Percent_shouldBeInvalid() {
        // Given - 5 exercises, 3 unique = 60%
        let newExercises = ["Bench Press", "Squat", "Deadlift", "Shoulder Press", "Lat Pulldown"]
        let previousExercises = [
            ["Bench Press", "Squat"] // Two repeated
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then
        XCTAssertEqual(result.score, 0.6, accuracy: 0.001)
        XCTAssertEqual(result.uniqueCount, 3)
        XCTAssertEqual(result.totalCount, 5)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Case Insensitivity

    func testCalculateDiversityScore_shouldBeCaseInsensitive() {
        // Given
        let newExercises = ["BENCH PRESS", "squat", "DeadLift"]
        let previousExercises = [
            ["bench press", "SQUAT", "deadlift"]
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then
        XCTAssertEqual(result.score, 0.0)
        XCTAssertEqual(result.uniqueCount, 0)
        XCTAssertEqual(result.repeatedExercises.count, 3)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Whitespace Handling

    func testCalculateDiversityScore_shouldTrimWhitespace() {
        // Given
        let newExercises = ["  Bench Press  ", "Squat", "Deadlift"]
        let previousExercises = [
            ["Bench Press", "  Squat  "]
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then
        XCTAssertEqual(result.uniqueCount, 1) // Only Deadlift is unique
        XCTAssertEqual(result.repeatedExercises.count, 2)
    }

    // MARK: - Fuzzy Matching

    func testCalculateDiversityScore_shouldDetectPartialMatches() {
        // Given - "Bench Press" should match with "Barbell Bench Press"
        let newExercises = ["Barbell Bench Press", "Squat", "Deadlift"]
        let previousExercises = [
            ["Bench Press", "Leg Press"]
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then - "Barbell Bench Press" contains "Bench Press"
        XCTAssertEqual(result.uniqueCount, 2) // Squat and Deadlift are unique
        XCTAssertTrue(result.repeatedExercises.contains("Barbell Bench Press"))
    }

    func testCalculateDiversityScore_shouldNotMatchShortSubstrings() {
        // Given - "Row" (3 chars) should NOT cause false positives with "Throw"
        // because the minimum string length for fuzzy matching is 4 characters
        let newExercises = ["Barbell Throw", "Medicine Ball Slam"]
        let previousExercises = [
            ["Row"] // Too short (3 chars < 4) to trigger fuzzy match
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then - Both exercises should be unique because "Row" is too short
        // to trigger fuzzy matching (even though "throw" contains "row")
        XCTAssertEqual(result.uniqueCount, 2)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Multiple Previous Workouts

    func testCalculateDiversityScore_shouldCheckAllPreviousWorkouts() {
        // Given
        let newExercises = ["Bench Press", "Squat", "Deadlift", "Shoulder Press", "Lat Pulldown"]
        let previousExercises = [
            ["Bench Press"], // Workout 1
            ["Squat"], // Workout 2
            ["Deadlift"] // Workout 3
        ]

        // When
        let result = sut.calculateDiversityScore(
            newExercises: newExercises,
            previousExercises: previousExercises
        )

        // Then - 2 unique (Shoulder Press, Lat Pulldown), 3 repeated = 40%
        XCTAssertEqual(result.score, 0.4, accuracy: 0.001)
        XCTAssertEqual(result.uniqueCount, 2)
        XCTAssertEqual(result.repeatedExercises.count, 3)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - DiversityResult Properties

    func testDiversityResult_description_whenValid() {
        // Given
        let result = DiversityResult(
            score: 0.85,
            uniqueCount: 17,
            totalCount: 20,
            repeatedExercises: ["Squat", "Bench Press", "Deadlift"]
        )

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.description.contains("85%"))
        XCTAssertTrue(result.description.contains("adequada"))
    }

    func testDiversityResult_description_whenInvalid() {
        // Given
        let result = DiversityResult(
            score: 0.65,
            uniqueCount: 13,
            totalCount: 20,
            repeatedExercises: ["Squat", "Bench Press", "Deadlift"]
        )

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.description.contains("65%"))
        XCTAssertTrue(result.description.contains("insuficiente"))
    }

    func testDiversityResult_requiredScore_is80Percent() {
        XCTAssertEqual(DiversityResult.requiredScore, 0.80)
    }
}
