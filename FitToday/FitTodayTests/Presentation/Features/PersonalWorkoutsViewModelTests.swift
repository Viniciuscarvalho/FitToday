//
//  PersonalWorkoutsViewModelTests.swift
//  FitTodayTests
//
//  Unit tests for PersonalWorkoutsViewModel.
//

import XCTest
@testable import FitToday

final class PersonalWorkoutsViewModelTests: XCTestCase {

    var viewModel: PersonalWorkoutsViewModel!
    var mockRepository: MockPersonalWorkoutTestRepository!
    var mockPDFCache: MockPDFCacheTestService!

    @MainActor
    override func setUp() {
        super.setUp()
        mockRepository = MockPersonalWorkoutTestRepository()
        mockPDFCache = MockPDFCacheTestService()
        viewModel = PersonalWorkoutsViewModel(repository: mockRepository, pdfCache: mockPDFCache)
    }

    @MainActor
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockPDFCache = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    @MainActor
    func testInitialStateIsEmpty() {
        XCTAssertTrue(viewModel.workouts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.newWorkoutsCount, 0)
        XCTAssertFalse(viewModel.hasNewWorkouts)
    }

    // MARK: - Load Workouts Tests

    @MainActor
    func testLoadWorkoutsSuccessfully() async throws {
        let workout1 = PersonalWorkout.fixture(title: "Treino A", viewedAt: nil)
        let workout2 = PersonalWorkout.fixture(title: "Treino B", viewedAt: Date())
        mockRepository.workoutsToReturn = [workout1, workout2]

        await viewModel.loadWorkouts(userId: "user-123")

        XCTAssertEqual(viewModel.workouts.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testLoadWorkoutsWithError() async throws {
        mockRepository.shouldThrowError = true

        await viewModel.loadWorkouts(userId: "user-123")

        XCTAssertTrue(viewModel.workouts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - New Workouts Count Tests

    @MainActor
    func testNewWorkoutsCount() async throws {
        let newWorkout = PersonalWorkout.fixture(title: "New", viewedAt: nil)
        let viewedWorkout = PersonalWorkout.fixture(title: "Viewed", viewedAt: Date())
        mockRepository.workoutsToReturn = [newWorkout, viewedWorkout]

        await viewModel.loadWorkouts(userId: "user-123")

        XCTAssertEqual(viewModel.newWorkoutsCount, 1)
        XCTAssertTrue(viewModel.hasNewWorkouts)
    }

    @MainActor
    func testNoNewWorkouts() async throws {
        let viewedWorkout = PersonalWorkout.fixture(title: "Viewed", viewedAt: Date())
        mockRepository.workoutsToReturn = [viewedWorkout]

        await viewModel.loadWorkouts(userId: "user-123")

        XCTAssertEqual(viewModel.newWorkoutsCount, 0)
        XCTAssertFalse(viewModel.hasNewWorkouts)
    }

    // MARK: - Mark As Viewed Tests

    @MainActor
    func testMarkAsViewedUpdatesWorkout() async throws {
        let newWorkout = PersonalWorkout.fixture(id: "workout-1", title: "New", viewedAt: nil)
        mockRepository.workoutsToReturn = [newWorkout]

        await viewModel.loadWorkouts(userId: "user-123")
        XCTAssertTrue(viewModel.workouts[0].isNew)

        await viewModel.markAsViewed(viewModel.workouts[0])

        XCTAssertFalse(viewModel.workouts[0].isNew)
        XCTAssertNotNil(viewModel.workouts[0].viewedAt)
        XCTAssertTrue(mockRepository.markAsViewedCalled)
    }

    @MainActor
    func testMarkAsViewedSkipsAlreadyViewed() async throws {
        let viewedWorkout = PersonalWorkout.fixture(id: "workout-1", title: "Viewed", viewedAt: Date())
        mockRepository.workoutsToReturn = [viewedWorkout]

        await viewModel.loadWorkouts(userId: "user-123")
        await viewModel.markAsViewed(viewModel.workouts[0])

        XCTAssertFalse(mockRepository.markAsViewedCalled)
    }

    // MARK: - PDF Cache Tests

    @MainActor
    func testGetPDFURLReturnsCachedURL() async throws {
        let workout = PersonalWorkout.fixture()
        let expectedURL = URL(fileURLWithPath: "/tmp/cached.pdf")
        mockPDFCache.urlToReturn = expectedURL

        let url = try await viewModel.getPDFURL(for: workout)

        XCTAssertEqual(url, expectedURL)
    }

    @MainActor
    func testIsPDFCachedReturnsTrue() async throws {
        let workout = PersonalWorkout.fixture()
        mockPDFCache.isCachedResult = true

        let isCached = await viewModel.isPDFCached(workout)

        XCTAssertTrue(isCached)
    }

    @MainActor
    func testIsPDFCachedReturnsFalse() async throws {
        let workout = PersonalWorkout.fixture()
        mockPDFCache.isCachedResult = false

        let isCached = await viewModel.isPDFCached(workout)

        XCTAssertFalse(isCached)
    }

    // MARK: - Clear Error Tests

    @MainActor
    func testClearErrorRemovesMessage() async throws {
        mockRepository.shouldThrowError = true
        await viewModel.loadWorkouts(userId: "user-123")

        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Empty State Tests

    @MainActor
    func testIsEmptyWhenNoWorkouts() async throws {
        mockRepository.workoutsToReturn = []

        await viewModel.loadWorkouts(userId: "user-123")

        XCTAssertTrue(viewModel.isEmpty)
    }

    @MainActor
    func testIsNotEmptyWhenHasWorkouts() async throws {
        mockRepository.workoutsToReturn = [PersonalWorkout.fixture()]

        await viewModel.loadWorkouts(userId: "user-123")

        XCTAssertFalse(viewModel.isEmpty)
    }
}

// MARK: - Mocks

final class MockPersonalWorkoutTestRepository: PersonalWorkoutRepository, @unchecked Sendable {
    var workoutsToReturn: [PersonalWorkout] = []
    var shouldThrowError = false
    var markAsViewedCalled = false

    func fetchWorkouts(for userId: String) async throws -> [PersonalWorkout] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return workoutsToReturn
    }

    func markAsViewed(_ workoutId: String) async throws {
        markAsViewedCalled = true
    }

    func observeWorkouts(for userId: String) -> AsyncStream<[PersonalWorkout]> {
        AsyncStream { continuation in
            continuation.yield(workoutsToReturn)
        }
    }
}

final class MockPDFCacheTestService: PDFCaching, @unchecked Sendable {
    var urlToReturn: URL = URL(fileURLWithPath: "/tmp/test.pdf")
    var isCachedResult = false

    func getPDF(for workout: PersonalWorkout) async throws -> URL {
        urlToReturn
    }

    func isCached(workoutId: String, fileType: PersonalWorkout.FileType) async -> Bool {
        isCachedResult
    }
}
