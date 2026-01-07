//
//  HomeViewModelTests.swift
//  FitTodayTests
//
//  Created by AI on 07/01/26.
//

import XCTest
@testable import FitToday

final class HomeViewModelTests: XCTestCase {
  
  // MARK: - ErrorPresenting Tests
  
  func testErrorPresentingProtocolConformance() {
    let container = AppContainer.build()
    let viewModel = HomeViewModel(resolver: container.container)
    
    // Verificar que ViewModel conforma a ErrorPresenting
    XCTAssertTrue(viewModel is ErrorPresenting)
  }
  
  func testErrorMessageInitialState() {
    let container = AppContainer.build()
    let viewModel = HomeViewModel(resolver: container.container)
    
    // Estado inicial deve ser nil
    XCTAssertNil(viewModel.errorMessage)
  }
  
  func testHandleErrorUpdatesErrorMessage() async throws {
    let container = AppContainer.build()
    let viewModel = HomeViewModel(resolver: container.container)
    
    let error = DomainError.profileNotFound
    
    // Executar handleError
    viewModel.handleError(error)
    
    // Aguardar propagação no MainActor
    try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
    
    // Verificar que errorMessage foi atualizado
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertEqual(viewModel.errorMessage?.title, "Perfil não encontrado")
  }
  
  func testErrorMessageIsMappedCorrectly() async throws {
    let container = AppContainer.build()
    let viewModel = HomeViewModel(resolver: container.container)
    
    let networkError = URLError(.notConnectedToInternet)
    
    viewModel.handleError(networkError)
    
    try await Task.sleep(nanoseconds: 50_000_000)
    
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertEqual(viewModel.errorMessage?.title, "Sem conexão")
    XCTAssertEqual(viewModel.errorMessage?.action, .openSettings)
  }
  
  func testMultipleErrorsUpdateErrorMessage() async throws {
    let container = AppContainer.build()
    let viewModel = HomeViewModel(resolver: container.container)
    
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

