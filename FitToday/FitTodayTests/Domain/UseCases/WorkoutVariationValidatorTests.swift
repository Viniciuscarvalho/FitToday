//
//  WorkoutVariationValidatorTests.swift
//  FitTodayTests
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 1.0)
//

import XCTest
@testable import FitToday

final class WorkoutVariationValidatorTests: XCTestCase {

    // MARK: - OpenAIWorkoutResponse Validation Tests

    func testValidateDiversity_WithEmptyGeneratedWorkout_ReturnsFalse() {
        // Given
        let emptyResponse = OpenAIWorkoutResponse(
            phases: [
                OpenAIPhaseResponse(kind: "strength", exercises: [], activity: nil)
            ],
            title: "Empty Workout",
            notes: nil
        )
        let previousWorkouts: [WorkoutPlan] = []

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: emptyResponse,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertFalse(isValid, "Empty workout should be invalid")
    }

    func testValidateDiversity_WithNoPreviousWorkouts_ReturnsTrue() {
        // Given
        let generatedResponse = createOpenAIResponse(exercises: [
            "Bench Press",
            "Squat",
            "Deadlift"
        ])
        let previousWorkouts: [WorkoutPlan] = []

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertTrue(isValid, "First workout should always be valid (100% new exercises)")
    }

    func testValidateDiversity_With100PercentOverlap_ReturnsFalse() {
        // Given
        let exercises = ["Bench Press", "Squat", "Deadlift"]
        let generatedResponse = createOpenAIResponse(exercises: exercises)
        let previousWorkouts = [
            createWorkoutPlan(exercises: exercises)
        ]

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertFalse(isValid, "100% overlap should fail diversity check (0% diversity < 60%)")
    }

    func testValidateDiversity_WithExactly60PercentNewExercises_ReturnsTrue() {
        // Given: 5 exercises total, 3 new (60%) and 2 repeated (40%)
        let generatedResponse = createOpenAIResponse(exercises: [
            "Bench Press",      // repeated
            "Squat",            // repeated
            "Romanian Deadlift", // new
            "Pull-ups",         // new
            "Dips"              // new
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press", "Squat", "Overhead Press"])
        ]

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts,
            minimumDiversityPercent: 0.6
        )

        // Then
        XCTAssertTrue(isValid, "60% diversity should meet threshold")
    }

    func testValidateDiversity_WithJustBelow60Percent_ReturnsFalse() {
        // Given: 5 exercises total, 2 new (40%) and 3 repeated (60%)
        let generatedResponse = createOpenAIResponse(exercises: [
            "Bench Press",      // repeated
            "Squat",            // repeated
            "Deadlift",         // repeated
            "Pull-ups",         // new
            "Dips"              // new
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press", "Squat", "Deadlift", "Overhead Press"])
        ]

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts,
            minimumDiversityPercent: 0.6
        )

        // Then
        XCTAssertFalse(isValid, "40% diversity should fail threshold (< 60%)")
    }

    func testValidateDiversity_WithCaseInsensitiveMatching_DetectsOverlap() {
        // Given
        let generatedResponse = createOpenAIResponse(exercises: [
            "BENCH PRESS",  // Should match "bench press" (case-insensitive)
            "squat",        // Should match "Squat" (case-insensitive)
            "Pull-ups"      // New exercise
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["bench press", "Squat", "Deadlift"])
        ]

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then: 1 new out of 3 = 33% diversity (fails 60% threshold)
        XCTAssertFalse(isValid, "Case-insensitive matching should detect overlaps")
    }

    func testValidateDiversity_WithWhitespaceVariations_DetectsOverlap() {
        // Given
        let generatedResponse = createOpenAIResponse(exercises: [
            "  Bench Press  ",  // Extra whitespace
            " Squat",           // Leading whitespace
            "Pull-ups"          // New exercise
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press", "Squat", "Deadlift"])
        ]

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then: 1 new out of 3 = 33% diversity (fails 60% threshold)
        XCTAssertFalse(isValid, "Trimmed whitespace should detect overlaps")
    }

    func testValidateDiversity_WithLast3WorkoutsOnly_IgnoresOlderWorkouts() {
        // Given
        let generatedResponse = createOpenAIResponse(exercises: [
            "Bench Press",  // In workout 1
            "Squat",        // In workout 2
            "Deadlift",     // In workout 3
            "Pull-ups",     // Only in workout 4 (should be ignored)
            "Dips"          // New
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press"]),      // Workout 1 (recent)
            createWorkoutPlan(exercises: ["Squat"]),            // Workout 2
            createWorkoutPlan(exercises: ["Deadlift"]),         // Workout 3 (oldest considered)
            createWorkoutPlan(exercises: ["Pull-ups"])          // Workout 4 (ignored - outside last 3)
        ]

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then: 2 new out of 5 = 40% diversity (fails 60% threshold)
        // Pull-ups is NOT considered new because validator only looks at last 3 workouts
        XCTAssertFalse(isValid, "Should only compare against last 3 workouts")
    }

    func testCalculateDiversityRatio_WithFullDiversity_Returns100Percent() {
        // Given
        let generatedResponse = createOpenAIResponse(exercises: [
            "Pull-ups",
            "Dips",
            "Lunges"
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press", "Squat", "Deadlift"])
        ]

        // When
        let ratio = WorkoutVariationValidator.calculateDiversityRatio(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertEqual(ratio, 1.0, accuracy: 0.01, "100% new exercises should return 1.0")
    }

    func testCalculateDiversityRatio_WithNoDiversity_Returns0Percent() {
        // Given
        let exercises = ["Bench Press", "Squat", "Deadlift"]
        let generatedResponse = createOpenAIResponse(exercises: exercises)
        let previousWorkouts = [
            createWorkoutPlan(exercises: exercises)
        ]

        // When
        let ratio = WorkoutVariationValidator.calculateDiversityRatio(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertEqual(ratio, 0.0, accuracy: 0.01, "0% new exercises should return 0.0")
    }

    func testCalculateDiversityRatio_WithPartialDiversity_ReturnsCorrectPercentage() {
        // Given: 5 exercises, 3 new (60%)
        let generatedResponse = createOpenAIResponse(exercises: [
            "Bench Press",  // repeated
            "Squat",        // repeated
            "Pull-ups",     // new
            "Dips",         // new
            "Lunges"        // new
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press", "Squat", "Deadlift"])
        ]

        // When
        let ratio = WorkoutVariationValidator.calculateDiversityRatio(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertEqual(ratio, 0.6, accuracy: 0.01, "3 new out of 5 should return 0.6 (60%)")
    }

    // MARK: - WorkoutPlan Validation Tests

    func testValidateDiversity_WithWorkoutPlan_WithNoPreviousWorkouts_ReturnsTrue() {
        // Given
        let generatedPlan = createWorkoutPlan(exercises: [
            "Bench Press",
            "Squat",
            "Deadlift"
        ])
        let previousWorkouts: [WorkoutPlan] = []

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedPlan,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertTrue(isValid, "First workout should always be valid")
    }

    func testValidateDiversity_WithWorkoutPlan_With60PercentDiversity_ReturnsTrue() {
        // Given
        let generatedPlan = createWorkoutPlan(exercises: [
            "Bench Press",  // repeated
            "Squat",        // repeated
            "Pull-ups",     // new
            "Dips",         // new
            "Lunges"        // new
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press", "Squat", "Deadlift"])
        ]

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedPlan,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertTrue(isValid, "60% diversity should meet threshold")
    }

    func testValidateDiversity_WithWorkoutPlan_Below60Percent_ReturnsFalse() {
        // Given
        let generatedPlan = createWorkoutPlan(exercises: [
            "Bench Press",  // repeated
            "Squat",        // repeated
            "Deadlift",     // repeated
            "Pull-ups",     // new
            "Dips"          // new
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press", "Squat", "Deadlift", "Overhead Press"])
        ]

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedPlan,
            previousWorkouts: previousWorkouts
        )

        // Then: 2 new out of 5 = 40% (fails 60% threshold)
        XCTAssertFalse(isValid, "40% diversity should fail threshold")
    }

    // MARK: - Edge Cases

    func testValidateDiversity_WithEmptyPreviousWorkouts_AlwaysReturnsTrue() {
        // Given
        let generatedResponse = createOpenAIResponse(exercises: ["Bench Press"])
        let previousWorkouts: [WorkoutPlan] = []

        // When
        let isValid = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertTrue(isValid, "First workout should always be valid")
    }

    func testValidateDiversity_WithCustomThreshold_AppliesCorrectly() {
        // Given: 5 exercises, 2 new (40%)
        let generatedResponse = createOpenAIResponse(exercises: [
            "Bench Press",  // repeated
            "Squat",        // repeated
            "Deadlift",     // repeated
            "Pull-ups",     // new
            "Dips"          // new
        ])
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press", "Squat", "Deadlift"])
        ]

        // When: Test with 30% threshold (should pass)
        let isValidWithLowThreshold = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts,
            minimumDiversityPercent: 0.3
        )

        // When: Test with 50% threshold (should fail)
        let isValidWithHighThreshold = WorkoutVariationValidator.validateDiversity(
            generated: generatedResponse,
            previousWorkouts: previousWorkouts,
            minimumDiversityPercent: 0.5
        )

        // Then
        XCTAssertTrue(isValidWithLowThreshold, "40% diversity should pass 30% threshold")
        XCTAssertFalse(isValidWithHighThreshold, "40% diversity should fail 50% threshold")
    }

    func testCalculateDiversityRatio_WithEmptyGeneratedWorkout_Returns0() {
        // Given
        let emptyResponse = OpenAIWorkoutResponse(
            phases: [OpenAIPhaseResponse(kind: "strength", exercises: [], activity: nil)],
            title: "Empty",
            notes: nil
        )
        let previousWorkouts = [
            createWorkoutPlan(exercises: ["Bench Press"])
        ]

        // When
        let ratio = WorkoutVariationValidator.calculateDiversityRatio(
            generated: emptyResponse,
            previousWorkouts: previousWorkouts
        )

        // Then
        XCTAssertEqual(ratio, 0.0, "Empty workout should return 0.0 ratio")
    }

    // MARK: - Helper Methods

    private func createOpenAIResponse(exercises: [String]) -> OpenAIWorkoutResponse {
        let exerciseResponses = exercises.map { name in
            OpenAIExerciseResponse(
                name: name,
                muscleGroup: "chest",
                equipment: "barbell",
                sets: 3,
                reps: "8-12",
                restSeconds: 90,
                notes: nil
            )
        }

        return OpenAIWorkoutResponse(
            phases: [
                OpenAIPhaseResponse(
                    kind: "strength",
                    exercises: exerciseResponses,
                    activity: nil
                )
            ],
            title: "Test Workout",
            notes: nil
        )
    }

    private func createWorkoutPlan(exercises: [String]) -> WorkoutPlan {
        let prescriptions = exercises.map { name in
            ExercisePrescription(
                exercise: Exercise(
                    id: UUID().uuidString,
                    name: name,
                    equipment: .barbell,
                    muscleGroups: [.chest],
                    instructions: [],
                    media: ExerciseMedia(imageURL: nil, gifURL: nil, videoURL: nil, placeholderName: nil, source: "test")
                ),
                sets: 3,
                repsRange: RepsRange.exact(10),
                restSeconds: 90,
                notes: nil
            )
        }

        return WorkoutPlan(
            id: UUID().uuidString,
            title: "Test Plan",
            focus: .fullBody,
            structure: .fullGym,
            goal: .hypertrophy,
            level: .intermediate,
            phases: [
                WorkoutPhase(kind: .strength, items: prescriptions.map { .exercise($0) })
            ],
            exercises: prescriptions,
            createdAt: Date()
        )
    }
}
