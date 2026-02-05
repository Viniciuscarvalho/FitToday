//
//  CMSWorkoutUseCasesTests.swift
//  FitTodayTests
//
//  Tests for CMS workout use cases.
//

import XCTest
@testable import FitToday

final class CMSWorkoutUseCasesTests: XCTestCase {

    // MARK: - FetchCMSWorkoutsUseCase Tests

    func test_fetchCMSWorkouts_whenAuthenticated_fetchesWorkouts() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let mockAuth = MockAuthenticationRepository()
        let sut = FetchCMSWorkoutsUseCase(repository: mockRepo, authRepository: mockAuth)

        let user = SocialUser.fixture(id: "user123")
        mockAuth.currentUserResult = user

        let workouts = [TrainerWorkout.fixture(id: "w1"), TrainerWorkout.fixture(id: "w2")]
        mockRepo.fetchWorkoutsResult = (workouts: workouts, hasMore: false)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(mockRepo.fetchWorkoutsCalled)
        XCTAssertEqual(mockRepo.capturedStudentId, "user123")
        XCTAssertNil(mockRepo.capturedTrainerId)
        XCTAssertEqual(result.workouts.count, 2)
        XCTAssertFalse(result.hasMore)
    }

    func test_fetchCMSWorkouts_whenNotAuthenticated_throwsError() async {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let mockAuth = MockAuthenticationRepository()
        let sut = FetchCMSWorkoutsUseCase(repository: mockRepo, authRepository: mockAuth)

        mockAuth.currentUserResult = nil

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected notAuthenticated error")
        } catch let error as CMSWorkoutError {
            XCTAssertEqual(error, .notAuthenticated)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchCMSWorkouts_withTrainerId_filtersCorrectly() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let mockAuth = MockAuthenticationRepository()
        let sut = FetchCMSWorkoutsUseCase(repository: mockRepo, authRepository: mockAuth)

        mockAuth.currentUserResult = SocialUser.fixture(id: "user123")
        mockRepo.fetchWorkoutsResult = (workouts: [], hasMore: false)

        // When
        _ = try await sut.execute(trainerId: "trainer456", page: 2, limit: 10)

        // Then
        XCTAssertEqual(mockRepo.capturedTrainerId, "trainer456")
        XCTAssertEqual(mockRepo.capturedPage, 2)
        XCTAssertEqual(mockRepo.capturedLimit, 10)
    }

    // MARK: - FetchCMSWorkoutDetailUseCase Tests

    func test_fetchWorkoutDetail_fetchesById() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = FetchCMSWorkoutDetailUseCase(repository: mockRepo)

        let workout = TrainerWorkout.fixture(id: "workout1", title: "Test Workout")
        mockRepo.fetchWorkoutResult = workout

        // When
        let result = try await sut.execute(id: "workout1")

        // Then
        XCTAssertTrue(mockRepo.fetchWorkoutCalled)
        XCTAssertEqual(mockRepo.capturedWorkoutId, "workout1")
        XCTAssertEqual(result.id, "workout1")
        XCTAssertEqual(result.title, "Test Workout")
    }

    func test_fetchWorkoutAsPlan_convertsToWorkoutPlan() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = FetchCMSWorkoutDetailUseCase(repository: mockRepo)

        let plan = WorkoutPlan.fixture(title: "Converted Plan")
        mockRepo.fetchWorkoutPlanResult = plan

        // When
        let result = try await sut.executeAsPlan(id: "workout1")

        // Then
        XCTAssertTrue(mockRepo.fetchWorkoutPlanCalled)
        XCTAssertEqual(result.title, "Converted Plan")
    }

    // MARK: - FetchWorkoutProgressUseCase Tests

    func test_fetchProgress_returnsProgressData() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = FetchWorkoutProgressUseCase(repository: mockRepo)

        let progress = CMSWorkoutProgress(
            workoutId: "w1",
            studentId: "student1",
            completedSessions: 5,
            totalSessions: 10,
            lastSessionDate: Date(),
            exerciseProgress: [],
            overallProgress: 0.5
        )
        mockRepo.fetchProgressResult = progress

        // When
        let result = try await sut.execute(workoutId: "w1")

        // Then
        XCTAssertTrue(mockRepo.fetchProgressCalled)
        XCTAssertEqual(result.completedSessions, 5)
        XCTAssertEqual(result.totalSessions, 10)
        XCTAssertEqual(result.overallProgress, 0.5)
    }

    // MARK: - FetchWorkoutFeedbackUseCase Tests

    func test_fetchFeedback_returnsAllFeedback() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = FetchWorkoutFeedbackUseCase(repository: mockRepo)

        let feedbacks = [
            CMSWorkoutFeedback.fixture(id: "f1", message: "Great workout!"),
            CMSWorkoutFeedback.fixture(id: "f2", message: "Too hard")
        ]
        mockRepo.fetchFeedbackResult = feedbacks

        // When
        let result = try await sut.execute(workoutId: "w1")

        // Then
        XCTAssertTrue(mockRepo.fetchFeedbackCalled)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].message, "Great workout!")
    }

    // MARK: - PostWorkoutFeedbackUseCase Tests

    func test_postFeedback_withValidData_createsFeedback() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = PostWorkoutFeedbackUseCase(repository: mockRepo)

        let createdFeedback = CMSWorkoutFeedback.fixture(
            workoutId: "w1",
            message: "Excellent session",
            rating: 5
        )
        mockRepo.postFeedbackResult = createdFeedback

        // When
        let result = try await sut.execute(
            workoutId: "w1",
            type: .general,
            message: "Excellent session",
            rating: 5
        )

        // Then
        XCTAssertTrue(mockRepo.postFeedbackCalled)
        XCTAssertEqual(mockRepo.capturedFeedbackWorkoutId, "w1")
        XCTAssertEqual(mockRepo.capturedFeedbackType, .general)
        XCTAssertEqual(mockRepo.capturedFeedbackMessage, "Excellent session")
        XCTAssertEqual(mockRepo.capturedFeedbackRating, 5)
        XCTAssertEqual(result.rating, 5)
    }

    func test_postFeedback_withEmptyMessage_throwsError() async {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = PostWorkoutFeedbackUseCase(repository: mockRepo)

        // When/Then
        do {
            _ = try await sut.execute(
                workoutId: "w1",
                type: .general,
                message: "   ",
                rating: nil
            )
            XCTFail("Expected invalidFeedback error")
        } catch let error as CMSWorkoutError {
            XCTAssertEqual(error, .invalidFeedback)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_postFeedback_withInvalidRating_throwsError() async {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = PostWorkoutFeedbackUseCase(repository: mockRepo)

        // When/Then
        do {
            _ = try await sut.execute(
                workoutId: "w1",
                type: .general,
                message: "Test",
                rating: 6 // Invalid: > 5
            )
            XCTFail("Expected invalidRating error")
        } catch let error as CMSWorkoutError {
            XCTAssertEqual(error, .invalidRating)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        do {
            _ = try await sut.execute(
                workoutId: "w1",
                type: .general,
                message: "Test",
                rating: 0 // Invalid: < 1
            )
            XCTFail("Expected invalidRating error")
        } catch let error as CMSWorkoutError {
            XCTAssertEqual(error, .invalidRating)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - CompleteCMSWorkoutUseCase Tests

    func test_completeWorkout_marksAsCompleted() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = CompleteCMSWorkoutUseCase(repository: mockRepo)

        // When
        try await sut.execute(id: "workout1")

        // Then
        XCTAssertTrue(mockRepo.markWorkoutCompletedCalled)
        XCTAssertEqual(mockRepo.capturedCompletedWorkoutId, "workout1")
    }

    // MARK: - ArchiveCMSWorkoutUseCase Tests

    func test_archiveWorkout_archivesWorkout() async throws {
        // Given
        let mockRepo = MockCMSWorkoutRepository()
        let sut = ArchiveCMSWorkoutUseCase(repository: mockRepo)

        // When
        try await sut.execute(id: "workout1")

        // Then
        XCTAssertTrue(mockRepo.archiveWorkoutCalled)
        XCTAssertEqual(mockRepo.capturedArchivedWorkoutId, "workout1")
    }
}

// MARK: - Mock Repository

final class MockCMSWorkoutRepository: CMSWorkoutRepository, @unchecked Sendable {
    var fetchWorkoutsCalled = false
    var capturedStudentId: String?
    var capturedTrainerId: String?
    var capturedPage: Int?
    var capturedLimit: Int?
    var fetchWorkoutsResult: (workouts: [TrainerWorkout], hasMore: Bool) = (workouts: [], hasMore: false)

    var fetchWorkoutCalled = false
    var capturedWorkoutId: String?
    var fetchWorkoutResult: TrainerWorkout?

    var fetchWorkoutPlanCalled = false
    var fetchWorkoutPlanResult: WorkoutPlan?

    var fetchProgressCalled = false
    var fetchProgressResult: CMSWorkoutProgress?

    var fetchFeedbackCalled = false
    var fetchFeedbackResult: [CMSWorkoutFeedback] = []

    var postFeedbackCalled = false
    var capturedFeedbackWorkoutId: String?
    var capturedFeedbackType: CMSFeedbackType?
    var capturedFeedbackMessage: String?
    var capturedFeedbackRating: Int?
    var postFeedbackResult: CMSWorkoutFeedback?

    var markWorkoutCompletedCalled = false
    var capturedCompletedWorkoutId: String?

    var archiveWorkoutCalled = false
    var capturedArchivedWorkoutId: String?

    func fetchWorkouts(studentId: String, trainerId: String?, page: Int, limit: Int) async throws -> (workouts: [TrainerWorkout], hasMore: Bool) {
        fetchWorkoutsCalled = true
        capturedStudentId = studentId
        capturedTrainerId = trainerId
        capturedPage = page
        capturedLimit = limit
        return fetchWorkoutsResult
    }

    func fetchWorkout(id: String) async throws -> TrainerWorkout {
        fetchWorkoutCalled = true
        capturedWorkoutId = id
        guard let result = fetchWorkoutResult else {
            throw CMSWorkoutError.workoutNotFound
        }
        return result
    }

    func fetchWorkoutPlan(id: String) async throws -> WorkoutPlan {
        fetchWorkoutPlanCalled = true
        guard let result = fetchWorkoutPlanResult else {
            throw CMSWorkoutError.workoutNotFound
        }
        return result
    }

    func fetchProgress(workoutId: String) async throws -> CMSWorkoutProgress {
        fetchProgressCalled = true
        guard let result = fetchProgressResult else {
            throw CMSWorkoutError.workoutNotFound
        }
        return result
    }

    func fetchFeedback(workoutId: String) async throws -> [CMSWorkoutFeedback] {
        fetchFeedbackCalled = true
        return fetchFeedbackResult
    }

    func postFeedback(workoutId: String, type: CMSFeedbackType, message: String, rating: Int?) async throws -> CMSWorkoutFeedback {
        postFeedbackCalled = true
        capturedFeedbackWorkoutId = workoutId
        capturedFeedbackType = type
        capturedFeedbackMessage = message
        capturedFeedbackRating = rating
        guard let result = postFeedbackResult else {
            throw CMSWorkoutError.syncFailed
        }
        return result
    }

    func markWorkoutCompleted(id: String) async throws {
        markWorkoutCompletedCalled = true
        capturedCompletedWorkoutId = id
    }

    func archiveWorkout(id: String) async throws {
        archiveWorkoutCalled = true
        capturedArchivedWorkoutId = id
    }
}

// MARK: - Fixtures

extension TrainerWorkout {
    static func fixture(
        id: String = "workout1",
        trainerId: String = "trainer1",
        title: String = "Test Workout",
        description: String? = nil,
        focus: DailyFocus = .fullBody,
        estimatedDurationMinutes: Int = 60,
        intensity: WorkoutIntensity = .moderate,
        phases: [TrainerWorkoutPhase] = [],
        isActive: Bool = true,
        createdAt: Date = Date(),
        version: Int = 1
    ) -> TrainerWorkout {
        TrainerWorkout(
            id: id,
            trainerId: trainerId,
            title: title,
            description: description,
            focus: focus,
            estimatedDurationMinutes: estimatedDurationMinutes,
            intensity: intensity,
            phases: phases,
            schedule: TrainerWorkoutSchedule(type: .once, scheduledDate: nil, dayOfWeek: nil),
            isActive: isActive,
            createdAt: createdAt,
            version: version
        )
    }
}

extension WorkoutPlan {
    static func fixture(
        id: UUID = UUID(),
        title: String = "Test Plan",
        focus: DailyFocus = .fullBody,
        estimatedDurationMinutes: Int = 60,
        intensity: WorkoutIntensity = .moderate,
        phases: [WorkoutPlanPhase] = [],
        createdAt: Date = Date()
    ) -> WorkoutPlan {
        WorkoutPlan(
            id: id,
            title: title,
            focus: focus,
            estimatedDurationMinutes: estimatedDurationMinutes,
            intensity: intensity,
            phases: phases,
            createdAt: createdAt
        )
    }
}

extension CMSWorkoutFeedback {
    static func fixture(
        id: String = "feedback1",
        workoutId: String = "workout1",
        studentId: String = "student1",
        trainerId: String? = nil,
        type: CMSFeedbackType = .general,
        message: String = "Test feedback",
        rating: Int? = nil,
        createdAt: Date = Date()
    ) -> CMSWorkoutFeedback {
        CMSWorkoutFeedback(
            id: id,
            workoutId: workoutId,
            studentId: studentId,
            trainerId: trainerId,
            type: type,
            message: message,
            rating: rating,
            createdAt: createdAt,
            repliedAt: nil,
            replyMessage: nil
        )
    }
}
