//
//  UnifiedWorkoutSession.swift
//  FitToday
//
//  Represents a completed workout session that unifies app and HealthKit data.
//

import Foundation

/// Represents a completed exercise within a unified workout session.
/// Named `SessionExercise` to avoid conflict with `CompletedExercise` in WorkoutRating.swift.
struct SessionExercise: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let exerciseId: String
    let exerciseName: String
    let sets: [SessionSet]
    let duration: TimeInterval?
    let notes: String?

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    init(
        id: UUID = UUID(),
        exerciseId: String,
        exerciseName: String,
        sets: [SessionSet] = [],
        duration: TimeInterval? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sets = sets
        self.duration = duration
        self.notes = notes
    }
}

/// Represents a completed set within a session exercise.
struct SessionSet: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let setNumber: Int
    let reps: Int
    let weight: Double
    let isWarmup: Bool
    let completedAt: Date

    var volume: Double {
        Double(reps) * weight
    }

    init(
        id: UUID = UUID(),
        setNumber: Int,
        reps: Int,
        weight: Double,
        isWarmup: Bool = false,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.isWarmup = isWarmup
        self.completedAt = completedAt
    }
}

/// Contribution to a challenge from this workout.
struct ChallengeContribution: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let challengeId: String
    let contributionType: ChallengeContributionType
    let value: Double
    let syncedAt: Date

    init(
        id: UUID = UUID(),
        challengeId: String,
        contributionType: ChallengeContributionType,
        value: Double,
        syncedAt: Date = Date()
    ) {
        self.id = id
        self.challengeId = challengeId
        self.contributionType = contributionType
        self.value = value
        self.syncedAt = syncedAt
    }
}

/// Type of contribution to a challenge.
enum ChallengeContributionType: String, Codable, Sendable {
    case workoutCount
    case totalVolume
    case totalDuration
    case totalSets
}

/// Unified workout session that combines app and HealthKit data.
/// Uses `WorkoutSource` from HistoryModels.swift.
struct UnifiedWorkoutSession: Identifiable, Codable, Sendable {
    let id: String
    let userId: String
    var name: String
    var templateId: String?
    var programId: String?
    var startedAt: Date
    var completedAt: Date?
    var duration: TimeInterval
    var totalVolume: Double
    var totalSets: Int
    var totalReps: Int
    var caloriesBurned: Double?
    var avgHeartRate: Double?
    var exercises: [SessionExercise]
    var source: WorkoutSource
    var healthKitId: UUID?
    var challengeContributions: [ChallengeContribution]

    /// Creates a new session from app workout.
    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        templateId: String? = nil,
        programId: String? = nil,
        startedAt: Date,
        completedAt: Date? = nil,
        exercises: [SessionExercise] = [],
        source: WorkoutSource = .app,
        healthKitId: UUID? = nil,
        challengeContributions: [ChallengeContribution] = []
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.templateId = templateId
        self.programId = programId
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.duration = completedAt?.timeIntervalSince(startedAt) ?? 0
        self.exercises = exercises
        self.totalVolume = exercises.reduce(0) { $0 + $1.totalVolume }
        self.totalSets = exercises.reduce(0) { $0 + $1.sets.count }
        self.totalReps = exercises.reduce(0) { $0 + $1.totalReps }
        self.caloriesBurned = nil
        self.avgHeartRate = nil
        self.source = source
        self.healthKitId = healthKitId
        self.challengeContributions = challengeContributions
    }

    /// Whether the session is currently in progress.
    var isInProgress: Bool {
        completedAt == nil
    }

    /// Formatted duration string.
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }

    /// Formatted volume string (in kg).
    var formattedVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1f ton", totalVolume / 1000)
        } else {
            return String(format: "%.0f kg", totalVolume)
        }
    }
}

// MARK: - Hashable

extension UnifiedWorkoutSession: Hashable {
    static func == (lhs: UnifiedWorkoutSession, rhs: UnifiedWorkoutSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
