//
//  HealthKitHistorySyncServiceTests.swift
//  FitTodayTests
//
//  Created by AI on 12/01/26.
//

import XCTest
@testable import FitToday

final class HealthKitHistorySyncServiceTests: XCTestCase {
    func testSyncUpdatesHistoryEntryWhenWorkoutMatchesSameDayAndCloseTime() async throws {
        let now = Date()
        let planId = UUID()
        
        var entry = WorkoutHistoryEntry(
            date: now,
            planId: planId,
            title: "Treino",
            focus: .upper,
            status: .completed,
            durationMinutes: nil,
            caloriesBurned: nil,
            workoutPlan: nil
        )
        
        let workout = ImportedSessionMetric(
            workoutUUID: UUID(),
            startDate: now.addingTimeInterval(-1800),
            endDate: now.addingTimeInterval(-60),
            durationMinutes: 30,
            caloriesBurned: 200
        )
        
        let hk = MockHealthKit(workouts: [workout])
        let repo = InMemoryHistoryRepo(entries: [entry])
        let sut = HealthKitHistorySyncService(healthKit: hk, historyRepository: repo)
        
        let updated = try await sut.syncLastDays(1)
        XCTAssertEqual(updated, 1)
        
        let stored = try await repo.listEntries()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored[0].durationMinutes, 30)
        XCTAssertEqual(stored[0].caloriesBurned, 200)
        XCTAssertEqual(stored[0].healthKitWorkoutUUID, workout.workoutUUID)
    }
}

private actor MockHealthKit: HealthKitServicing {
    private let workouts: [ImportedSessionMetric]
    
    init(workouts: [ImportedSessionMetric]) {
        self.workouts = workouts
    }
    
    func authorizationState() async -> HealthKitAuthorizationState { .authorized }
    func requestAuthorization() async throws {}
    
    func fetchWorkouts(in range: DateInterval) async throws -> [ImportedSessionMetric] {
        workouts
    }
    
    func exportWorkout(plan: WorkoutPlan, completedAt: Date) async throws -> ExportedWorkoutReceipt {
        .init(workoutUUID: UUID(), exportedAt: Date())
    }

    func fetchCaloriesForWorkout(workoutUUID: UUID, around date: Date) async throws -> Int? {
        nil
    }
}

private actor InMemoryHistoryRepo: WorkoutHistoryRepository {
    private var entries: [WorkoutHistoryEntry]
    
    init(entries: [WorkoutHistoryEntry]) {
        self.entries = entries
    }
    
    func listEntries() async throws -> [WorkoutHistoryEntry] {
        entries.sorted { $0.date > $1.date }
    }
    
    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        let sorted = entries.sorted { $0.date > $1.date }
        guard offset < sorted.count else { return [] }
        let slice = sorted.dropFirst(offset).prefix(limit)
        return Array(slice)
    }
    
    func count() async throws -> Int {
        entries.count
    }
    
    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        } else {
            entries.append(entry)
        }
    }
}

