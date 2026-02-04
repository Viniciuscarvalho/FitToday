//
//  Repositories.swift
//  FitToday
//
//  Created by AI on 03/01/26.
//

import Foundation

protocol UserProfileRepository: Sendable {
    func loadProfile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
}

protocol WorkoutBlocksRepository: Sendable {
    func loadBlocks() async throws -> [WorkoutBlock]
}

protocol WorkoutHistoryRepository: Sendable {
    func listEntries() async throws -> [WorkoutHistoryEntry]
    func listEntries(limit: Int, offset: Int) async throws -> [WorkoutHistoryEntry]
    func count() async throws -> Int
    func saveEntry(_ entry: WorkoutHistoryEntry) async throws
}

protocol EntitlementRepository: Sendable {
    func currentEntitlement() async throws -> ProEntitlement
    func entitlementStream() -> AsyncStream<ProEntitlement>
}

protocol LibraryWorkoutsRepository: Sendable {
    func loadWorkouts() async throws -> [LibraryWorkout]
}

protocol ProgramRepository: Sendable {
    func listPrograms() async throws -> [Program]
    func getProgram(id: String) async throws -> Program?
}

// MARK: - Workout Composition Cache (F7)

/// Cached workout composition entry
struct CachedWorkoutEntry: Sendable {
    let inputsHash: String
    let workoutPlan: WorkoutPlan
    let createdAt: Date
    let expiresAt: Date
    let goal: FitnessGoal
    let structure: TrainingStructure
    let focus: DailyFocus
    let blueprintVersion: String
    let variationSeed: UInt64
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var timeToLive: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }
}

/// Repository for caching workout compositions with 24h TTL
protocol WorkoutCompositionCacheRepository: Sendable {
    /// Retrieve cached workout if valid (not expired)
    func getCachedWorkout(for inputsHash: String) async throws -> CachedWorkoutEntry?
    
    /// Save a workout composition to cache
    func saveCachedWorkout(_ entry: CachedWorkoutEntry) async throws
    
    /// Remove expired entries (cleanup)
    func cleanupExpired() async throws -> Int
    
    /// Clear all cached compositions (DEBUG)
    func clearAll() async throws
    
    /// Get cache statistics (DEBUG)
    func getStats() async throws -> (total: Int, expired: Int, validCount: Int)
}

// MARK: - User Stats Repository

/// Repository for storing and retrieving aggregated user statistics
protocol UserStatsRepository: Sendable {
    /// Fetch current user statistics
    func getCurrentStats() async throws -> UserStats?

    /// Save or update user statistics
    func saveStats(_ stats: UserStats) async throws

    /// Reset all statistics (for testing/debug)
    func resetStats() async throws
}

// MARK: - Saved Routine Repository

/// Repository for managing user's saved routines (up to 5).
/// Routines are programs saved for quick access in "Minhas Rotinas" section.
protocol SavedRoutineRepository: Sendable {
    /// List all saved routines sorted by saved date (most recent first).
    func listRoutines() async throws -> [SavedRoutine]

    /// Save a new routine. Throws if limit is reached.
    func saveRoutine(_ routine: SavedRoutine) async throws

    /// Delete a routine by ID.
    func deleteRoutine(_ id: UUID) async throws

    /// Check if user can save more routines (under the limit).
    func canSaveMore() async -> Bool

    /// Check if a program is already saved as a routine.
    func isRoutineSaved(programId: String) async -> Bool
}