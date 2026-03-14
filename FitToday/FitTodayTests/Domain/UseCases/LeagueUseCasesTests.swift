//
//  LeagueUseCasesTests.swift
//  FitTodayTests
//

import XCTest
@testable import FitToday

// MARK: - GetCurrentLeagueUseCaseTests

@MainActor
final class GetCurrentLeagueUseCaseTests: XCTestCase {

    private var sut: GetCurrentLeagueUseCase!
    private var mockRepo: MockLeagueRepository!
    private var mockFlags: StubFeatureFlagChecker!

    override func setUp() {
        super.setUp()
        mockRepo = MockLeagueRepository()
        mockFlags = StubFeatureFlagChecker(enabledFlags: [])
        sut = GetCurrentLeagueUseCase(repository: mockRepo, featureFlags: mockFlags)
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        mockFlags = nil
        super.tearDown()
    }

    // MARK: - Feature Flag Disabled

    func test_execute_returnsNil_whenFeatureFlagDisabled() async throws {
        // Given
        mockFlags = StubFeatureFlagChecker(enabledFlags: [])
        sut = GetCurrentLeagueUseCase(repository: mockRepo, featureFlags: mockFlags)
        mockRepo.currentLeague = .fixture()

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNil(result)
        XCTAssertFalse(mockRepo.getCurrentLeagueCalled)
    }

    // MARK: - Feature Flag Enabled

    func test_execute_returnsLeague_whenFeatureFlagEnabled() async throws {
        // Given
        mockFlags = StubFeatureFlagChecker(enabledFlags: [.leaguesEnabled])
        sut = GetCurrentLeagueUseCase(repository: mockRepo, featureFlags: mockFlags)
        let expectedLeague = League.fixture(tier: .gold, seasonWeek: 5)
        mockRepo.currentLeague = expectedLeague

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tier, .gold)
        XCTAssertEqual(result?.seasonWeek, 5)
        XCTAssertTrue(mockRepo.getCurrentLeagueCalled)
    }

    func test_execute_returnsNil_whenNoActiveLeague() async throws {
        // Given
        mockFlags = StubFeatureFlagChecker(enabledFlags: [.leaguesEnabled])
        sut = GetCurrentLeagueUseCase(repository: mockRepo, featureFlags: mockFlags)
        mockRepo.currentLeague = nil

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNil(result)
        XCTAssertTrue(mockRepo.getCurrentLeagueCalled)
    }

    // MARK: - Error Propagation

    func test_execute_propagatesError_whenRepositoryThrows() async {
        // Given
        mockFlags = StubFeatureFlagChecker(enabledFlags: [.leaguesEnabled])
        sut = GetCurrentLeagueUseCase(repository: mockRepo, featureFlags: mockFlags)
        mockRepo.shouldThrowError = true

        // When / Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mockRepo.getCurrentLeagueCalled)
        }
    }
}

// MARK: - GetLeagueHistoryUseCaseTests

@MainActor
final class GetLeagueHistoryUseCaseTests: XCTestCase {

    private var sut: GetLeagueHistoryUseCase!
    private var mockRepo: MockLeagueRepository!
    private var mockFlags: StubFeatureFlagChecker!

    override func setUp() {
        super.setUp()
        mockRepo = MockLeagueRepository()
        mockFlags = StubFeatureFlagChecker(enabledFlags: [])
        sut = GetLeagueHistoryUseCase(repository: mockRepo, featureFlags: mockFlags)
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        mockFlags = nil
        super.tearDown()
    }

    // MARK: - Feature Flag Disabled

    func test_execute_returnsEmpty_whenFeatureFlagDisabled() async throws {
        // Given
        mockFlags = StubFeatureFlagChecker(enabledFlags: [])
        sut = GetLeagueHistoryUseCase(repository: mockRepo, featureFlags: mockFlags)
        mockRepo.history = [.fixture()]

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertFalse(mockRepo.getHistoryCalled)
    }

    // MARK: - Feature Flag Enabled

    func test_execute_returnsHistory_whenFeatureFlagEnabled() async throws {
        // Given
        mockFlags = StubFeatureFlagChecker(enabledFlags: [.leaguesEnabled])
        sut = GetLeagueHistoryUseCase(repository: mockRepo, featureFlags: mockFlags)
        mockRepo.history = [
            .fixture(id: "r1", seasonWeek: 1, promoted: true),
            .fixture(id: "r2", seasonWeek: 2, demoted: true)
        ]

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result[0].promoted)
        XCTAssertTrue(result[1].demoted)
        XCTAssertTrue(mockRepo.getHistoryCalled)
    }

    func test_execute_returnsEmptyArray_whenNoHistory() async throws {
        // Given
        mockFlags = StubFeatureFlagChecker(enabledFlags: [.leaguesEnabled])
        sut = GetLeagueHistoryUseCase(repository: mockRepo, featureFlags: mockFlags)
        mockRepo.history = []

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockRepo.getHistoryCalled)
    }

    // MARK: - Error Propagation

    func test_execute_propagatesError_whenRepositoryThrows() async {
        // Given
        mockFlags = StubFeatureFlagChecker(enabledFlags: [.leaguesEnabled])
        sut = GetLeagueHistoryUseCase(repository: mockRepo, featureFlags: mockFlags)
        mockRepo.shouldThrowError = true

        // When / Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mockRepo.getHistoryCalled)
        }
    }
}

// MARK: - ObserveLeagueUseCaseTests

@MainActor
final class ObserveLeagueUseCaseTests: XCTestCase {

    func test_execute_returnsStream_fromRepository() {
        // Given
        let mockRepo = MockLeagueRepository()
        let sut = ObserveLeagueUseCase(repository: mockRepo)

        // When
        _ = sut.execute(leagueId: "league1")

        // Then
        XCTAssertTrue(mockRepo.observeLeagueCalled)
    }
}

// MARK: - Stub Feature Flag Checker

final class StubFeatureFlagChecker: FeatureFlagChecking, @unchecked Sendable {
    let enabledFlags: Set<FeatureFlagKey>

    init(enabledFlags: Set<FeatureFlagKey>) {
        self.enabledFlags = enabledFlags
    }

    func isFeatureEnabled(_ key: FeatureFlagKey) async -> Bool {
        enabledFlags.contains(key)
    }

    func checkFeatureAccess(_ feature: ProFeature, flag: FeatureFlagKey) async -> FeatureAccessResult {
        .featureDisabled(reason: "stub")
    }

    func refreshFlags() async throws {}
}
