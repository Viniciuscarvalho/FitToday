//
//  FirebaseStorageService.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import FirebaseStorage
import Foundation

// MARK: - StorageServicing Protocol

/// Protocol for storage operations.
protocol StorageServicing: Sendable {
    /// Uploads image data to storage at the specified path.
    /// - Parameters:
    ///   - data: The image data to upload (JPEG format expected)
    ///   - path: The storage path where the image will be stored
    /// - Returns: The download URL of the uploaded image
    func uploadImage(data: Data, path: String) async throws -> URL

    /// Deletes an image from storage at the specified path.
    /// - Parameter path: The storage path of the image to delete
    func deleteImage(path: String) async throws
}

// MARK: - FirebaseStorageService

/// Actor-based Firebase Storage service for thread-safe image operations.
actor FirebaseStorageService: StorageServicing {
    private let storage = Storage.storage()

    func uploadImage(data: Data, path: String) async throws -> URL {
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }

    func deleteImage(path: String) async throws {
        let ref = storage.reference().child(path)
        try await ref.delete()
    }
}
