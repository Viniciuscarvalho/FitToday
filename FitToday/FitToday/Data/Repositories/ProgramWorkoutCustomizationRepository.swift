//
//  ProgramWorkoutCustomizationRepository.swift
//  FitToday
//
//  Repository for storing user customizations of program workouts (exercise order, deletions).
//

import Foundation

// MARK: - Customization Model

/// Stores user customizations for a program workout.
struct ProgramWorkoutCustomization: Codable, Sendable {
    let workoutId: String
    /// Ordered list of exercise IDs after user customization.
    var exerciseOrder: [String]
    /// IDs of exercises that were deleted by the user.
    var deletedExerciseIds: Set<String>
    /// Last modified date.
    var lastModified: Date

    init(workoutId: String, exerciseOrder: [String] = [], deletedExerciseIds: Set<String> = []) {
        self.workoutId = workoutId
        self.exerciseOrder = exerciseOrder
        self.deletedExerciseIds = deletedExerciseIds
        self.lastModified = Date()
    }
}

// MARK: - Protocol

/// Protocol for storing and retrieving program workout customizations.
protocol ProgramWorkoutCustomizationRepositoryProtocol: Sendable {
    /// Saves customization for a workout.
    func saveCustomization(_ customization: ProgramWorkoutCustomization) async

    /// Gets customization for a workout, if any.
    func getCustomization(for workoutId: String) async -> ProgramWorkoutCustomization?

    /// Removes customization for a workout (resets to default).
    func removeCustomization(for workoutId: String) async

    /// Removes all customizations.
    func clearAllCustomizations() async
}

// MARK: - Implementation

/// UserDefaults-based implementation for storing program workout customizations.
actor UserDefaultsProgramWorkoutCustomizationRepository: ProgramWorkoutCustomizationRepositoryProtocol {
    private let userDefaults: UserDefaults
    private let storageKey = "program_workout_customizations"

    private var cache: [String: ProgramWorkoutCustomization] = [:]
    private var isLoaded = false

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func saveCustomization(_ customization: ProgramWorkoutCustomization) async {
        await loadIfNeeded()

        var updatedCustomization = customization
        updatedCustomization.lastModified = Date()
        cache[customization.workoutId] = updatedCustomization

        await persist()

        #if DEBUG
        print("[ProgramCustomization] 💾 Saved customization for workout: \(customization.workoutId)")
        #endif
    }

    func getCustomization(for workoutId: String) async -> ProgramWorkoutCustomization? {
        await loadIfNeeded()
        return cache[workoutId]
    }

    func removeCustomization(for workoutId: String) async {
        await loadIfNeeded()
        cache.removeValue(forKey: workoutId)
        await persist()

        #if DEBUG
        print("[ProgramCustomization] 🗑️ Removed customization for workout: \(workoutId)")
        #endif
    }

    func clearAllCustomizations() async {
        cache.removeAll()
        await persist()

        #if DEBUG
        print("[ProgramCustomization] 🧹 Cleared all customizations")
        #endif
    }

    // MARK: - Private Helpers

    private func loadIfNeeded() async {
        guard !isLoaded else { return }

        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: ProgramWorkoutCustomization].self, from: data) {
            cache = decoded
        }

        isLoaded = true

        #if DEBUG
        print("[ProgramCustomization] 📂 Loaded \(cache.count) customizations from storage")
        #endif
    }

    private func persist() async {
        if let encoded = try? JSONEncoder().encode(cache) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
}
