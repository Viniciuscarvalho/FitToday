//
//  PersonalTrainerUseCaseTests.swift
//  FitTodayTests
//
//  Tests for RequestTrainerConnectionUseCase and CancelTrainerConnectionUseCase.
//

import XCTest
@testable import FitToday

final class PersonalTrainerUseCaseTests: XCTestCase {

    // MARK: - Mocks

    private final class MockTrainerStudentRepository: TrainerStudentRepository, @unchecked Sendable {
        var requestConnectionCallCount = 0
        var capturedMessage: String?
        var capturedTrainerId: String?
        var requestConnectionResult = "conn-123"
        var requestConnectionError: Error?

        var cancelConnectionCallCount = 0
        var capturedConnectionId: String?
        var capturedReason: String?
        var cancelConnectionError: Error?

        var currentRelationship: TrainerStudentRelationship?

        func requestConnection(
            trainerId: String,
            studentDisplayName: String,
            message: String?
        ) async throws -> String {
            requestConnectionCallCount += 1
            capturedTrainerId = trainerId
            capturedMessage = message
            if let error = requestConnectionError { throw error }
            return requestConnectionResult
        }

        func cancelConnection(connectionId: String, reason: String?) async throws {
            cancelConnectionCallCount += 1
            capturedConnectionId = connectionId
            capturedReason = reason
            if let error = cancelConnectionError { throw error }
        }

        func getCurrentRelationship(studentId: String) async throws -> TrainerStudentRelationship? {
            currentRelationship
        }

        func observeRelationship(studentId: String) -> AsyncStream<TrainerStudentRelationship?> {
            AsyncStream { $0.finish() }
        }
    }

    private final class MockAuthRepository: AuthenticationRepository, @unchecked Sendable {
        var user: SocialUser?

        func currentUser() async throws -> SocialUser? { user }
        func getIDToken() async throws -> String { "mock-token" }
        func signInWithApple() async throws -> SocialUser { fatalError() }
        func signInWithGoogle() async throws -> SocialUser { fatalError() }
        func signInWithEmail(_ email: String, password: String) async throws -> SocialUser { fatalError() }
        func createAccount(email: String, password: String, displayName: String) async throws -> SocialUser { fatalError() }
        func signOut() async throws {}
        func observeAuthState() -> AsyncStream<SocialUser?> { AsyncStream { $0.finish() } }
    }

    private final class MockFeatureFlags: FeatureFlagChecking, @unchecked Sendable {
        var enabled = true

        func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool { enabled }
        func checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey) async -> FeatureAccessResult { .allowed }
        func refreshFlags() async throws {}
    }

    // MARK: - Request Connection Tests

    func test_requestConnection_passesMessageThrough() async throws {
        let repo = MockTrainerStudentRepository()
        let auth = MockAuthRepository()
        auth.user = SocialUser(id: "student-1", displayName: "Test Student", email: "test@test.com", authProvider: .email, privacySettings: PrivacySettings(), createdAt: Date())
        let flags = MockFeatureFlags()

        let useCase = RequestTrainerConnectionUseCase(
            trainerStudentRepository: repo,
            authRepository: auth,
            featureFlagChecker: flags
        )

        let result = try await useCase.execute(trainerId: "trainer-1", message: "Hi, I want to train!")

        XCTAssertEqual(result, "conn-123")
        XCTAssertEqual(repo.capturedTrainerId, "trainer-1")
        XCTAssertEqual(repo.capturedMessage, "Hi, I want to train!")
        XCTAssertEqual(repo.requestConnectionCallCount, 1)
    }

    func test_requestConnection_nilMessage() async throws {
        let repo = MockTrainerStudentRepository()
        let auth = MockAuthRepository()
        auth.user = SocialUser(id: "student-1", displayName: "Test", authProvider: .email, privacySettings: PrivacySettings(), createdAt: Date())
        let flags = MockFeatureFlags()

        let useCase = RequestTrainerConnectionUseCase(
            trainerStudentRepository: repo,
            authRepository: auth,
            featureFlagChecker: flags
        )

        _ = try await useCase.execute(trainerId: "trainer-1", message: nil)

        XCTAssertNil(repo.capturedMessage)
    }

    func test_requestConnection_featureDisabled_throws() async {
        let repo = MockTrainerStudentRepository()
        let auth = MockAuthRepository()
        auth.user = SocialUser(id: "student-1", displayName: "Test", authProvider: .email, privacySettings: PrivacySettings(), createdAt: Date())
        let flags = MockFeatureFlags()
        flags.enabled = false

        let useCase = RequestTrainerConnectionUseCase(
            trainerStudentRepository: repo,
            authRepository: auth,
            featureFlagChecker: flags
        )

        do {
            _ = try await useCase.execute(trainerId: "trainer-1", message: nil)
            XCTFail("Expected featureDisabled error")
        } catch let error as PersonalTrainerError {
            XCTAssertEqual(error, .featureDisabled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(repo.requestConnectionCallCount, 0)
    }

    // MARK: - Cancel Connection Tests

    func test_cancelConnection_passesReasonThrough() async throws {
        let repo = MockTrainerStudentRepository()
        let auth = MockAuthRepository()
        auth.user = SocialUser(id: "student-1", displayName: "Test", authProvider: .email, privacySettings: PrivacySettings(), createdAt: Date())
        let flags = MockFeatureFlags()

        let useCase = CancelTrainerConnectionUseCase(
            trainerStudentRepository: repo,
            authRepository: auth,
            featureFlagChecker: flags
        )

        try await useCase.execute(connectionId: "conn-123", reason: "No longer interested")

        XCTAssertEqual(repo.cancelConnectionCallCount, 1)
        XCTAssertEqual(repo.capturedConnectionId, "conn-123")
        XCTAssertEqual(repo.capturedReason, "No longer interested")
    }

    func test_cancelConnection_featureDisabled_throws() async {
        let repo = MockTrainerStudentRepository()
        let auth = MockAuthRepository()
        auth.user = SocialUser(id: "student-1", displayName: "Test", authProvider: .email, privacySettings: PrivacySettings(), createdAt: Date())
        let flags = MockFeatureFlags()
        flags.enabled = false

        let useCase = CancelTrainerConnectionUseCase(
            trainerStudentRepository: repo,
            authRepository: auth,
            featureFlagChecker: flags
        )

        do {
            try await useCase.execute(connectionId: "conn-123", reason: nil)
            XCTFail("Expected featureDisabled error")
        } catch let error as PersonalTrainerError {
            XCTAssertEqual(error, .featureDisabled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(repo.cancelConnectionCallCount, 0)
    }
}

// MARK: - PersonalTrainerError Equatable

extension PersonalTrainerError: @retroactive Equatable {
    public static func == (lhs: PersonalTrainerError, rhs: PersonalTrainerError) -> Bool {
        switch (lhs, rhs) {
        case (.featureDisabled, .featureDisabled),
             (.trainerNotFound, .trainerNotFound),
             (.invalidInviteCode, .invalidInviteCode),
             (.alreadyConnected, .alreadyConnected),
             (.connectionNotFound, .connectionNotFound),
             (.unauthorized, .unauthorized):
            return true
        case (.networkError, .networkError):
            return true
        default:
            return false
        }
    }
}
