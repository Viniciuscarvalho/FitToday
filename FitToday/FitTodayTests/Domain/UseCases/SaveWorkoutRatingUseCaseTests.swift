//
//  SaveWorkoutRatingUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 18/01/26.
//

import XCTest
@testable import FitToday

final class SaveWorkoutRatingUseCaseTests: XCTestCase {

    private var sut: SaveWorkoutRatingUseCase!
    private var mockRepository: MockWorkoutHistoryRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockWorkoutHistoryRepository()
        sut = SaveWorkoutRatingUseCase(historyRepository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Execute Tests

    func test_execute_withMatchingPlanId_savesRating() async throws {
        // Given
        let planId = UUID()
        let entry = WorkoutHistoryEntry(
            planId: planId,
            title: "Test Workout",
            focus: .fullBody,
            status: .completed
        )
        mockRepository.entries = [entry]

        // When
        try await sut.execute(rating: .adequate, planId: planId)

        // Then
        XCTAssertEqual(mockRepository.savedEntries.count, 1)
        XCTAssertEqual(mockRepository.savedEntries.first?.userRating, .adequate)
    }

    func test_execute_withNoMatchingPlanId_throwsNotFound() async {
        // Given
        let planId = UUID()
        let differentPlanId = UUID()
        let entry = WorkoutHistoryEntry(
            planId: planId,
            title: "Test Workout",
            focus: .upper,
            status: .completed
        )
        mockRepository.entries = [entry]

        // When/Then
        do {
            try await sut.execute(rating: .tooHard, planId: differentPlanId)
            XCTFail("Expected error to be thrown")
        } catch let error as DomainError {
            if case .notFound = error {
                // Expected
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        } catch {
            XCTFail("Expected DomainError, got: \(error)")
        }
    }

    func test_execute_withNilRating_clearsRating() async throws {
        // Given
        let planId = UUID()
        var entry = WorkoutHistoryEntry(
            planId: planId,
            title: "Test Workout",
            focus: .lower,
            status: .completed,
            userRating: .tooEasy
        )
        mockRepository.entries = [entry]

        // When
        try await sut.execute(rating: nil, planId: planId)

        // Then
        XCTAssertEqual(mockRepository.savedEntries.count, 1)
        XCTAssertNil(mockRepository.savedEntries.first?.userRating)
    }

    func test_execute_withCompletedExercises_savesExercises() async throws {
        // Given
        let planId = UUID()
        let entry = WorkoutHistoryEntry(
            planId: planId,
            title: "Test Workout",
            focus: .fullBody,
            status: .completed
        )
        mockRepository.entries = [entry]

        let exercises = [
            CompletedExercise(exerciseId: "1", exerciseName: "Squat", muscleGroup: "quads"),
            CompletedExercise(exerciseId: "2", exerciseName: "Bench", muscleGroup: "chest")
        ]

        // When
        try await sut.execute(rating: .adequate, completedExercises: exercises, planId: planId)

        // Then
        XCTAssertEqual(mockRepository.savedEntries.count, 1)
        XCTAssertEqual(mockRepository.savedEntries.first?.completedExercises?.count, 2)
    }

    func test_execute_findsEntryInLargeList() async throws {
        // Given
        let targetPlanId = UUID()
        var entries: [WorkoutHistoryEntry] = []

        // Create 15 entries, target is at index 10
        for i in 0..<15 {
            let planId = i == 10 ? targetPlanId : UUID()
            entries.append(WorkoutHistoryEntry(
                planId: planId,
                title: "Workout \(i)",
                focus: .fullBody,
                status: .completed
            ))
        }
        mockRepository.entries = entries

        // When
        try await sut.execute(rating: .tooHard, planId: targetPlanId)

        // Then
        XCTAssertEqual(mockRepository.savedEntries.count, 1)
        XCTAssertEqual(mockRepository.savedEntries.first?.title, "Workout 10")
        XCTAssertEqual(mockRepository.savedEntries.first?.userRating, .tooHard)
    }
}

// MARK: - Mock Repository

fileprivate class MockWorkoutHistoryRepository: WorkoutHistoryRepository {
    var entries: [WorkoutHistoryEntry] = []
    var savedEntries: [WorkoutHistoryEntry] = []

    func listEntries() async throws -> [WorkoutHistoryEntry] {
        return entries
    }

    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        let start = min(offset, entries.count)
        let end = min(offset + limit, entries.count)
        return Array(entries[start..<end])
    }

    func count() async throws -> Int {
        return entries.count
    }

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        savedEntries.append(entry)
        // Update in-place for subsequent reads
        if let idx = entries.firstIndex(where: { $0.planId == entry.planId }) {
            entries[idx] = entry
        }
    }
}
