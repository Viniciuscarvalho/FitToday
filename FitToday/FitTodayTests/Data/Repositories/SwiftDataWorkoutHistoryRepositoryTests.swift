//
//  SwiftDataWorkoutHistoryRepositoryTests.swift
//  FitTodayTests
//
//  Created by AI on 15/01/26.
//

import XCTest
import SwiftData
@testable import FitToday

// 💡 Learn: Testes para o repositório SwiftData de histórico de treinos
// Valida paginação, ordenação e persistência
@MainActor
final class SwiftDataWorkoutHistoryRepositoryTests: XCTestCase {

    var container: ModelContainer!
    var sut: SwiftDataWorkoutHistoryRepository!

    override func setUp() async throws {
        let schema = Schema([SDWorkoutHistoryEntry.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        sut = SwiftDataWorkoutHistoryRepository(modelContainer: container)
    }

    override func tearDown() async throws {
        container = nil
        sut = nil
    }

    // MARK: - List Entries Tests

    func testListEntries_whenEmpty_returnsEmptyArray() async throws {
        // When
        let result = try await sut.listEntries()

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testListEntries_returnsSortedByDateDescending() async throws {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        let entry1 = createEntry(title: "Yesterday", date: yesterday)
        let entry2 = createEntry(title: "Today", date: today)
        let entry3 = createEntry(title: "Two Days Ago", date: twoDaysAgo)

        try await sut.saveEntry(entry1)
        try await sut.saveEntry(entry2)
        try await sut.saveEntry(entry3)

        // When
        let result = try await sut.listEntries()

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].title, "Today") // Most recent first
        XCTAssertEqual(result[1].title, "Yesterday")
        XCTAssertEqual(result[2].title, "Two Days Ago") // Oldest last
    }

    // MARK: - Pagination Tests

    func testListEntries_withLimitAndOffset_returnsPaginatedResults() async throws {
        // Given - Create 5 entries
        for i in 0..<5 {
            let date = Date().addingTimeInterval(Double(-i * 3600)) // Each 1 hour apart
            let entry = createEntry(title: "Entry \(i)", date: date)
            try await sut.saveEntry(entry)
        }

        // When - Get page 2 with limit 2
        let result = try await sut.listEntries(limit: 2, offset: 2)

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].title, "Entry 2")
        XCTAssertEqual(result[1].title, "Entry 3")
    }

    func testListEntries_withLimitGreaterThanTotal_returnsAllRemaining() async throws {
        // Given
        for i in 0..<3 {
            let entry = createEntry(title: "Entry \(i)")
            try await sut.saveEntry(entry)
        }

        // When
        let result = try await sut.listEntries(limit: 10, offset: 0)

        // Then
        XCTAssertEqual(result.count, 3)
    }

    // MARK: - Count Tests

    func testCount_whenEmpty_returnsZero() async throws {
        // When
        let count = try await sut.count()

        // Then
        XCTAssertEqual(count, 0)
    }

    func testCount_returnsCorrectTotal() async throws {
        // Given
        for i in 0..<5 {
            let entry = createEntry(title: "Entry \(i)")
            try await sut.saveEntry(entry)
        }

        // When
        let count = try await sut.count()

        // Then
        XCTAssertEqual(count, 5)
    }

    // MARK: - Save Entry Tests

    func testSaveEntry_insertsNewEntry() async throws {
        // Given
        let entry = createEntry(title: "New Workout")

        // When
        try await sut.saveEntry(entry)

        // Then
        let entries = try await sut.listEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].id, entry.id)
        XCTAssertEqual(entries[0].title, "New Workout")
    }

    func testSaveEntry_updatesExistingEntry() async throws {
        // Given
        var entry = createEntry(title: "Original Title")
        try await sut.saveEntry(entry)

        // When - Update the same entry
        entry.title = "Updated Title"
        entry.durationMinutes = 60
        try await sut.saveEntry(entry)

        // Then
        let entries = try await sut.listEntries()
        XCTAssertEqual(entries.count, 1) // Should still have only 1 entry
        XCTAssertEqual(entries[0].title, "Updated Title")
        XCTAssertEqual(entries[0].durationMinutes, 60)
    }

    func testSaveEntry_persistsAllFields() async throws {
        // Given
        let plan = createMockPlan()
        let entry = WorkoutHistoryEntry(
            date: Date(),
            planId: UUID(),
            title: "Complete Workout",
            focus: .upper,
            status: .completed,
            programId: "program-123",
            programName: "Hypertrophy Program",
            durationMinutes: 45,
            caloriesBurned: 350,
            healthKitWorkoutUUID: UUID(),
            workoutPlan: plan
        )

        // When
        try await sut.saveEntry(entry)

        // Then
        let loaded = try await sut.listEntries()
        XCTAssertEqual(loaded.count, 1)
        let savedEntry = loaded[0]
        XCTAssertEqual(savedEntry.title, "Complete Workout")
        XCTAssertEqual(savedEntry.focus, .upper)
        XCTAssertEqual(savedEntry.status, .completed)
        XCTAssertEqual(savedEntry.programId, "program-123")
        XCTAssertEqual(savedEntry.programName, "Hypertrophy Program")
        XCTAssertEqual(savedEntry.durationMinutes, 45)
        XCTAssertEqual(savedEntry.caloriesBurned, 350)
        XCTAssertNotNil(savedEntry.healthKitWorkoutUUID)
        XCTAssertNotNil(savedEntry.workoutPlan)
        XCTAssertEqual(savedEntry.workoutPlan?.id, plan.id)
    }

    // MARK: - Helper Methods

    private func createEntry(title: String, date: Date = Date()) -> WorkoutHistoryEntry {
        WorkoutHistoryEntry(
            date: date,
            planId: UUID(),
            title: title,
            focus: .fullBody,
            status: .completed,
            durationMinutes: 30
        )
    }

    private func createMockPlan() -> WorkoutPlan {
        WorkoutPlan(
            id: UUID(),
            title: "Test Plan",
            focus: .fullBody,
            estimatedDurationMinutes: 45,
            intensity: .moderate,
            phases: []
        )
    }
}
