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
  var mockRepository: MockWorkoutHistoryRepository!
  
  override func setUp() {
    super.setUp()
    mockRepository = MockWorkoutHistoryRepository()
    viewModel = HistoryViewModel(repository: mockRepository)
  }
  
  override func tearDown() {
    viewModel = nil
    mockRepository = nil
    super.tearDown()
  }
  
  // MARK: - ErrorPresenting Tests
  
  func testErrorPresentingProtocolConformance() {
    XCTAssertTrue(viewModel is ErrorPresenting)
  }
  
  func testErrorMessageInitialState() {
    XCTAssertNil(viewModel.errorMessage)
  }
  
  func testHandleErrorUpdatesErrorMessage() async throws {
    let error = DomainError.repositoryFailure(reason: "Database error")
    
    await viewModel.handleError(error)
    
    try await Task.sleep(nanoseconds: 50_000_000)
    
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertEqual(viewModel.errorMessage?.title, "Erro ao salvar")
  }
  
  func testLoadHistoryShowsErrorOnFailure() async throws {
    mockRepository.shouldThrowError = true
    
    viewModel.loadHistory()
    
    // Aguardar Task completar
    try await Task.sleep(nanoseconds: 100_000_000)
    
    // Verificar que erro foi propagado
    XCTAssertNotNil(viewModel.errorMessage)
  }
  
  func testLoadHistorySucceedsWithValidData() async throws {
    let mockEntry = WorkoutHistoryEntry(
      id: UUID(),
      title: "Test Workout",
      focus: .fullBody,
      date: Date(),
      status: .completed,
      planId: UUID(),
      planSnapshot: nil,
      sessionSnapshot: nil,
      durationMinutes: nil,
      caloriesBurned: nil,
      programId: nil,
      programName: nil
    )
    mockRepository.mockEntries = [mockEntry]
    
    viewModel.loadHistory()
    
    try await Task.sleep(nanoseconds: 100_000_000)
    
    XCTAssertFalse(viewModel.sections.isEmpty)
    XCTAssertNil(viewModel.errorMessage)
  }
  
  func testGroupingByDate() async throws {
    let date1 = Date()
    let date2 = Calendar.current.date(byAdding: .day, value: -1, to: date1)!
    
    let entry1 = WorkoutHistoryEntry(
      id: UUID(),
      title: "Workout 1",
      focus: .fullBody,
      date: date1,
      status: .completed,
      planId: UUID(),
      planSnapshot: nil,
      sessionSnapshot: nil,
      durationMinutes: nil,
      caloriesBurned: nil,
      programId: nil,
      programName: nil
    )
    
    let entry2 = WorkoutHistoryEntry(
      id: UUID(),
      title: "Workout 2",
      focus: .upper,
      date: date2,
      status: .completed,
      planId: UUID(),
      planSnapshot: nil,
      sessionSnapshot: nil,
      durationMinutes: nil,
      caloriesBurned: nil,
      programId: nil,
      programName: nil
    )
    
    mockRepository.mockEntries = [entry1, entry2]
    
    viewModel.loadHistory()
    
    try await Task.sleep(nanoseconds: 100_000_000)
    
    // Deve agrupar em 2 seções (2 dias diferentes)
    XCTAssertEqual(viewModel.sections.count, 2)
  }
}

// MARK: - Mocks

class MockWorkoutHistoryRepository: WorkoutHistoryRepository {
  var mockEntries: [WorkoutHistoryEntry] = []
  var shouldThrowError = false
  
  func listEntries() async throws -> [WorkoutHistoryEntry] {
    if shouldThrowError {
      throw DomainError.repositoryFailure(reason: "Mock error")
    }
    return mockEntries
  }
  
  func save(_ entry: WorkoutHistoryEntry) async throws {
    mockEntries.append(entry)
  }
  
  func load(id: UUID) async throws -> WorkoutHistoryEntry? {
    return mockEntries.first { $0.id == id }
  }
  
  func delete(id: UUID) async throws {
    mockEntries.removeAll { $0.id == id }
  }
}

