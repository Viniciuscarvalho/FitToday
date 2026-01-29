//
//  ExerciseDBCompat.swift
//  FitToday
//
//  Compatibility layer for ExerciseDB types that were removed.
//  This allows code that referenced ExerciseDB to compile while
//  the migration to Wger API is completed.
//

import Foundation

// MARK: - Image Resolution

/// Image resolution options (previously used by ExerciseDB).
enum ExerciseImageResolution: String, Sendable {
    case r360 = "360"
    case r720 = "720"
}

// MARK: - Media Display Context

/// Context for displaying exercise media.
enum MediaDisplayContext: Sendable {
    case thumbnail
    case detail
    case fullScreen

    var resolution: ExerciseImageResolution {
        switch self {
        case .thumbnail: return .r360
        case .detail, .fullScreen: return .r720
        }
    }
}

// MARK: - ExerciseDB Exercise (Stub)

/// Stub type for ExerciseDB exercises during migration.
/// Use Wger API types directly for new code.
struct ExerciseDBExercise: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let target: String?
    let bodyPart: String?
    let equipment: String?
    let gifUrl: String?
    let instructions: [String]?

    var gifURL: URL? {
        gifUrl.flatMap { URL(string: $0) }
    }
}

// MARK: - ExerciseDB Servicing Protocol (Stub)

/// Stub protocol for ExerciseDB service.
/// Use WgerAPIService/ExerciseServiceProtocol for new code.
protocol ExerciseDBServicing: Sendable {
    func fetchExercise(byId id: String) async throws -> ExerciseDBExercise?
    func searchExercises(query: String, limit: Int) async throws -> [ExerciseDBExercise]
    func fetchImageURL(exerciseId: String, resolution: ExerciseImageResolution) async throws -> URL?
    func fetchImageData(exerciseId: String, resolution: ExerciseImageResolution) async throws -> (data: Data, mimeType: String)?
    func fetchTargetList() async throws -> [String]
    func fetchExercises(target: String, limit: Int) async throws -> [ExerciseDBExercise]
}

// MARK: - ExerciseDB Error

/// Errors that can occur when using ExerciseDB (stub for compatibility).
enum ExerciseDBError: Error {
    case notFound
    case networkError(Error)
}

// MARK: - Exercise Media Resolver (Stub)

/// Stub for ExerciseMediaResolver used in previews.
/// Use direct URL loading for new code.
struct ExerciseMediaResolver: Sendable {
    let service: ExerciseDBServicing?

    init(service: ExerciseDBServicing?) {
        self.service = service
    }

    func resolveMedia(for exerciseId: String) async -> ExerciseMedia? {
        nil
    }
}

// MARK: - No-Op ExerciseDB Service

/// No-op implementation for previews and testing.
final class NoOpExerciseDBService: ExerciseDBServicing, @unchecked Sendable {
    func fetchExercise(byId id: String) async throws -> ExerciseDBExercise? { nil }
    func searchExercises(query: String, limit: Int) async throws -> [ExerciseDBExercise] { [] }
    func fetchImageURL(exerciseId: String, resolution: ExerciseImageResolution) async throws -> URL? { nil }
    func fetchImageData(exerciseId: String, resolution: ExerciseImageResolution) async throws -> (data: Data, mimeType: String)? { nil }
    func fetchTargetList() async throws -> [String] { [] }
    func fetchExercises(target: String, limit: Int) async throws -> [ExerciseDBExercise] { [] }
}
