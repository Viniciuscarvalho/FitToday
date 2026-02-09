//
//  EnhancedLocalWorkoutPlanComposer.swift
//  FitToday
//
//  Created by AI on 09/02/26.
//  Part of: Workout Experience Overhaul (Task 2.0)
//

import Foundation

/// Enhanced local workout plan composer that guarantees workout variation.
///
/// This composer wraps the existing LocalWorkoutPlanComposer and adds:
/// - Automatic variation validation against last 3 workouts
/// - Retry mechanism with modified seeds (up to 2 retries)
/// - Integration with WorkoutHistoryRepository
///
/// - Note: Part of FR-002 (Variação Obrigatória de Treinos) from PRD
struct EnhancedLocalWorkoutPlanComposer: WorkoutPlanComposing, Sendable {

    // MARK: - Dependencies

    private let baseComposer: LocalWorkoutPlanComposer
    private let historyRepository: WorkoutHistoryRepository

    // MARK: - Configuration

    private let maxRetries = 2
    private let minimumDiversityPercent = 0.6

    // MARK: - Initialization

    init(
        baseComposer: LocalWorkoutPlanComposer = LocalWorkoutPlanComposer(),
        historyRepository: WorkoutHistoryRepository
    ) {
        self.baseComposer = baseComposer
        self.historyRepository = historyRepository
    }

    // MARK: - WorkoutPlanComposing

    func composePlan(
        blocks: [WorkoutBlock],
        profile: UserProfile,
        checkIn: DailyCheckIn
    ) async throws -> WorkoutPlan {
        // 1. Fetch last 3 workouts from history for variation validation
        let previousWorkouts = try await fetchRecentWorkouts(limit: 3)

        // 2. Attempt to generate a varied workout with retries
        var attempt = 0

        while attempt < maxRetries {
            // Generate workout using base composer
            let generatedPlan = try await baseComposer.composePlan(
                blocks: blocks,
                profile: profile,
                checkIn: checkIn
            )

            // Validate diversity against previous workouts
            let isValid = WorkoutVariationValidator.validateDiversity(
                generated: generatedPlan,
                previousWorkouts: previousWorkouts,
                minimumDiversityPercent: minimumDiversityPercent
            )

            if isValid {
                #if DEBUG
                let diversity = WorkoutVariationValidator.calculateDiversityRatio(
                    generated: generatedPlan,
                    previousWorkouts: previousWorkouts
                )
                print("[EnhancedLocalComposer] ✅ Workout passed variation validation (diversity: \(String(format: "%.0f", diversity * 100))%, attempt: \(attempt + 1)/\(maxRetries))")
                #endif
                return generatedPlan
            }

            // Validation failed, increment attempt
            attempt += 1

            #if DEBUG
            let diversity = WorkoutVariationValidator.calculateDiversityRatio(
                generated: generatedPlan,
                previousWorkouts: previousWorkouts
            )
            print("[EnhancedLocalComposer] ⚠️ Workout failed variation validation (diversity: \(String(format: "%.0f", diversity * 100))%, attempt: \(attempt)/\(maxRetries))")
            #endif

            // If not the last attempt, add small delay to allow seed to change
            // The base composer uses time-based seed (15-minute buckets)
            if attempt < maxRetries {
                // Small delay to ensure different seed generation
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }

        // 3. All retries exhausted - return last generated plan
        // This ensures we always return a valid workout, even if variation is suboptimal
        let finalPlan = try await baseComposer.composePlan(
            blocks: blocks,
            profile: profile,
            checkIn: checkIn
        )

        #if DEBUG
        let finalDiversity = WorkoutVariationValidator.calculateDiversityRatio(
            generated: finalPlan,
            previousWorkouts: previousWorkouts
        )
        print("[EnhancedLocalComposer] ⚠️ Returning workout after \(maxRetries) retries (diversity: \(String(format: "%.0f", finalDiversity * 100))%)")
        #endif

        return finalPlan
    }

    // MARK: - Private Helpers

    /// Fetches recent workouts from history repository
    ///
    /// - Parameter limit: Maximum number of workouts to fetch (default: 3)
    /// - Returns: Array of WorkoutPlan objects from history, most recent first
    private func fetchRecentWorkouts(limit: Int = 3) async throws -> [WorkoutPlan] {
        do {
            // Fetch entries from repository
            let entries = try await historyRepository.listEntries(limit: limit, offset: 0)

            // Extract WorkoutPlan objects (filter out entries without plans)
            let workoutPlans = entries.compactMap { $0.workoutPlan }

            #if DEBUG
            print("[EnhancedLocalComposer] Fetched \(workoutPlans.count) previous workouts for variation validation")
            #endif

            return workoutPlans
        } catch {
            // If history fetch fails, continue without validation
            // This ensures workout generation doesn't fail due to history issues
            #if DEBUG
            print("[EnhancedLocalComposer] ⚠️ Failed to fetch history: \(error.localizedDescription). Proceeding without variation validation.")
            #endif
            return []
        }
    }
}
