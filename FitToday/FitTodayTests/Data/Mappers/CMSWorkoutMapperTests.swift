//
//  CMSWorkoutMapperTests.swift
//  FitTodayTests
//
//  Tests for CMS workout mapper transformations.
//

import XCTest
@testable import FitToday

final class CMSWorkoutMapperTests: XCTestCase {

    // MARK: - CMS to TrainerWorkout Tests

    func test_toDomain_mapsAllFields() {
        // Given
        let cms = CMSWorkout.fixture()

        // When
        let domain = CMSWorkoutMapper.toDomain(cms)

        // Then
        XCTAssertEqual(domain.id, cms.id)
        XCTAssertEqual(domain.trainerId, cms.trainerId)
        XCTAssertEqual(domain.title, cms.title)
        XCTAssertEqual(domain.description, cms.description)
        XCTAssertEqual(domain.estimatedDurationMinutes, cms.estimatedDurationMinutes)
        XCTAssertEqual(domain.version, cms.version)
        XCTAssertEqual(domain.pdfUrl, cms.pdfUrl)
        XCTAssertEqual(domain.createdAt, cms.createdAt)
    }

    func test_toDomain_mapsFocusCorrectly() {
        // Given - Test various focus mappings
        let testCases: [(String, DailyFocus)] = [
            ("fullbody", .fullBody),
            ("full_body", .fullBody),
            ("corpo todo", .fullBody),
            ("upper", .upper),
            ("superior", .upper),
            ("push", .upper),
            ("lower", .lower),
            ("inferior", .lower),
            ("legs", .lower),
            ("cardio", .cardio),
            ("aerobico", .cardio),
            ("core", .core),
            ("abdomen", .core),
            ("unknown", .surprise)
        ]

        for (input, expected) in testCases {
            // When
            let cms = CMSWorkout.fixture(focus: input)
            let domain = CMSWorkoutMapper.toDomain(cms)

            // Then
            XCTAssertEqual(domain.focus, expected, "Failed for input: \(input)")
        }
    }

    func test_toDomain_mapsIntensityCorrectly() {
        // Given - Test intensity mappings
        let testCases: [(String, WorkoutIntensity)] = [
            ("low", .low),
            ("baixa", .low),
            ("leve", .low),
            ("moderate", .moderate),
            ("moderada", .moderate),
            ("media", .moderate),
            ("high", .high),
            ("alta", .high),
            ("intensa", .high),
            ("unknown", .moderate)
        ]

        for (input, expected) in testCases {
            // When
            let cms = CMSWorkout.fixture(intensity: input)
            let domain = CMSWorkoutMapper.toDomain(cms)

            // Then
            XCTAssertEqual(domain.intensity, expected, "Failed for input: \(input)")
        }
    }

    func test_toDomain_mapsPhases() {
        // Given
        let phase1 = CMSWorkoutPhase(name: "Warmup", order: 0, items: [
            CMSWorkoutItem.fixture(exerciseName: "Jumping Jacks", sets: 3, reps: "20")
        ])
        let phase2 = CMSWorkoutPhase(name: "Main", order: 1, items: [
            CMSWorkoutItem.fixture(exerciseName: "Squats", sets: 4, reps: "8-12")
        ])
        let cms = CMSWorkout.fixture(phases: [phase1, phase2])

        // When
        let domain = CMSWorkoutMapper.toDomain(cms)

        // Then
        XCTAssertEqual(domain.phases.count, 2)
        XCTAssertEqual(domain.phases[0].name, "Warmup")
        XCTAssertEqual(domain.phases[0].items.count, 1)
        XCTAssertEqual(domain.phases[0].items[0].exerciseName, "Jumping Jacks")
        XCTAssertEqual(domain.phases[0].items[0].sets, 3)
    }

    func test_toDomain_parsesRepRangeCorrectly() {
        // Given - Test various rep formats
        let testCases: [(String, IntRange)] = [
            ("8-12", IntRange(8, 12)),
            ("10", IntRange(10, 10)),
            ("6-8", IntRange(6, 8)),
            ("invalid", IntRange(10, 12)) // Default fallback
        ]

        for (input, expected) in testCases {
            // When
            let item = CMSWorkoutItem.fixture(reps: input)
            let phase = CMSWorkoutPhase(name: "Test", order: 0, items: [item])
            let cms = CMSWorkout.fixture(phases: [phase])
            let domain = CMSWorkoutMapper.toDomain(cms)

            // Then
            let actualReps = domain.phases[0].items[0].reps
            XCTAssertEqual(actualReps.lowerBound, expected.lowerBound, "Failed for input: \(input)")
            XCTAssertEqual(actualReps.upperBound, expected.upperBound, "Failed for input: \(input)")
        }
    }

    func test_toDomain_mapsScheduleTypeCorrectly() {
        // Given - Test schedule type mappings
        let testCases: [(String, TrainerWorkoutScheduleType)] = [
            ("once", .once),
            ("single", .once),
            ("recurring", .recurring),
            ("repeat", .recurring),
            ("weekly", .weekly),
            ("semanal", .weekly),
            ("unknown", .once)
        ]

        for (input, expected) in testCases {
            // When
            let schedule = CMSWorkoutSchedule(type: input, scheduledDate: nil, dayOfWeek: nil, recurrence: nil)
            let cms = CMSWorkout.fixture(schedule: schedule)
            let domain = CMSWorkoutMapper.toDomain(cms)

            // Then
            XCTAssertEqual(domain.schedule.type, expected, "Failed for input: \(input)")
        }
    }

    func test_toDomain_mapsPdfUrl() {
        // Given
        let pdfUrlString = "https://example.com/workout.pdf"
        let cms = CMSWorkout.fixture(pdfUrl: pdfUrlString)

        // When
        let domain = CMSWorkoutMapper.toDomain(cms)

        // Then
        XCTAssertEqual(domain.pdfUrl, pdfUrlString)
    }

    func test_toDomain_handlesNilPdfUrl() {
        // Given
        let cms = CMSWorkout.fixture(pdfUrl: nil)

        // When
        let domain = CMSWorkoutMapper.toDomain(cms)

        // Then
        XCTAssertNil(domain.pdfUrl)
    }

    func test_toDomain_handlesNilSchedule() {
        // Given
        let cms = CMSWorkout.fixture(schedule: nil)

        // When
        let domain = CMSWorkoutMapper.toDomain(cms)

        // Then
        XCTAssertEqual(domain.schedule.type, .once)
        XCTAssertNil(domain.schedule.scheduledDate)
        XCTAssertNil(domain.schedule.dayOfWeek)
    }

    // MARK: - CMS to WorkoutPlan Tests

    func test_toWorkoutPlan_createsValidPlan() {
        // Given
        let cms = CMSWorkout.fixture(
            title: "Test Workout",
            focus: "upper",
            estimatedDurationMinutes: 45,
            intensity: "high"
        )

        // When
        let plan = CMSWorkoutMapper.toWorkoutPlan(cms)

        // Then
        XCTAssertEqual(plan.title, "Test Workout")
        XCTAssertEqual(plan.focus, .upper)
        XCTAssertEqual(plan.estimatedDurationMinutes, 45)
        XCTAssertEqual(plan.intensity, .high)
        XCTAssertEqual(plan.phases.count, cms.phases.count)
    }

    func test_toWorkoutPlan_mapsExercisesToPrescriptions() {
        // Given
        let item = CMSWorkoutItem.fixture(
            exerciseId: 123,
            exerciseName: "Bench Press",
            sets: 4,
            reps: "8-10",
            restSeconds: 90,
            notes: "Focus on form"
        )
        let phase = CMSWorkoutPhase(name: "Strength", order: 0, items: [item])
        let cms = CMSWorkout.fixture(phases: [phase])

        // When
        let plan = CMSWorkoutMapper.toWorkoutPlan(cms)

        // Then
        XCTAssertEqual(plan.phases.count, 1)
        let exercises = plan.phases[0].exercises
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises[0].exercise.name, "Bench Press")
        XCTAssertEqual(exercises[0].sets, 4)
        XCTAssertEqual(exercises[0].reps, IntRange(8, 10))
        XCTAssertEqual(exercises[0].restInterval, 90)
        XCTAssertEqual(exercises[0].tip, "Focus on form")
    }

    func test_toWorkoutPlan_mapsPhaseKindCorrectly() {
        // Given - Test phase name to kind mapping
        let testCases: [(String, WorkoutPlanPhase.Kind)] = [
            ("Warmup", .warmup),
            ("Aquecimento", .warmup),
            ("Strength Training", .strength),
            ("Força", .strength),
            ("Principal", .strength),
            ("Accessory Work", .accessory),
            ("Acessório", .accessory),
            ("Conditioning", .conditioning),
            ("Cardio Session", .aerobic),
            ("Aeróbico", .aerobic),
            ("Finisher", .finisher),
            ("Cooldown", .cooldown),
            ("Alongamento", .cooldown),
            ("Unknown Name", .strength) // Default
        ]

        for (phaseName, expectedKind) in testCases {
            // When
            let phase = CMSWorkoutPhase(name: phaseName, order: 0, items: [])
            let cms = CMSWorkout.fixture(phases: [phase])
            let plan = CMSWorkoutMapper.toWorkoutPlan(cms)

            // Then
            XCTAssertEqual(plan.phases[0].kind, expectedKind, "Failed for phase: \(phaseName)")
        }
    }

    func test_toWorkoutPlan_handlesMuscleGroupMapping() {
        // Given - Test focus to muscle group mapping
        let testCases: [(DailyFocus, MuscleGroup)] = [
            (.fullBody, .fullBody),
            (.upper, .chest),
            (.lower, .quadriceps),
            (.cardio, .fullBody),
            (.core, .core),
            (.surprise, .fullBody)
        ]

        for (focus, expectedMuscle) in testCases {
            // When
            let item = CMSWorkoutItem.fixture(exerciseName: "Exercise")
            let phase = CMSWorkoutPhase(name: "Test", order: 0, items: [item])
            let cms = CMSWorkout.fixture(focus: focus.rawValue, phases: [phase])
            let plan = CMSWorkoutMapper.toWorkoutPlan(cms)

            // Then
            let exercise = plan.phases[0].exercises[0].exercise
            XCTAssertEqual(exercise.mainMuscle, expectedMuscle, "Failed for focus: \(focus)")
        }
    }

    func test_toWorkoutPlan_createsUniqueWorkoutIds() {
        // Given
        let cms = CMSWorkout.fixture()

        // When
        let plan1 = CMSWorkoutMapper.toWorkoutPlan(cms)
        let plan2 = CMSWorkoutMapper.toWorkoutPlan(cms)

        // Then
        XCTAssertNotEqual(plan1.id, plan2.id)
    }
}

// MARK: - Fixtures

extension CMSWorkout {
    static func fixture(
        id: String = "workout123",
        trainerId: String = "trainer1",
        studentId: String = "student1",
        title: String = "Test Workout",
        description: String? = "Test description",
        focus: String = "fullbody",
        estimatedDurationMinutes: Int = 60,
        intensity: String = "moderate",
        phases: [CMSWorkoutPhase] = [
            CMSWorkoutPhase(name: "Main", order: 0, items: [
                CMSWorkoutItem.fixture()
            ])
        ],
        schedule: CMSWorkoutSchedule? = CMSWorkoutSchedule(type: "once", scheduledDate: nil, dayOfWeek: nil, recurrence: nil),
        status: CMSWorkoutStatus = .active,
        pdfUrl: String? = nil,
        version: Int = 1,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> CMSWorkout {
        CMSWorkout(
            id: id,
            trainerId: trainerId,
            studentId: studentId,
            title: title,
            description: description,
            focus: focus,
            estimatedDurationMinutes: estimatedDurationMinutes,
            intensity: intensity,
            phases: phases,
            schedule: schedule,
            status: status,
            pdfUrl: pdfUrl,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension CMSWorkoutItem {
    static func fixture(
        id: String = "item1",
        exerciseId: Int? = 100,
        exerciseName: String = "Test Exercise",
        sets: Int = 3,
        reps: String = "10-12",
        weight: String? = nil,
        restSeconds: Int = 60,
        notes: String? = nil,
        order: Int = 0
    ) -> CMSWorkoutItem {
        CMSWorkoutItem(
            id: id,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            sets: sets,
            reps: reps,
            weight: weight,
            restSeconds: restSeconds,
            notes: notes,
            order: order,
            mediaUrl: nil
        )
    }
}
