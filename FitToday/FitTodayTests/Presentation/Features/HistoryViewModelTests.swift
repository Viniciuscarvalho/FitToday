//
//  HistoryViewModelTests.swift
//  FitTodayTests
//
//  Created by AI on 07/01/26.
//

import XCTest
@testable import FitToday

final class HistoryViewModelTests: XCTestCase {
    
    var viewModel: HistoryViewModel!
    var mockRepository: MockHWorkoutHistoryRepository!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockRepository = MockHWorkoutHistoryRepository()
        viewModel = HistoryViewModel(repository: mockRepository)
    }
    
    @MainActor
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - ErrorPresenting Tests
    
    @MainActor
    func testErrorPresentingProtocolConformance() {
        XCTAssertTrue(viewModel is ErrorPresenting)
    }
    
    @MainActor
    func testErrorMessageInitialState() {
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testHandleErrorUpdatesErrorMessage() async throws {
        let error = DomainError.repositoryFailure(reason: "Database error")
        
        viewModel.handleError(error)
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage?.title, "Erro ao salvar")
    }
    
    @MainActor
    func testLoadHistoryShowsErrorOnFailure() async throws {
        mockRepository.shouldThrowError = true
        
        viewModel.loadHistory()
        
        // Aguardar Task completar
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verificar que erro foi propagado
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testLoadHistorySucceedsWithValidData() async throws {
        let mockEntry = WorkoutHistoryEntry(
            id: UUID(),
            date: Date(),
            planId: UUID(),
            title: "Test Workout",
            focus: .fullBody,
            status: .completed
        )
        mockRepository.mockEntries = [mockEntry]
        
        viewModel.loadHistory()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(viewModel.sections.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testGroupingByDate() async throws {
        let date1 = Date()
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: date1)!
        
        let entry1 = WorkoutHistoryEntry(
            id: UUID(),
            date: date1,
            planId: UUID(),
            title: "Workout 1",
            focus: .fullBody,
            status: .completed
        )
        
        let entry2 = WorkoutHistoryEntry(
            id: UUID(),
            date: date2,
            planId: UUID(),
            title: "Workout 2",
            focus: .upper,
            status: .completed
        )
        
        mockRepository.mockEntries = [entry1, entry2]
        
        viewModel.loadHistory()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Deve agrupar em 2 seções (2 dias diferentes)
        XCTAssertEqual(viewModel.sections.count, 2)
    }
}

// MARK: - Mocks (prefixed to avoid conflicts)

class MockHWorkoutHistoryRepository: WorkoutHistoryRepository {
    var mockEntries: [WorkoutHistoryEntry] = []
    var shouldThrowError = false
    
    func listEntries() async throws -> [WorkoutHistoryEntry] {
        if shouldThrowError {
            throw DomainError.repositoryFailure(reason: "Mock error")
        }
        return mockEntries
    }
    
    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry] {
        if shouldThrowError {
            throw DomainError.repositoryFailure(reason: "Mock error")
        }
        let start = min(offset, mockEntries.count)
        let end = min(offset + limit, mockEntries.count)
        return Array(mockEntries[start..<end])
    }
    
    func count() async throws -> Int {
        if shouldThrowError {
            throw DomainError.repositoryFailure(reason: "Mock error")
        }
        return mockEntries.count
    }
    
    func saveEntry(_ entry: WorkoutHistoryEntry) async throws {
        mockEntries.append(entry)
    }
}

