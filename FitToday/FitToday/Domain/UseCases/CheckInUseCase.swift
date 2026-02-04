//
//  CheckInUseCase.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import Foundation

// MARK: - CheckInUseCase

/// Use case for creating workout check-ins with photo verification.
/// Handles all business logic validation before persisting the check-in.
struct CheckInUseCase: Sendable {

    // MARK: - Dependencies

    private let checkInRepository: CheckInRepository
    private let authRepository: AuthenticationRepository
    private let leaderboardRepository: LeaderboardRepository
    private let imageCompressor: ImageCompressing

    // MARK: - Constants

    private static let maxImageSizeBytes = 500_000

    // MARK: - Init

    init(
        checkInRepository: CheckInRepository,
        authRepository: AuthenticationRepository,
        leaderboardRepository: LeaderboardRepository,
        imageCompressor: ImageCompressing
    ) {
        self.checkInRepository = checkInRepository
        self.authRepository = authRepository
        self.leaderboardRepository = leaderboardRepository
        self.imageCompressor = imageCompressor
    }

    // MARK: - Execute

    /// Executes the check-in flow with all validations.
    /// - Parameters:
    ///   - workoutEntry: The completed workout entry
    ///   - photoData: Raw photo data from camera/gallery
    ///   - isConnected: Whether the device has network connectivity
    /// - Returns: The created CheckIn object
    /// - Throws: CheckInError if validation fails or upload fails
    @MainActor
    func execute(
        workoutEntry: WorkoutHistoryEntry,
        photoData: Data,
        isConnected: Bool
    ) async throws -> CheckIn {
        // 1. Validate network
        guard isConnected else {
            throw CheckInError.networkUnavailable
        }

        // 2. Validate user is in group
        guard let user = try await authRepository.currentUser(),
              let groupId = user.currentGroupId else {
            throw CheckInError.notInGroup
        }

        // 3. Validate workout duration
        let duration = workoutEntry.durationMinutes ?? 0
        guard duration >= CheckIn.minimumWorkoutMinutes else {
            throw CheckInError.workoutTooShort(minutes: duration)
        }

        // 4. Compress image
        let compressed: Data
        do {
            compressed = try imageCompressor.compress(
                data: photoData,
                maxBytes: Self.maxImageSizeBytes,
                quality: 0.7
            )
        } catch {
            throw CheckInError.uploadFailed(underlying: error)
        }

        // 5. Upload photo with retry logic
        let photoURL = try await uploadPhotoWithRetry(
            imageData: compressed,
            groupId: groupId,
            userId: user.id
        )

        // 6. Get current challenge
        let challenges = try await leaderboardRepository.getCurrentWeekChallenges(groupId: groupId)
        guard let challenge = challenges.first(where: { $0.type == .checkIns }) else {
            throw CheckInError.noActiveChallenge
        }

        // 7. Create check-in record
        let checkIn = CheckIn(
            id: UUID().uuidString,
            groupId: groupId,
            challengeId: challenge.id,
            userId: user.id,
            displayName: user.displayName,
            userPhotoURL: user.photoURL,
            checkInPhotoURL: photoURL,
            workoutEntryId: workoutEntry.id,
            workoutDurationMinutes: duration,
            createdAt: Date()
        )

        try await checkInRepository.createCheckIn(checkIn)

        // 8. Increment challenge counter
        try await leaderboardRepository.incrementCheckIn(
            challengeId: challenge.id,
            userId: user.id,
            displayName: user.displayName,
            photoURL: user.photoURL
        )

        return checkIn
    }

    // MARK: - Private Methods

    /// Uploads a photo with exponential backoff retry logic.
    /// - Parameters:
    ///   - imageData: Compressed image data
    ///   - groupId: Group identifier
    ///   - userId: User identifier
    /// - Returns: The URL of the uploaded photo
    /// - Throws: CheckInError if all retries fail
    private func uploadPhotoWithRetry(
        imageData: Data,
        groupId: String,
        userId: String
    ) async throws -> URL {
        let maxRetries = 3
        var lastError: Error?

        for attempt in 1...maxRetries {
            do {
                return try await checkInRepository.uploadPhoto(
                    imageData: imageData,
                    groupId: groupId,
                    userId: userId
                )
            } catch {
                lastError = error
                #if DEBUG
                print("[CheckIn] Upload attempt \(attempt)/\(maxRetries) failed: \(error.localizedDescription)")
                #endif
                if attempt < maxRetries {
                    // Exponential backoff: 1s, 2s, 4s
                    let delayNanoseconds = UInt64(pow(2.0, Double(attempt - 1)) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delayNanoseconds)
                }
            }
        }

        throw CheckInError.uploadFailed(underlying: lastError!)
    }
}
