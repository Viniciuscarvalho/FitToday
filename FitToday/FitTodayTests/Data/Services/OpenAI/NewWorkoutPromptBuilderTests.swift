//
//  NewWorkoutPromptBuilderTests.swift
//  FitTodayTests
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 3.0)
//

import XCTest
@testable import FitToday

final class NewWorkoutPromptBuilderTests: XCTestCase {

    private var builder: NewWorkoutPromptBuilder!
    private var testBlueprint: WorkoutBlueprint!
    private var testBlocks: [WorkoutBlock]!
    private var testProfile: UserProfile!
    private var testCheckIn: DailyCheckIn!

    override func setUp() {
        super.setUp()
        builder = NewWorkoutPromptBuilder()

        // Create test fixtures
        testProfile = UserProfile(
            name: "Test User",
            mainGoal: .hypertrophy,
            level: .intermediate,
            weeklyFrequency: 4,
            availableStructure: .homeFullEquipment,
            healthConditions: []
        )

        testCheckIn = DailyCheckIn(
            focus: .upper,
            energyLevel: 7,
            sorenessLevel: .light,
            sorenessAreas: []
        )

        testBlueprint = WorkoutBlueprint(
            title: "Upper Body Strength",
            goal: .hypertrophy,
            focus: .upper,
            intensity: .moderate,
            estimatedDurationMinutes: 60,
            isRecoveryMode: false,
            variationSeed: 12345,
            equipmentConstraints: EquipmentConstraints(
                allowedEquipment: [.barbell, .dumbbells, .bench]
            ),
            blocks: [
                WorkoutBlueprintBlock(
                    title: "Main Strength",
                    phaseKind: .strength,
                    exerciseCount: 5,
                    targetMuscles: [.chest, .back],
                    avoidMuscles: [],
                    setsRange: 3...5,
                    repsRange: 6...10,
                    restSeconds: 120,
                    rpeTarget: 8
                )
            ],
            version: .v1
        )

        testBlocks = [
            WorkoutBlock(
                id: UUID(),
                name: "Chest Press",
                category: .strength,
                equipmentOptions: [.barbell, .dumbbells],
                exercises: [
                    WorkoutExercise(
                        id: UUID(),
                        name: "Bench Press",
                        mainMuscle: .chest,
                        secondaryMuscles: [.triceps, .shoulders],
                        equipment: .barbell,
                        difficulty: .intermediate
                    )
                ]
            )
        ]
    }

    override func tearDown() {
        builder = nil
        testBlueprint = nil
        testBlocks = nil
        testProfile = nil
        testCheckIn = nil
        super.tearDown()
    }

    // MARK: - Basic Prompt Construction Tests

    func testBuildPromptReturnsNonEmptyString() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("SYSTEM:"))
        XCTAssertTrue(prompt.contains("USER:"))
    }

    func testPromptIncludesGoalInformation() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("HYPERTROPHY"))
        XCTAssertTrue(prompt.contains("muscle hypertrophy"))
    }

    func testPromptIncludesEquipmentConstraints() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("barbell"))
        XCTAssertTrue(prompt.contains("dumbbells"))
        XCTAssertTrue(prompt.contains("bench"))
    }

    func testPromptIncludesUserLevel() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("intermediate"))
    }

    func testPromptIncludesCheckInState() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("upper"))
        XCTAssertTrue(prompt.contains("7/10"))
        XCTAssertTrue(prompt.contains("light"))
    }

    // MARK: - Previous Workouts Tests

    func testPromptIncludesPreviousWorkoutsWhenProvided() {
        // Given
        let previousWorkout = WorkoutPlan(
            title: "Previous Workout",
            focus: .upper,
            estimatedDurationMinutes: 60,
            intensity: .moderate,
            phases: [
                WorkoutPlanPhase(
                    kind: .strength,
                    title: "Strength",
                    rpeTarget: 8,
                    items: [
                        .exercise(ExercisePrescription(
                            exercise: WorkoutExercise(
                                id: UUID(),
                                name: "Squat",
                                mainMuscle: .quads,
                                secondaryMuscles: [],
                                equipment: .barbell,
                                difficulty: .intermediate
                            ),
                            sets: 5,
                            reps: IntRange(5, 8),
                            restInterval: 180
                        ))
                    ]
                )
            ],
            createdAt: Date()
        )

        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: [previousWorkout]
        )

        // Then
        XCTAssertTrue(prompt.contains("PROHIBITED EXERCISES"))
        XCTAssertTrue(prompt.contains("Squat"))
        XCTAssertTrue(prompt.contains("DO NOT REPEAT"))
    }

    func testPromptDoesNotIncludeProhibitedSectionWhenNoPreviousWorkouts() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertFalse(prompt.contains("PROHIBITED EXERCISES"))
    }

    func testPromptIncludesMultiplePreviousWorkouts() {
        // Given
        let workout1 = createTestWorkoutPlan(exercises: ["Bench Press", "Squat"])
        let workout2 = createTestWorkoutPlan(exercises: ["Deadlift", "Pull-up"])
        let workout3 = createTestWorkoutPlan(exercises: ["Overhead Press"])

        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: [workout1, workout2, workout3]
        )

        // Then
        XCTAssertTrue(prompt.contains("PROHIBITED EXERCISES"))
        XCTAssertTrue(prompt.contains("Bench Press"))
        XCTAssertTrue(prompt.contains("Squat"))
        XCTAssertTrue(prompt.contains("Deadlift"))
        XCTAssertTrue(prompt.contains("Pull-up"))
        XCTAssertTrue(prompt.contains("Overhead Press"))
    }

    // MARK: - Goal-Specific Guidelines Tests

    func testHypertrophyGoalGuidelines() {
        // Given
        testProfile = testProfile.with(mainGoal: .hypertrophy)

        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("multi-joint"))
        XCTAssertTrue(prompt.contains("Progressive overload"))
    }

    func testWeightLossGoalGuidelines() {
        // Given
        testProfile = testProfile.with(mainGoal: .weightLoss)
        testBlueprint = testBlueprint.with(goal: .weightLoss)

        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("circuits"))
        XCTAssertTrue(prompt.contains("energy expenditure"))
    }

    func testPerformanceGoalGuidelines() {
        // Given
        testProfile = testProfile.with(mainGoal: .performance)
        testBlueprint = testBlueprint.with(goal: .performance)

        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("Explosive"))
        XCTAssertTrue(prompt.contains("functional"))
    }

    // MARK: - Health Conditions Tests

    func testPromptIncludesHealthConditions() {
        // Given
        testProfile = UserProfile(
            name: "Test User",
            mainGoal: .hypertrophy,
            level: .intermediate,
            weeklyFrequency: 4,
            availableStructure: .homeFullEquipment,
            healthConditions: [.lowerBackPain, .knee]
        )

        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("lower back pain"))
        XCTAssertTrue(prompt.contains("knee"))
    }

    func testPromptHandlesNoHealthConditions() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("Health conditions: none"))
    }

    // MARK: - Blueprint Formatting Tests

    func testPromptIncludesBlueprintPhases() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("Main Strength"))
        XCTAssertTrue(prompt.contains("strength"))
        XCTAssertTrue(prompt.contains("EXERCISES: 5"))
    }

    func testPromptIncludesRecoveryMode() {
        // Given
        testBlueprint = testBlueprint.with(isRecoveryMode: true)

        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("Recovery mode: YES"))
    }

    // MARK: - Exercise Catalog Tests

    func testPromptIncludesExerciseCatalog() {
        // When
        let prompt = builder.buildPrompt(
            blueprint: testBlueprint,
            blocks: testBlocks,
            profile: testProfile,
            checkIn: testCheckIn,
            previousWorkouts: []
        )

        // Then
        XCTAssertTrue(prompt.contains("AVAILABLE EXERCISES"))
        XCTAssertTrue(prompt.contains("Bench Press"))
        XCTAssertTrue(prompt.contains("CRITICAL: Use EXACTLY these exercise names"))
    }

    // MARK: - Helper Methods

    private func createTestWorkoutPlan(exercises: [String]) -> WorkoutPlan {
        let items = exercises.map { exerciseName in
            WorkoutPlanItem.exercise(ExercisePrescription(
                exercise: WorkoutExercise(
                    id: UUID(),
                    name: exerciseName,
                    mainMuscle: .chest,
                    secondaryMuscles: [],
                    equipment: .barbell,
                    difficulty: .intermediate
                ),
                sets: 3,
                reps: IntRange(8, 12),
                restInterval: 90
            ))
        }

        return WorkoutPlan(
            title: "Test Workout",
            focus: .upper,
            estimatedDurationMinutes: 60,
            intensity: .moderate,
            phases: [
                WorkoutPlanPhase(
                    kind: .strength,
                    title: "Strength",
                    rpeTarget: 8,
                    items: items
                )
            ],
            createdAt: Date()
        )
    }
}
