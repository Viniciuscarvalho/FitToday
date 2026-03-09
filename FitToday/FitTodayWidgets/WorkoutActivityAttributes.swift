import ActivityKit
import Foundation

/// Attributes for the Workout Live Activity
/// Shared between main app and widget extension
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        var currentExerciseName: String
        var currentSeries: String
        var restTimerSeconds: Int?
        var totalWorkoutTime: String
        var canGoToNextExercise: Bool
        var completionPercentage: Int
        var workoutState: WorkoutState

        enum WorkoutState: String, Codable, Sendable {
            case active = "Active"
            case resting = "Resting"
            case paused = "Paused"
        }
    }

    var workoutTitle: String
    var totalExercises: Int
}
