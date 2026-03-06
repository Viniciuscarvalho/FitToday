//
//  PersonalTrainerViewModelTests.swift
//  FitTodayTests
//
//  Tests for PersonalTrainerViewModel — Issue #88 regression tests.
//

import XCTest
@testable import FitToday

@MainActor
final class PersonalTrainerViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockCancelUseCase: CancelTrainerConnectionUseCaseProtocol, @unchecked Sendable {
        var executeCallCount = 0
        var shouldThrow = false

        func execute(relationshipId: String) async throws {
            executeCallCount += 1
            if shouldThrow {
                throw PersonalTrainerError.unauthorized
            }
        }
    }

    private final class MockRequestUseCase: RequestTrainerConnectionUseCaseProtocol, @unchecked Sendable {
        var shouldThrow = false
        var returnedId = "rel-123"

        func execute(trainerId: String) async throws -> String {
            if shouldThrow {
                throw PersonalTrainerError.unauthorized
            }
            return returnedId
        }
    }

    // MARK: - Cancel Connection Tests (Issue #88)

    func testCancelConnectionResetsLoadingOnSuccess() async {
        let cancelUseCase = MockCancelUseCase()
        let viewModel = PersonalTrainerViewModel(
            cancelConnectionUseCase: cancelUseCase
        )

        // Simulate having an active relationship
        viewModel.setRelationshipIdForTesting("rel-123")

        let result = await viewModel.cancelConnection()

        XCTAssertTrue(result)
        XCTAssertFalse(viewModel.isLoading, "isLoading must be false after successful cancel")
        XCTAssertNil(viewModel.currentTrainer)
        XCTAssertNil(viewModel.connectionStatus)
        XCTAssertNil(viewModel.relationshipId)
    }

    func testCancelConnectionResetsLoadingOnError() async {
        let cancelUseCase = MockCancelUseCase()
        cancelUseCase.shouldThrow = true
        let viewModel = PersonalTrainerViewModel(
            cancelConnectionUseCase: cancelUseCase
        )

        viewModel.setRelationshipIdForTesting("rel-123")

        let result = await viewModel.cancelConnection()

        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.isLoading, "isLoading must be false even after cancel error")
        XCTAssertNotNil(viewModel.error)
    }

    func testCancelConnectionReturnsFalseWhenNoRelationshipId() async {
        let cancelUseCase = MockCancelUseCase()
        let viewModel = PersonalTrainerViewModel(
            cancelConnectionUseCase: cancelUseCase
        )

        // No relationshipId set
        let result = await viewModel.cancelConnection()

        XCTAssertFalse(result)
        XCTAssertEqual(cancelUseCase.executeCallCount, 0, "Should not call use case without relationship ID")
    }

    // MARK: - Request Connection Tests

    func testRequestConnectionResetsLoadingOnSuccess() async {
        let requestUseCase = MockRequestUseCase()
        let viewModel = PersonalTrainerViewModel(
            requestConnectionUseCase: requestUseCase
        )

        let trainer = PersonalTrainer.stub()
        let result = await viewModel.requestConnection(to: trainer)

        XCTAssertTrue(result)
        XCTAssertFalse(viewModel.isRequestingConnection, "isRequestingConnection must be false after success")
    }

    func testRequestConnectionResetsLoadingOnError() async {
        let requestUseCase = MockRequestUseCase()
        requestUseCase.shouldThrow = true
        let viewModel = PersonalTrainerViewModel(
            requestConnectionUseCase: requestUseCase
        )

        let trainer = PersonalTrainer.stub()
        let result = await viewModel.requestConnection(to: trainer)

        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.isRequestingConnection, "isRequestingConnection must be false after error")
        XCTAssertNotNil(viewModel.error)
    }
}

// MARK: - Test Helpers

extension PersonalTrainerViewModel {
    /// Test-only helper to set relationshipId for cancel tests
    func setRelationshipIdForTesting(_ id: String) {
        // Access internal state via the testing init path
        // We need a way to set this. Since the property is private(set),
        // we'll use a workaround through the observation flow.
        self.relationshipId = id
    }
}
