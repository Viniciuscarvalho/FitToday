//
//  SyncWorkoutWithHealthKitUseCaseTests.swift
//  FitTodayTests
//
//  Created by Claude on 20/01/26.
//

import XCTest
@testable import FitToday

final class SyncWorkoutWithHealthKitUseCaseTests: XCTestCase {

    private var sut: SyncWorkoutWithHealthKitUseCase!
    private var mockHealthKitService: MockHealthKitService!
    private var mockHistoryRepository: MockWorkoutHistoryRepository!

    override func setUp() {
        super.setUp()
        mockHealthKitService = MockHealthKitService()
        mockHistoryRepository = MockWorkoutHistoryRepository()
        sut = SyncWorkoutWithHealthKitUseCase(
            healthKitService: mockHealthKitService,
            historyRepository: mockHistoryRepository,
            calorieImportDelay: .milliseconds(10), // Fast delay for tests
            maxRetries: 2
        )
    }

    override func tearDown() {
        sut = nil
        mockHealthKitService = nil
        mockHistoryRepository = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testExecute_whenNotAuthorized_shouldReturnSkipped() async {
        // Given
        mockHealthKitService.stubbedAuthState = .denied
        let entry = makeHistoryEntry()
        let plan = makeWorkoutPlan()

        // When
        let result = await sut.execute(entry: entry, plan: plan, completedAt: Date())

        // Then
        XCTAssertFalse(result.succeeded)
        XCTAssertNil(result.workoutUUID)
        if case .skipped(let reason) = result.status {
            XCTAssertTrue(reason.contains("negada"))
        } else {
            XCTFail("Expected skipped status")
        }
    }

    func testExecute_whenNotAvailable_shouldReturnSkipped() async {
        // Given
        mockHealthKitService.stubbedAuthState = .notAvailable
        let entry = makeHistoryEntry()
        let plan = makeWorkoutPlan()

        // When
        let result = await sut.execute(entry: entry, plan: plan, completedAt: Date())

        // Then
        XCTAssertFalse(result.succeeded)
        if case .skipped(let reason) = result.status {
            XCTAssertTrue(reason.contains("não disponível"))
        } else {
            XCTFail("Expected skipped status")
        }
    }

    // MARK: - Export Tests

    func testExecute_whenExportSucceeds_shouldReturnWorkoutUUID() async {
        // Given
        mockHealthKitService.stubbedAuthState = .authorized
        let expectedUUID = UUID()
        mockHealthKitService.stubbedExportReceipt = ExportedWorkoutReceipt(
            workoutUUID: expectedUUID,
            exportedAt: Date()
        )
        let entry = makeHistoryEntry()
        let plan = makeWorkoutPlan()

        // When
        let result = await sut.execute(entry: entry, plan: plan, completedAt: Date())

        // Then
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.workoutUUID, expectedUUID)
    }

    func testExecute_whenExportFails_shouldReturnFailed() async {
        // Given
        mockHealthKitService.stubbedAuthState = .authorized
        mockHealthKitService.shouldThrowOnExport = true
        let entry = makeHistoryEntry()
        let plan = makeWorkoutPlan()

        // When
        let result = await sut.execute(entry: entry, plan: plan, completedAt: Date())

        // Then
        XCTAssertFalse(result.succeeded)
        XCTAssertNil(result.workoutUUID)
        if case .failed(let reason) = result.status {
            XCTAssertTrue(reason.contains("Falha ao exportar"))
        } else {
            XCTFail("Expected failed status")
        }
    }

    // MARK: - Calorie Import Tests

    func testExecute_whenCaloriesAvailable_shouldReturnCalories() async {
        // Given
        mockHealthKitService.stubbedAuthState = .authorized
        let workoutUUID = UUID()
        mockHealthKitService.stubbedExportReceipt = ExportedWorkoutReceipt(
            workoutUUID: workoutUUID,
            exportedAt: Date()
        )
        mockHealthKitService.stubbedCalories = 350
        let entry = makeHistoryEntry()
        let plan = makeWorkoutPlan()

        // When
        let result = await sut.execute(entry: entry, plan: plan, completedAt: Date())

        // Then
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.caloriesBurned, 350)
        if case .success = result.status {
            // Expected
        } else {
            XCTFail("Expected success status")
        }
    }

    func testExecute_whenCaloriesNotAvailable_shouldReturnPartialSuccess() async {
        // Given
        mockHealthKitService.stubbedAuthState = .authorized
        let workoutUUID = UUID()
        mockHealthKitService.stubbedExportReceipt = ExportedWorkoutReceipt(
            workoutUUID: workoutUUID,
            exportedAt: Date()
        )
        mockHealthKitService.stubbedCalories = nil // No calories available
        let entry = makeHistoryEntry()
        let plan = makeWorkoutPlan()

        // When
        let result = await sut.execute(entry: entry, plan: plan, completedAt: Date())

        // Then
        XCTAssertTrue(result.succeeded) // Still considered success
        XCTAssertNil(result.caloriesBurned)
        if case .partialSuccess(let reason) = result.status {
            XCTAssertTrue(reason.contains("Calorias não disponíveis"))
        } else {
            XCTFail("Expected partialSuccess status")
        }
    }

    // MARK: - History Update Tests

    func testExecute_shouldUpdateHistoryEntry() async {
        // Given
        mockHealthKitService.stubbedAuthState = .authorized
        let workoutUUID = UUID()
        mockHealthKitService.stubbedExportReceipt = ExportedWorkoutReceipt(
            workoutUUID: workoutUUID,
            exportedAt: Date()
        )
        mockHealthKitService.stubbedCalories = 400
        let entry = makeHistoryEntry()
        let plan = makeWorkoutPlan()

        // When
        _ = await sut.execute(entry: entry, plan: plan, completedAt: Date())

        // Then
        XCTAssertEqual(mockHistoryRepository.savedEntries.count, 1)
        let savedEntry = mockHistoryRepository.savedEntries.first!
        XCTAssertEqual(savedEntry.healthKitWorkoutUUID, workoutUUID)
        XCTAssertEqual(savedEntry.caloriesBurned, 400)
    }

    // MARK: - Helpers

    private func makeHistoryEntry() -> WorkoutHistoryEntry {
        WorkoutHistoryEntry(
            planId: UUID(),
            title: "Test Workout",
            focus: .fullBody,
            status: .completed
        )
    }

    private func makeWorkoutPlan() -> WorkoutPlan {
        WorkoutPlan(
            title: "Test Plan",
            focus: .fullBody,
            estimatedDurationMinutes: 45,
            intensity: .moderate,
            phases: []
        )
    }
}

// MARK: - Mock HealthKit Service

private final class MockHealthKitService: HealthKitServicing, @unchecked Sendable {
    var stubbedAuthState: HealthKitAuthorizationState = .authorized
    var stubbedExportReceipt: ExportedWorkoutReceipt?
    var stubbedCalories: Int?
    var shouldThrowOnExport = false

    func authorizationState() async -> HealthKitAuthorizationState {
        stubbedAuthState
    }

    func requestAuthorization() async throws {
        // No-op for tests
    }

    func fetchWorkouts(in range: DateInterval) async throws -> [ImportedSessionMetric] {
        guard let receipt = stubbedExportReceipt else { return [] }
        return [
            ImportedSessionMetric(
                workoutUUID: receipt.workoutUUID,
                startDate: Date(),
                endDate: Date(),
                durationMinutes: 45,
                caloriesBurned: stubbedCalories
            )
        ]
    }

    func exportWorkout(plan: WorkoutPlan, completedAt: Date) async throws -> ExportedWorkoutReceipt {
        if shouldThrowOnExport {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Export failed"])
        }
        guard let receipt = stubbedExportReceipt else {
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "No receipt configured"])
        }
        return receipt
    }

    func fetchCaloriesForWorkout(workoutUUID: UUID, around date: Date) async throws -> Int? {
        stubbedCalories
    }
}

// MARK: - Mock Workout History Repository

private final class MockWorkoutHistoryRepository: WorkoutHistoryRepository, @unchecked Sendable {
    var savedEntries: [WorkoutHistoryEntry] = []

    func listEntries() async throws -> [WorkoutHistoryEntry] {
        savedEntries
    }

    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        Array(savedEntries.prefix(limit))
    }

    func count() async throws -> Int {
        savedEntries.count
    }

    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        if let index = savedEntries.firstIndex(where: { $0.id == entry.id }) {
            savedEntries[index] = entry
        } else {
            savedEntries.append(entry)
        }
    }

    func listAppEntriesWithPlan(limit: Int) async throws -> [WorkoutHistoryEntry] {
        let filtered = savedEntries.filter { $0.source == .app && $0.workoutPlan != nil }
        return Array(filtered.prefix(limit))
    }
}
