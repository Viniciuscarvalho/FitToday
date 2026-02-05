//
//  CMSWorkoutUseCases.swift
//  FitToday
//
//  Use cases for CMS workout operations.
//

import Foundation

// MARK: - Fetch CMS Workouts Use Case

/// Use case for fetching trainer workouts from the CMS.
struct FetchCMSWorkoutsUseCase: Sendable {

    private let repository: CMSWorkoutRepository
    private let authRepository: AuthenticationRepository

    init(repository: CMSWorkoutRepository, authRepository: AuthenticationRepository) {
        self.repository = repository
        self.authRepository = authRepository
    }

    /// Fetches workouts for the current user.
    ///
    /// - Parameters:
    ///   - trainerId: Optional trainer ID to filter by.
    ///   - page: Page number (default: 1).
    ///   - limit: Items per page (default: 20).
    /// - Returns: A tuple with workouts and hasMore flag.
    func execute(
        trainerId: String? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> (workouts: [TrainerWorkout], hasMore: Bool) {
        guard let user = try await authRepository.currentUser() else {
            throw CMSWorkoutError.notAuthenticated
        }

        return try await repository.fetchWorkouts(
            studentId: user.id,
            trainerId: trainerId,
            page: page,
            limit: limit
        )
    }
}

// MARK: - Fetch CMS Workout Detail Use Case

/// Use case for fetching a single workout's details.
struct FetchCMSWorkoutDetailUseCase: Sendable {

    private let repository: CMSWorkoutRepository

    init(repository: CMSWorkoutRepository) {
        self.repository = repository
    }

    /// Fetches a workout by ID.
    ///
    /// - Parameter id: The workout ID.
    /// - Returns: The TrainerWorkout.
    func execute(id: String) async throws -> TrainerWorkout {
        try await repository.fetchWorkout(id: id)
    }

    /// Fetches a workout as an executable WorkoutPlan.
    ///
    /// - Parameter id: The workout ID.
    /// - Returns: A WorkoutPlan ready for execution.
    func executeAsPlan(id: String) async throws -> WorkoutPlan {
        try await repository.fetchWorkoutPlan(id: id)
    }
}

// MARK: - Fetch Workout Progress Use Case

/// Use case for fetching workout progress.
struct FetchWorkoutProgressUseCase: Sendable {

    private let repository: CMSWorkoutRepository

    init(repository: CMSWorkoutRepository) {
        self.repository = repository
    }

    /// Fetches progress for a workout.
    ///
    /// - Parameter workoutId: The workout ID.
    /// - Returns: The progress data.
    func execute(workoutId: String) async throws -> CMSWorkoutProgress {
        try await repository.fetchProgress(workoutId: workoutId)
    }
}

// MARK: - Fetch Workout Feedback Use Case

/// Use case for fetching workout feedback.
struct FetchWorkoutFeedbackUseCase: Sendable {

    private let repository: CMSWorkoutRepository

    init(repository: CMSWorkoutRepository) {
        self.repository = repository
    }

    /// Fetches all feedback for a workout.
    ///
    /// - Parameter workoutId: The workout ID.
    /// - Returns: Array of feedback items.
    func execute(workoutId: String) async throws -> [CMSWorkoutFeedback] {
        try await repository.fetchFeedback(workoutId: workoutId)
    }
}

// MARK: - Post Workout Feedback Use Case

/// Use case for posting feedback on a workout.
struct PostWorkoutFeedbackUseCase: Sendable {

    private let repository: CMSWorkoutRepository

    init(repository: CMSWorkoutRepository) {
        self.repository = repository
    }

    /// Posts feedback for a workout.
    ///
    /// - Parameters:
    ///   - workoutId: The workout ID.
    ///   - type: The feedback type.
    ///   - message: The feedback message.
    ///   - rating: Optional rating (1-5).
    /// - Returns: The created feedback.
    func execute(
        workoutId: String,
        type: CMSFeedbackType,
        message: String,
        rating: Int? = nil
    ) async throws -> CMSWorkoutFeedback {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CMSWorkoutError.invalidFeedback
        }

        if let rating, (rating < 1 || rating > 5) {
            throw CMSWorkoutError.invalidRating
        }

        return try await repository.postFeedback(
            workoutId: workoutId,
            type: type,
            message: message,
            rating: rating
        )
    }
}

// MARK: - Complete Workout Use Case

/// Use case for marking a workout as completed.
struct CompleteCMSWorkoutUseCase: Sendable {

    private let repository: CMSWorkoutRepository

    init(repository: CMSWorkoutRepository) {
        self.repository = repository
    }

    /// Marks a workout as completed in the CMS.
    ///
    /// - Parameter id: The workout ID.
    func execute(id: String) async throws {
        try await repository.markWorkoutCompleted(id: id)
    }
}

// MARK: - Archive Workout Use Case

/// Use case for archiving a workout.
struct ArchiveCMSWorkoutUseCase: Sendable {

    private let repository: CMSWorkoutRepository

    init(repository: CMSWorkoutRepository) {
        self.repository = repository
    }

    /// Archives a workout (removes from active list).
    ///
    /// - Parameter id: The workout ID.
    func execute(id: String) async throws {
        try await repository.archiveWorkout(id: id)
    }
}

// MARK: - CMS Workout Error

/// Errors that can occur during CMS workout operations.
enum CMSWorkoutError: LocalizedError, Sendable {
    case notAuthenticated
    case workoutNotFound
    case invalidFeedback
    case invalidRating
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Voce precisa estar logado para acessar os treinos"
        case .workoutNotFound:
            return "Treino nao encontrado"
        case .invalidFeedback:
            return "A mensagem de feedback nao pode estar vazia"
        case .invalidRating:
            return "A avaliacao deve ser entre 1 e 5"
        case .syncFailed:
            return "Falha ao sincronizar com o CMS"
        }
    }
}
