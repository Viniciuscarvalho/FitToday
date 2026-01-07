//
//  ErrorPresentingTests.swift
//  FitTodayTests
//
//  Created by AI on 07/01/26.
//

import XCTest
import Foundation
import Combine
@testable import FitToday

final class ErrorPresentingTests: XCTestCase {
  
  // MARK: - ErrorMessage Tests
  
  func testErrorMessageIdentity() {
    let message1 = ErrorMessage(title: "Test", message: "Test message", action: .dismiss)
    let message2 = ErrorMessage(title: "Test", message: "Test message", action: .dismiss)
    
    // IDs devem ser diferentes
    XCTAssertNotEqual(message1.id, message2.id)
    
    // Equatable compara por ID
    XCTAssertNotEqual(message1, message2)
    XCTAssertEqual(message1, message1)
  }
  
  func testErrorMessageOptionalAction() {
    let messageWithAction = ErrorMessage(title: "Test", message: "Test", action: .dismiss)
    let messageWithoutAction = ErrorMessage(title: "Test", message: "Test")
    
    XCTAssertNotNil(messageWithAction.action)
    XCTAssertNil(messageWithoutAction.action)
  }
  
  // MARK: - ErrorAction Tests
  
  func testErrorActionLabels() {
    let retry = ErrorAction.retry({})
    let openSettings = ErrorAction.openSettings
    let dismiss = ErrorAction.dismiss
    
    XCTAssertEqual(retry.label, "Tentar Novamente")
    XCTAssertEqual(openSettings.label, "Abrir Configurações")
    XCTAssertEqual(dismiss.label, "OK")
  }
  
  func testErrorActionSystemImages() {
    let retry = ErrorAction.retry({})
    let openSettings = ErrorAction.openSettings
    let dismiss = ErrorAction.dismiss
    
    XCTAssertEqual(retry.systemImage, "arrow.clockwise")
    XCTAssertEqual(openSettings.systemImage, "gearshape")
    XCTAssertEqual(dismiss.systemImage, "xmark")
  }
  
  func testErrorActionEquality() {
    XCTAssertEqual(ErrorAction.retry({}), ErrorAction.retry({}))
    XCTAssertEqual(ErrorAction.openSettings, ErrorAction.openSettings)
    XCTAssertEqual(ErrorAction.dismiss, ErrorAction.dismiss)
    
    XCTAssertNotEqual(ErrorAction.retry({}), ErrorAction.dismiss)
    XCTAssertNotEqual(ErrorAction.openSettings, ErrorAction.dismiss)
  }
  
  func testErrorActionRetryExecution() async {
    let expectation = XCTestExpectation(description: "Retry closure executed")
    
    let action = ErrorAction.retry {
      expectation.fulfill()
    }
    
    action.execute()
    
    await fulfillment(of: [expectation], timeout: 1.0)
  }
  
  func testErrorActionDismissExecution() {
    let action = ErrorAction.dismiss
    action.execute() // Não deve fazer nada, mas não deve crashar
    XCTAssertTrue(true)
  }
  
  // MARK: - ErrorMapper URLError Tests
  
  func testURLErrorNoInternet() {
    let error = URLError(.notConnectedToInternet)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Sem conexão")
    XCTAssertTrue(message.message.contains("internet"))
    XCTAssertEqual(message.action, .openSettings)
  }
  
  func testURLErrorTimeout() {
    let error = URLError(.timedOut)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Tempo esgotado")
    XCTAssertTrue(message.message.contains("demorou"))
    XCTAssertNotNil(message.action)
  }
  
  func testURLErrorCannotFindHost() {
    let error = URLError(.cannotFindHost)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Servidor indisponível")
    XCTAssertTrue(message.message.contains("servidor"))
  }
  
  func testURLErrorNetworkLost() {
    let error = URLError(.networkConnectionLost)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Sem conexão")
    XCTAssertEqual(message.action, .openSettings)
  }
  
  func testURLErrorBadURL() {
    let error = URLError(.badURL)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "URL inválida")
  }
  
  func testURLErrorDataNotAllowed() {
    let error = URLError(.dataNotAllowed)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Dados móveis desabilitados")
    XCTAssertEqual(message.action, .openSettings)
  }
  
  func testURLErrorGeneric() {
    let error = URLError(.unknown)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Erro de conexão")
  }
  
  // MARK: - ErrorMapper DomainError Tests
  
  func testDomainErrorProfileNotFound() {
    let error = DomainError.profileNotFound
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Perfil não encontrado")
    XCTAssertTrue(message.message.contains("perfil"))
  }
  
  func testDomainErrorInvalidInput() {
    let error = DomainError.invalidInput(reason: "Idade inválida")
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Dados inválidos")
    XCTAssertEqual(message.message, "Idade inválida")
  }
  
  func testDomainErrorNoCompatibleBlocks() {
    let error = DomainError.noCompatibleBlocks
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Nenhum treino compatível")
    XCTAssertTrue(message.message.contains("exercícios"))
  }
  
  func testDomainErrorRepositoryFailure() {
    let error = DomainError.repositoryFailure(reason: "Falha ao escrever")
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Erro ao salvar")
    XCTAssertTrue(message.message.contains("Falha ao escrever"))
  }
  
  func testDomainErrorNetworkFailure() {
    let error = DomainError.networkFailure
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Sem conexão")
    XCTAssertEqual(message.action, .openSettings)
  }
  
  func testDomainErrorSubscriptionExpired() {
    let error = DomainError.subscriptionExpired
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Assinatura expirada")
    XCTAssertTrue(message.message.contains("assinatura"))
  }
  
  // MARK: - ErrorMapper OpenAIClientError Tests
  
  func testOpenAIErrorConfigurationMissing() {
    let error = OpenAIClientError.configurationMissing
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "IA não configurada")
    XCTAssertTrue(message.message.contains("treino local"))
  }
  
  func testOpenAIErrorInvalidResponse() {
    let error = OpenAIClientError.invalidResponse
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "IA temporariamente indisponível")
    XCTAssertTrue(message.message.contains("treino local"))
  }
  
  func testOpenAIErrorRateLimit() {
    let error = OpenAIClientError.httpError(429, "Rate limit exceeded")
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Limite atingido")
    XCTAssertTrue(message.message.contains("limite"))
  }
  
  func testOpenAIErrorServerError() {
    let error = OpenAIClientError.httpError(500, "Internal server error")
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Servidor temporariamente indisponível")
  }
  
  func testOpenAIErrorGenericHTTP() {
    let error = OpenAIClientError.httpError(400, "Bad request")
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "IA temporariamente indisponível")
  }
  
  // MARK: - ErrorMapper ImageCacheError Tests
  
  func testImageCacheErrorInvalidResponse() {
    let error = ImageCacheError.invalidResponse(statusCode: 404)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Erro ao carregar imagem")
    XCTAssertTrue(message.message.contains("404"))
  }
  
  func testImageCacheErrorDiskWriteFailed() {
    let nsError = NSError(domain: "test", code: 1)
    let error = ImageCacheError.diskWriteFailed(underlying: nsError)
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Erro ao salvar")
  }
  
  func testImageCacheErrorSizeExceeded() {
    let error = ImageCacheError.cacheSizeExceeded
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Cache cheio")
    XCTAssertTrue(message.message.contains("cache"))
  }
  
  func testImageCacheErrorInvalidImageData() {
    let error = ImageCacheError.invalidImageData
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Imagem inválida")
  }
  
  // MARK: - ErrorMapper Unknown Error Tests
  
  func testUnknownError() {
    struct CustomError: Error {}
    let error = CustomError()
    let message = ErrorMapper.userFriendlyMessage(for: error)
    
    XCTAssertEqual(message.title, "Ops!")
    XCTAssertTrue(message.message.contains("inesperado"))
    XCTAssertEqual(message.action, .dismiss)
  }
  
  // MARK: - ErrorPresenting Protocol Tests
  
  func testViewModelAdoptsErrorPresenting() async {
    class TestViewModel: ObservableObject, ErrorPresenting {
      @Published var errorMessage: ErrorMessage?
    }
    
    let viewModel = TestViewModel()
    XCTAssertNil(viewModel.errorMessage)
    
    viewModel.handleError(DomainError.profileNotFound)
    
    // Aguardar Task publicar no main thread
    try? await Task.sleep(nanoseconds: 50_000_000)
    
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertEqual(viewModel.errorMessage?.title, "Perfil não encontrado")
  }
  
  func testErrorPresentingPublishesOnMainThread() async {
    class TestViewModel: ObservableObject, ErrorPresenting {
      @Published var errorMessage: ErrorMessage?
      var wasCalledOnMainThread = false
      
      func checkThread() {
        wasCalledOnMainThread = Thread.isMainThread
      }
    }
    
    let viewModel = TestViewModel()
    viewModel.handleError(DomainError.profileNotFound)
    
    // Aguardar publicação
    try? await Task.sleep(nanoseconds: 50_000_000)
    
    await MainActor.run {
      viewModel.checkThread()
    }
    
    XCTAssertTrue(viewModel.wasCalledOnMainThread)
  }
  
  // MARK: - Integration Tests
  
  func testCompleteErrorFlow() async {
    class TestViewModel: ObservableObject, ErrorPresenting {
      @Published var errorMessage: ErrorMessage?
    }
    
    let viewModel = TestViewModel()
    
    // Simular erro de rede
    let networkError = URLError(.notConnectedToInternet)
    viewModel.handleError(networkError)
    
    try? await Task.sleep(nanoseconds: 50_000_000)
    
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertEqual(viewModel.errorMessage?.title, "Sem conexão")
    XCTAssertEqual(viewModel.errorMessage?.action, .openSettings)
  }
  
  func testMessagesAreUserFriendly() {
    let errors: [Error] = [
      URLError(.notConnectedToInternet),
      DomainError.profileNotFound,
      OpenAIClientError.invalidResponse,
      ImageCacheError.invalidImageData
    ]
    
    for error in errors {
      let message = ErrorMapper.userFriendlyMessage(for: error)
      
      // Verificar que não contém termos técnicos
      let fullText = "\(message.title) \(message.message)"
      XCTAssertFalse(fullText.contains("Error"))
      XCTAssertFalse(fullText.contains("URLError"))
      XCTAssertFalse(fullText.contains("HTTP"))
      XCTAssertFalse(fullText.contains("nil"))
      XCTAssertFalse(fullText.contains("null"))
    }
  }
}
