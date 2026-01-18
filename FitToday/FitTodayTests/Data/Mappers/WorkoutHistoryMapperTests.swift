//
//  WorkoutHistoryMapperTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class WorkoutHistoryMapperTests: XCTestCase {

    // MARK: - toDomain Tests

    func test_toDomain_withUserRating_mapsCorrectly() {
        // Given
        let sdEntry = SDWorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Treino Superior",
            focusRaw: "upper",
            statusRaw: "completed",
            userRating: "adequate"
        )

        // When
        let domain = WorkoutHistoryMapper.toDomain(sdEntry)

        // Then
        XCTAssertNotNil(domain)
        XCTAssertEqual(domain?.userRating, .adequate)
    }

    func test_toDomain_withoutUserRating_returnsNilRating() {
        // Given
        let sdEntry = SDWorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Treino Inferior",
            focusRaw: "lower",
            statusRaw: "completed",
            userRating: nil
        )

        // When
        let domain = WorkoutHistoryMapper.toDomain(sdEntry)

        // Then
        XCTAssertNotNil(domain)
        XCTAssertNil(domain?.userRating)
    }

    func test_toDomain_withInvalidUserRating_returnsNilRating() {
        // Given
        let sdEntry = SDWorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Treino",
            focusRaw: "fullBody",
            statusRaw: "completed",
            userRating: "invalid_rating"
        )

        // When
        let domain = WorkoutHistoryMapper.toDomain(sdEntry)

        // Then
        XCTAssertNotNil(domain)
        XCTAssertNil(domain?.userRating)
    }

    func test_toDomain_withCompletedExercises_mapsCorrectly() throws {
        // Given
        let exercises = [
            CompletedExercise(exerciseId: "1", exerciseName: "Bench Press", muscleGroup: "chest"),
            CompletedExercise(exerciseId: "2", exerciseName: "Rows", muscleGroup: "back")
        ]
        let exercisesJSON = try JSONEncoder().encode(exercises)

        let sdEntry = SDWorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Treino",
            focusRaw: "upper",
            statusRaw: "completed",
            completedExercisesJSON: exercisesJSON
        )

        // When
        let domain = WorkoutHistoryMapper.toDomain(sdEntry)

        // Then
        XCTAssertNotNil(domain)
        XCTAssertEqual(domain?.completedExercises?.count, 2)
        XCTAssertEqual(domain?.completedExercises?[0].exerciseName, "Bench Press")
        XCTAssertEqual(domain?.completedExercises?[1].exerciseName, "Rows")
    }

    func test_toDomain_withInvalidCompletedExercisesJSON_returnsNilExercises() {
        // Given
        let invalidJSON = "not valid json".data(using: .utf8)!

        let sdEntry = SDWorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Treino",
            focusRaw: "lower",
            statusRaw: "completed",
            completedExercisesJSON: invalidJSON
        )

        // When
        let domain = WorkoutHistoryMapper.toDomain(sdEntry)

        // Then
        XCTAssertNotNil(domain)
        XCTAssertNil(domain?.completedExercises)
    }

    // MARK: - toModel Tests

    func test_toModel_withUserRating_mapsCorrectly() {
        // Given
        let domainEntry = WorkoutHistoryEntry(
            planId: UUID(),
            title: "Treino Superior",
            focus: .upper,
            status: .completed,
            userRating: .tooHard
        )

        // When
        let sdModel = WorkoutHistoryMapper.toModel(domainEntry)

        // Then
        XCTAssertEqual(sdModel.userRating, "too_hard")
    }

    func test_toModel_withoutUserRating_storesNil() {
        // Given
        let domainEntry = WorkoutHistoryEntry(
            planId: UUID(),
            title: "Treino",
            focus: .fullBody,
            status: .completed,
            userRating: nil
        )

        // When
        let sdModel = WorkoutHistoryMapper.toModel(domainEntry)

        // Then
        XCTAssertNil(sdModel.userRating)
    }

    func test_toModel_withCompletedExercises_serializesCorrectly() throws {
        // Given
        let exercises = [
            CompletedExercise(exerciseId: "1", exerciseName: "Squat", muscleGroup: "quads"),
            CompletedExercise(exerciseId: "2", exerciseName: "Deadlift", muscleGroup: "hamstrings")
        ]

        let domainEntry = WorkoutHistoryEntry(
            planId: UUID(),
            title: "Treino Inferior",
            focus: .lower,
            status: .completed,
            completedExercises: exercises
        )

        // When
        let sdModel = WorkoutHistoryMapper.toModel(domainEntry)

        // Then
        XCTAssertNotNil(sdModel.completedExercisesJSON)

        let decoded = try JSONDecoder().decode([CompletedExercise].self, from: sdModel.completedExercisesJSON!)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].exerciseName, "Squat")
    }

    func test_roundTrip_preservesAllFields() throws {
        // Given
        let exercises = [
            CompletedExercise(exerciseId: "1", exerciseName: "Bench", muscleGroup: "chest")
        ]

        let original = WorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Treino Completo",
            focus: .fullBody,
            status: .completed,
            programId: "prog123",
            programName: "Hipertrofia",
            durationMinutes: 45,
            caloriesBurned: 320,
            userRating: .adequate,
            completedExercises: exercises
        )

        // When
        let sdModel = WorkoutHistoryMapper.toModel(original)
        let restored = WorkoutHistoryMapper.toDomain(sdModel)

        // Then
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.title, original.title)
        XCTAssertEqual(restored?.focus, original.focus)
        XCTAssertEqual(restored?.status, original.status)
        XCTAssertEqual(restored?.programId, original.programId)
        XCTAssertEqual(restored?.programName, original.programName)
        XCTAssertEqual(restored?.durationMinutes, original.durationMinutes)
        XCTAssertEqual(restored?.caloriesBurned, original.caloriesBurned)
        XCTAssertEqual(restored?.userRating, original.userRating)
        XCTAssertEqual(restored?.completedExercises?.count, original.completedExercises?.count)
    }
}
