//
//  ExerciseServiceProtocols.swift
//  FitToday
//
//  Protocols for exercise name normalization and media resolution.
//  Created on 29/01/26 - Simplified after ExerciseDB removal.
//

import Foundation

// MARK: - Exercise Name Normalizing

/// Protocol for normalizing exercise names for matching.
protocol ExerciseNameNormalizing: Sendable {
    /// Normalizes an exercise name for comparison/matching.
    /// - Parameters:
    ///   - exerciseName: The exercise name to normalize
    ///   - equipment: Optional equipment context
    ///   - muscleGroup: Optional muscle group context
    /// - Returns: Normalized exercise name
    func normalize(exerciseName: String, equipment: String?, muscleGroup: String?) async throws -> String
}

/// No-op implementation that returns the original name.
struct NoOpExerciseNameNormalizer: ExerciseNameNormalizing, Sendable {
    func normalize(exerciseName: String, equipment: String?, muscleGroup: String?) async throws -> String {
        exerciseName
    }
}

/// Simple normalizer that lowercases and removes special characters.
struct SimpleExerciseNameNormalizer: ExerciseNameNormalizing, Sendable {
    func normalize(exerciseName: String, equipment: String?, muscleGroup: String?) async throws -> String {
        exerciseName
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Exercise Media Resolving

/// Source of resolved media.
enum ResolvedMediaSource: String, Sendable {
    case local
    case api
    case cache
}

/// Resolved media result.
struct ResolvedMedia: Sendable {
    let imageURL: URL?
    let gifURL: URL?
    let source: ResolvedMediaSource

    var hasMedia: Bool {
        imageURL != nil || gifURL != nil
    }

    static let empty = ResolvedMedia(imageURL: nil, gifURL: nil, source: .local)
}

/// Context for media resolution.
enum MediaResolutionContext: Sendable {
    case thumbnail
    case detail
    case card
}

/// Protocol for resolving exercise media.
protocol ExerciseMediaResolving: Sendable {
    /// Resolves media for an exercise.
    func resolveMedia(for exercise: WorkoutExercise, context: MediaResolutionContext) async -> ResolvedMedia
}

/// No-op implementation that returns empty media.
struct NoOpExerciseMediaResolver: ExerciseMediaResolving, Sendable {
    func resolveMedia(for exercise: WorkoutExercise, context: MediaResolutionContext) async -> ResolvedMedia {
        // Return existing media if available
        if let media = exercise.media {
            return ResolvedMedia(
                imageURL: media.imageURL,
                gifURL: media.gifURL,
                source: .local
            )
        }
        return .empty
    }
}
