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

    private final class MockGetCurrentTrainerUseCase: GetCurrentTrainerUseCaseProtocol, @unchecked Sendable {
        var result: TrainerWithRelationship?

        func execute() async throws -> TrainerWithRelationship? {
            return result
        }

        func observeRelationship() -> AsyncStream<TrainerStudentRelationship?> {
            AsyncStream { continuation in
                continuation.finish()
            }
        }
    }

    // MARK: - Helpers

    private func makeTrainer() -> PersonalTrainer {
        PersonalTrainer(
            id: "trainer-1",
            displayName: "Test Trainer",
            email: "test@trainer.com",
            photoURL: nil,
            specializations: ["strength"],
            bio: nil,
            isActive: true,
            inviteCode: "TEST",
            maxStudents: 10,
            currentStudentCount: 0,
            rating: nil,
            reviewCount: nil
        )
    }

    private func makeViewModelWithRelationship(
        cancelUseCase: MockCancelUseCase
    ) async -> PersonalTrainerViewModel {
        let getCurrentUseCase = MockGetCurrentTrainerUseCase()
        let trainer = makeTrainer()
        let relationship = TrainerStudentRelationship(
            id: "rel-123",
            trainerId: trainer.id,
            studentId: "student-1",
            status: .pending,
            createdAt: Date()
        )
        getCurrentUseCase.result = TrainerWithRelationship(
            trainer: trainer,
            relationship: relationship
        )

        let viewModel = PersonalTrainerViewModel(
            cancelConnectionUseCase: cancelUseCase,
            getCurrentTrainerUseCase: getCurrentUseCase
        )

        // Load the trainer so relationshipId is set
        await viewModel.loadCurrentTrainer()
        XCTAssertEqual(viewModel.relationshipId, "rel-123")

        return viewModel
    }

    // MARK: - Cancel Connection Tests (Issue #88)

    func testCancelConnectionResetsLoadingOnSuccess() async {
        let cancelUseCase = MockCancelUseCase()
        let viewModel = await makeViewModelWithRelationship(cancelUseCase: cancelUseCase)

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
        let viewModel = await makeViewModelWithRelationship(cancelUseCase: cancelUseCase)

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

    func testRequestConnectionResetsIsRequestingOnSuccess() async {
        let requestUseCase = MockRequestUseCase()
        let viewModel = PersonalTrainerViewModel(
            requestConnectionUseCase: requestUseCase
        )

        let trainer = makeTrainer()
        let result = await viewModel.requestConnection(to: trainer)

        XCTAssertTrue(result)
        XCTAssertFalse(viewModel.isRequestingConnection, "isRequestingConnection must be false after success")
    }

    func testRequestConnectionResetsIsRequestingOnError() async {
        let requestUseCase = MockRequestUseCase()
        requestUseCase.shouldThrow = true
        let viewModel = PersonalTrainerViewModel(
            requestConnectionUseCase: requestUseCase
        )

        let trainer = makeTrainer()
        let result = await viewModel.requestConnection(to: trainer)

        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.isRequestingConnection, "isRequestingConnection must be false after error")
        XCTAssertNotNil(viewModel.error)
    }
}
