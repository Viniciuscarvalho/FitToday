//
//  HomeViewModelTests.swift
//  FitTodayTests
//
//  Created by AI on 07/01/26.
//

import XCTest
import Swinject
@testable import FitToday

final class HomeViewModelTests: XCTestCase {
    
    var mockResolver: Container!
    
    override func setUp() {
        super.setUp()
        mockResolver = Container()
        // Register minimal mocks
        mockResolver.register(UserProfileRepository.self) { _ in MockProfileRepo() }
        mockResolver.register(EntitlementRepository.self) { _ in MockEntitlementRepo() }
    }
    
    override func tearDown() {
        mockResolver = nil
        super.tearDown()
    }
  
  // MARK: - ErrorPresenting Tests
  
    @MainActor
    func testErrorPresentingProtocolConformance() {
        let viewModel = HomeViewModel(resolver: mockResolver)
        
        // Verificar que ViewModel conforma a ErrorPresenting
        XCTAssertTrue(viewModel is ErrorPresenting)
    }
  
    @MainActor
    func testErrorMessageInitialState() {
        let viewModel = HomeViewModel(resolver: mockResolver)
        
        // Estado inicial deve ser nil
        XCTAssertNil(viewModel.errorMessage)
    }
  
    @MainActor
    func testHandleErrorUpdatesErrorMessage() async throws {
        let viewModel = HomeViewModel(resolver: mockResolver)
        
        let error = DomainError.profileNotFound
        
        // Executar handleError
        viewModel.handleError(error)
        
        // Aguardar propagação no MainActor
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
        
        // Verificar que errorMessage foi atualizado
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage?.title, "Perfil não encontrado")
    }
  
    @MainActor
    func testErrorMessageIsMappedCorrectly() async throws {
        let viewModel = HomeViewModel(resolver: mockResolver)
        
        let networkError = URLError(.notConnectedToInternet)
        
        viewModel.handleError(networkError)
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage?.title, "Sem conexão")
        XCTAssertEqual(viewModel.errorMessage?.action, .openSettings)
    }
  
    @MainActor
    func testMultipleErrorsUpdateErrorMessage() async throws {
        let viewModel = HomeViewModel(resolver: mockResolver)
        
        // Primeiro erro
        viewModel.handleError(DomainError.profileNotFound)
        try await Task.sleep(nanoseconds: 50_000_000)
        
        let firstErrorTitle = viewModel.errorMessage?.title
        XCTAssertNotNil(firstErrorTitle)
        
        // Segundo erro
        viewModel.handleError(DomainError.networkFailure)
        try await Task.sleep(nanoseconds: 50_000_000)
        
        let secondErrorTitle = viewModel.errorMessage?.title
        XCTAssertNotNil(secondErrorTitle)
        XCTAssertNotEqual(firstErrorTitle, secondErrorTitle)
    }
}

// MARK: - Mocks

private final class MockProfileRepo: UserProfileRepository {
    func loadProfile() async throws -> UserProfile? { nil }
    func saveProfile(_ profile: UserProfile) async throws {}
}

private final class MockEntitlementRepo: EntitlementRepository {
    func currentEntitlement() async throws -> ProEntitlement { .free }
    func entitlementStream() -> AsyncStream<ProEntitlement> {
        AsyncStream { $0.finish() }
    }
}

