//
//  FirebaseStorageService.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import FirebaseStorage
import Foundation

// MARK: - StorageError

/// Errors that can occur during storage operations.
enum StorageError: Error, LocalizedError {
    case uploadFailed(path: String, underlyingError: Error)
    case deleteFailed(path: String, underlyingError: Error)
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .uploadFailed(let path, let error):
            return "Falha ao enviar arquivo para '\(path)': \(error.localizedDescription)"
        case .deleteFailed(let path, let error):
            return "Falha ao deletar arquivo '\(path)': \(error.localizedDescription)"
        case .invalidConfiguration:
            return "Configuração do Firebase Storage inválida"
        }
    }
}

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

        #if DEBUG
        print("[Storage] 📤 Uploading image to: \(path) (\(data.count / 1024) KB)")
        print("[Storage] 📦 Storage bucket: \(storage.reference().bucket)")
        #endif

        do {
            // Upload the data and wait for completion
            let uploadResult = try await ref.putDataAsync(data, metadata: metadata)

            #if DEBUG
            print("[Storage] 📤 Upload metadata returned - path: \(uploadResult.path ?? "nil")")
            #endif

            // Get the download URL from the same reference we uploaded to
            let url = try await ref.downloadURL()

            #if DEBUG
            print("[Storage] ✅ Upload successful: \(url.absoluteString.prefix(80))...")
            #endif

            return url
        } catch let error as NSError {
            #if DEBUG
            print("[Storage] ❌ Upload failed: \(error.localizedDescription)")
            print("[Storage] Error code: \(error.code)")
            print("[Storage] Error domain: \(error.domain)")
            print("[Storage] Full error: \(error)")

            // Provide more helpful error messages based on error code
            switch error.code {
            case -13010: // Object does not exist
                print("[Storage] ⚠️ Hint: This usually means Firebase Storage rules don't allow writes to this path.")
                print("[Storage] ⚠️ Check your storage.rules file allows: 'write' to '/checkIns/{groupId}/{userId}/{filename}'")
            case -13021: // Unauthenticated
                print("[Storage] ⚠️ Hint: User is not authenticated. Ensure Firebase Auth is configured.")
            case -13000: // Unknown error
                print("[Storage] ⚠️ Hint: Check network connectivity and Firebase configuration.")
            default:
                break
            }
            #endif

            throw StorageError.uploadFailed(
                path: path,
                underlyingError: error
            )
        } catch {
            #if DEBUG
            print("[Storage] ❌ Unexpected error: \(error)")
            #endif
            throw StorageError.uploadFailed(path: path, underlyingError: error)
        }
    }

    func deleteImage(path: String) async throws {
        let ref = storage.reference().child(path)
        try await ref.delete()
    }
}
