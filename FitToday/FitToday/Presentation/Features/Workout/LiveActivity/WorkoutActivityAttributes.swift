import ActivityKit
import Foundation

/// Attributes for the Workout Live Activity
/// Defines the static and dynamic content shown in the Live Activity
struct WorkoutActivityAttributes: ActivityAttributes {
    /// Static content that doesn't change during the activity
    public struct ContentState: Codable, Hashable, Sendable {
        /// Current exercise name being performed
        var currentExerciseName: String

        /// Current series progress (e.g., "2/4" for second out of four series)
        var currentSeries: String

        /// Rest timer countdown in seconds (nil if not in rest period)
        var restTimerSeconds: Int?

        /// Total workout duration formatted as string (e.g., "12:34")
        var totalWorkoutTime: String

        /// Whether the user can advance to the next exercise
        var canGoToNextExercise: Bool

        /// Workout completion percentage (0-100)
        var completionPercentage: Int

        /// Current workout state (active, resting, paused)
        var workoutState: WorkoutState

        enum WorkoutState: String, Codable, Sendable {
            case active = "Active"
            case resting = "Resting"
            case paused = "Paused"
        }
    }

    /// Workout title that remains constant throughout the activity
    var workoutTitle: String

    /// Total number of exercises in the workout
    var totalExercises: Int
}
