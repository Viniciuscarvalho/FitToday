//
//  HistoryUseCasesTests.swift
//  FitTodayTests
//
//  Created by AI on 15/01/26.
//

import XCTest
@testable import FitToday

// 💡 Learn: Testes para os UseCases de histórico de treinos
// Validam listagem e ordenação do histórico
final class HistoryUseCasesTests: XCTestCase {

    func testListWorkoutHistory_returnsEntriesSortedByDateDescending() async throws {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        let entries = [
            WorkoutHistoryEntry(
                date: yesterday,
                planId: UUID(),
                title: "Yesterday Workout",
                focus: .upper,
                status: .completed,
                durationMinutes: 30
            ),
            WorkoutHistoryEntry(
                date: today,
                planId: UUID(),
                title: "Today Workout",
                focus: .lower,
                status: .completed,
                durationMinutes: 45
            ),
            WorkoutHistoryEntry(
                date: twoDaysAgo,
                planId: UUID(),
                title: "Old Workout",
                focus: .fullBody,
                status: .completed,
                durationMinutes: 40
            )
        ]

        let mockRepo = MockWorkoutHistoryRepository(entries: entries)
        let sut = ListWorkoutHistoryUseCase(repository: mockRepo)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].title, "Today Workout") // Most recent first
        XCTAssertEqual(result[1].title, "Yesterday Workout")
        XCTAssertEqual(result[2].title, "Old Workout") // Oldest last
        XCTAssertTrue(mockRepo.listEntriesCalled)
    }

    func testListWorkoutHistory_whenEmpty_returnsEmptyArray() async throws {
        // Given
        let mockRepo = MockWorkoutHistoryRepository(entries: [])
        let sut = ListWorkoutHistoryUseCase(repository: mockRepo)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockRepo.listEntriesCalled)
    }

    func testListWorkoutHistory_withSingleEntry_returnsOneEntry() async throws {
        // Given
        let entry = WorkoutHistoryEntry(
            date: Date(),
            planId: UUID(),
            title: "Single Workout",
            focus: .upper,
            status: .completed,
            durationMinutes: 30
        )

        let mockRepo = MockWorkoutHistoryRepository(entries: [entry])
        let sut = ListWorkoutHistoryUseCase(repository: mockRepo)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "Single Workout")
    }
}

// MARK: - Mock Repository

private final class MockWorkoutHistoryRepository: WorkoutHistoryRepository, @unchecked Sendable {
    var entries: [WorkoutHistoryEntry]
    var listEntriesCalled = false

    init(entries: [WorkoutHistoryEntry]) {
        self.entries = entries
    }

    func listEntries() async throws -> [WorkoutHistoryEntry] {
        listEntriesCalled = true
        return entries
    }

    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        let startIndex = min(offset, entries.count)
        let endIndex = min(startIndex + limit, entries.count)
        return Array(entries[startIndex..<endIndex])
    }

    func count() async throws -> Int {
        return entries.count
    }

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {}
}
