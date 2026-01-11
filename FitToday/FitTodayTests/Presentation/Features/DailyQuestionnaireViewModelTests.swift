//
//  DailyQuestionnaireViewModelTests.swift
//  FitTodayTests
//
//  Created by AI on 07/01/26.
//

import XCTest
import Swinject
@testable import FitToday

final class DailyQuestionnaireViewModelTests: XCTestCase {
    
    var viewModel: DailyQuestionnaireViewModel!
    var mockEntitlementRepo: MockQEntitlementRepository!
    var mockProfileRepo: MockQUserProfileRepository!
    var mockBlocksRepo: MockQWorkoutBlocksRepository!
    var mockComposer: MockQWorkoutPlanComposer!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockEntitlementRepo = MockQEntitlementRepository()
        mockProfileRepo = MockQUserProfileRepository()
        mockBlocksRepo = MockQWorkoutBlocksRepository()
        mockComposer = MockQWorkoutPlanComposer()
        
        viewModel = DailyQuestionnaireViewModel(
            entitlementRepository: mockEntitlementRepo,
            profileRepository: mockProfileRepo,
            blocksRepository: mockBlocksRepo,
            composer: mockComposer
        )
    }
    
    @MainActor
    override func tearDown() {
        viewModel = nil
        mockEntitlementRepo = nil
        mockProfileRepo = nil
        mockBlocksRepo = nil
        mockComposer = nil
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
        let error = DomainError.invalidInput(reason: "Teste")
        
        viewModel.handleError(error)
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage?.title, "Dados inválidos")
    }
    
    @MainActor
    func testErrorFromRepositoryFailureShowsToast() async throws {
        mockEntitlementRepo.shouldThrowError = true
        
        // Start carrega entitlement
        await viewModel.start()
        
        // Aguardar processamento
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verificar que erro foi propagado
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Business Logic Tests
    
    @MainActor
    func testBuildCheckInThrowsErrorWhenNoFocus() {
        XCTAssertThrowsError(try viewModel.buildCheckIn()) { error in
            if let domainError = error as? DomainError,
               case .invalidInput(let reason) = domainError {
                XCTAssertTrue(reason.contains("foco"))
            } else {
                XCTFail("Expected DomainError.invalidInput")
            }
        }
    }
    
    @MainActor
    func testBuildCheckInThrowsErrorWhenNoSoreness() {
        viewModel.selectFocus(.fullBody)
        
        XCTAssertThrowsError(try viewModel.buildCheckIn()) { error in
            if let domainError = error as? DomainError,
               case .invalidInput(let reason) = domainError {
                XCTAssertTrue(reason.contains("dor"))
            } else {
                XCTFail("Expected DomainError.invalidInput")
            }
        }
    }
    
    @MainActor
    func testBuildCheckInSucceedsWithValidData() throws {
        viewModel.selectFocus(.fullBody)
        viewModel.selectSoreness(.none)
        
        let checkIn = try viewModel.buildCheckIn()
        
        XCTAssertEqual(checkIn.focus, .fullBody)
        XCTAssertEqual(checkIn.sorenessLevel, .none)
    }
}

// MARK: - Mocks (prefixed to avoid conflicts)

class MockQEntitlementRepository: EntitlementRepository {
    var shouldThrowError = false
    var mockEntitlement: ProEntitlement = .free
    
    func currentEntitlement() async throws -> ProEntitlement {
        if shouldThrowError {
            throw URLError(.badServerResponse)
        }
        return mockEntitlement
    }
    
    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { continuation in
            continuation.yield(mockEntitlement)
            continuation.finish()
        }
    }
}

class MockQUserProfileRepository: UserProfileRepository {
    var mockProfile: UserProfile?
    var shouldThrowError = false
    
    func loadProfile() async throws -> UserProfile? {
        if shouldThrowError {
            throw DomainError.repositoryFailure(reason: "Mock error")
        }
        return mockProfile
    }
    
    func saveProfile(_ profile: UserProfile) async throws {
        mockProfile = profile
    }
}

class MockQWorkoutBlocksRepository: WorkoutBlocksRepository {
    var mockBlocks: [WorkoutBlock] = []
    
    func loadBlocks() async throws -> [WorkoutBlock] {
        return mockBlocks
    }
}

class MockQWorkoutPlanComposer: WorkoutPlanComposing {
    var mockPlan: WorkoutPlan?
    
    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        if let plan = mockPlan {
            return plan
        }
        throw DomainError.noCompatibleBlocks
    }
}

