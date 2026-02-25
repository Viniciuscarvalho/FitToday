import ActivityKit
import Foundation
import OSLog

/// Manager for controlling Workout Live Activity lifecycle
/// Handles starting, updating, and ending Live Activities for workout sessions
@MainActor
final class WorkoutLiveActivityManager {
    // MARK: - Properties

    /// Currently active Live Activity instance
    private(set) var currentActivity: Activity<WorkoutActivityAttributes>?

    /// Logger for debugging Live Activity operations
    private let logger = Logger(subsystem: "com.fittoday.app", category: "LiveActivity")

    // MARK: - Lifecycle Methods

    /// Starts a new Live Activity for the workout session
    /// - Parameters:
    ///   - workoutTitle: Title of the workout
    ///   - totalExercises: Total number of exercises in the workout
    ///   - initialExerciseName: Name of the first exercise
    /// - Throws: Error if activity creation fails or permission is denied
    func startActivity(
        workoutTitle: String,
        totalExercises: Int,
        initialExerciseName: String
    ) async throws {
        logger.info("Starting Live Activity for workout: \(workoutTitle)")

        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities are not enabled by user")
            throw LiveActivityError.notEnabled
        }

        // End any existing activity before starting a new one
        if currentActivity != nil {
            await endActivity()
        }

        // Define static attributes
        let attributes = WorkoutActivityAttributes(
            workoutTitle: workoutTitle,
            totalExercises: totalExercises
        )

        // Define initial dynamic state
        let initialState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: initialExerciseName,
            currentSeries: "1/1",
            restTimerSeconds: nil,
            totalWorkoutTime: "00:00",
            canGoToNextExercise: false,
            completionPercentage: 0,
            workoutState: .active
        )

        do {
            // Request the Live Activity
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            logger.info("Live Activity started successfully with ID: \(self.currentActivity?.id ?? "unknown")")
        } catch {
            logger.error("Failed to start Live Activity: \(error.localizedDescription)")
            throw LiveActivityError.failedToStart(underlying: error)
        }
    }

    /// Updates the Live Activity with new workout state
    /// - Parameters:
    ///   - exerciseName: Current exercise name
    ///   - series: Current series progress (e.g., "2/4")
    ///   - restSeconds: Optional rest timer countdown in seconds
    ///   - totalTime: Total workout time formatted string
    ///   - canGoNext: Whether user can advance to next exercise
    ///   - completionPercentage: Workout completion percentage (0-100)
    ///   - workoutState: Current workout state (active, resting, paused)
    func updateActivity(
        exerciseName: String,
        series: String,
        restSeconds: Int? = nil,
        totalTime: String,
        canGoNext: Bool,
        completionPercentage: Int,
        workoutState: WorkoutActivityAttributes.ContentState.WorkoutState
    ) async {
        guard let activity = currentActivity else {
            logger.warning("Attempted to update Live Activity but none is active")
            return
        }

        let updatedState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: exerciseName,
            currentSeries: series,
            restTimerSeconds: restSeconds,
            totalWorkoutTime: totalTime,
            canGoToNextExercise: canGoNext,
            completionPercentage: completionPercentage,
            workoutState: workoutState
        )

        let updatedContent = ActivityContent(
            state: updatedState,
            staleDate: nil
        )

        do {
            await activity.update(updatedContent)
            logger.debug("Live Activity updated: \(exerciseName) - \(series)")
        } catch {
            logger.error("Failed to update Live Activity: \(error.localizedDescription)")
        }
    }

    /// Ends the current Live Activity
    /// - Parameter dismissalPolicy: When to dismiss the activity (default: immediate)
    func endActivity(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) async {
        guard let activity = currentActivity else {
            logger.debug("No active Live Activity to end")
            return
        }

        logger.info("Ending Live Activity with ID: \(activity.id)")

        let finalState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: "Workout Complete",
            currentSeries: "",
            restTimerSeconds: nil,
            totalWorkoutTime: activity.content.state.totalWorkoutTime,
            canGoToNextExercise: false,
            completionPercentage: 100,
            workoutState: .active
        )

        let finalContent = ActivityContent(
            state: finalState,
            staleDate: nil
        )

        await activity.end(finalContent, dismissalPolicy: dismissalPolicy)
        currentActivity = nil

        logger.info("Live Activity ended successfully")
    }

    // MARK: - Helper Methods

    /// Checks if a Live Activity is currently active
    var isActivityActive: Bool {
        currentActivity != nil
    }
}

// MARK: - Error Types

enum LiveActivityError: LocalizedError {
    case notEnabled
    case failedToStart(underlying: Error)
    case failedToUpdate(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notEnabled:
            return "Live Activities are not enabled. Please enable them in Settings."
        case .failedToStart(let error):
            return "Failed to start Live Activity: \(error.localizedDescription)"
        case .failedToUpdate(let error):
            return "Failed to update Live Activity: \(error.localizedDescription)"
        }
    }
}
