//
//  CompleteCustomWorkoutUseCase.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation

/// Use case for completing a custom workout session.
/// Handles recording completion, history entry, HealthKit sync, and challenge sync.
struct CompleteCustomWorkoutUseCase: Sendable {
    private let repository: CustomWorkoutRepository
    private let historyRepository: WorkoutHistoryRepository
    private let syncWorkoutUseCase: SyncWorkoutCompletionUseCase?

    /// Minimum workout duration in minutes to count for challenges
    private static let minimumWorkoutMinutes = 30

    init(
        repository: CustomWorkoutRepository,
        historyRepository: WorkoutHistoryRepository,
        syncWorkoutUseCase: SyncWorkoutCompletionUseCase? = nil
    ) {
        self.repository = repository
        self.historyRepository = historyRepository
        self.syncWorkoutUseCase = syncWorkoutUseCase
    }

    /// Completes a custom workout session
    /// - Parameters:
    ///   - template: The template that was used
    ///   - actualExercises: The exercises with actual performed values
    ///   - startTime: When the workout started
    ///   - endTime: When the workout ended
    /// - Returns: The created history entry
    @discardableResult
    func execute(
        template: CustomWorkoutTemplate,
        actualExercises: [CustomExerciseEntry],
        startTime: Date,
        endTime: Date
    ) async throws -> WorkoutHistoryEntry {
        let durationMinutes = max(1, Int(endTime.timeIntervalSince(startTime) / 60))

        #if DEBUG
        print("[CompleteCustomWorkoutUseCase] 🏋️ Completing workout '\(template.name)'")
        print("[CompleteCustomWorkoutUseCase]    Duration: \(durationMinutes) min")
        print("[CompleteCustomWorkoutUseCase]    Exercises: \(actualExercises.count)")
        #endif

        // 1. Record completion in custom workout repository
        try await repository.recordCompletion(
            templateId: template.id,
            actualExercises: actualExercises,
            duration: durationMinutes,
            completedAt: endTime
        )

        #if DEBUG
        print("[CompleteCustomWorkoutUseCase] ✅ Recorded completion in custom workout repository")
        #endif

        // 2. Create history entry for general tracking
        // Note: Custom workouts use .app source since they're completed in-app
        let historyEntry = WorkoutHistoryEntry(
            id: UUID(),
            date: endTime,
            planId: template.id, // Use template ID as plan ID
            title: template.name,
            focus: .fullBody, // Custom workouts default to full body
            status: .completed,
            durationMinutes: durationMinutes,
            caloriesBurned: nil, // Will be populated by HealthKit if available
            source: .app
        )

        try await historyRepository.saveEntry(historyEntry)

        #if DEBUG
        print("[CompleteCustomWorkoutUseCase] ✅ Saved history entry")
        #endif

        // 3. HealthKit sync is skipped for custom workouts as they don't have a WorkoutPlan
        // The user's workout will still count toward challenges via SyncWorkoutCompletionUseCase
        #if DEBUG
        print("[CompleteCustomWorkoutUseCase] ℹ️ HealthKit export skipped (no WorkoutPlan for custom workout)")
        #endif

        // 4. Sync to challenges (if >= 30 min)
        if durationMinutes >= Self.minimumWorkoutMinutes {
            if let syncWorkoutUseCase {
                await syncWorkoutUseCase.execute(entry: historyEntry)
                #if DEBUG
                print("[CompleteCustomWorkoutUseCase] ✅ Synced to challenges (\(durationMinutes) min >= \(Self.minimumWorkoutMinutes) min)")
                #endif
            }
        } else {
            #if DEBUG
            print("[CompleteCustomWorkoutUseCase] ℹ️ Workout too short for challenges (\(durationMinutes) min < \(Self.minimumWorkoutMinutes) min)")
            #endif
        }

        return historyEntry
    }

    /// Calculates estimated calories burned based on duration and intensity
    /// This is a rough estimate - actual calories should come from HealthKit
    private func estimateCalories(durationMinutes: Int, exerciseCount: Int) -> Int? {
        // Average ~5-7 calories per minute for strength training
        let caloriesPerMinute = 6.0
        return Int(Double(durationMinutes) * caloriesPerMinute)
    }
}
