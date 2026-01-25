//
//  ImageCompressor.swift
//  FitToday
//
//  Created by Claude on 25/01/26.
//

import UIKit

// MARK: - ImageCompressing Protocol

/// Protocol for image compression operations.
protocol ImageCompressing: Sendable {
    /// Compresses image data to fit within the specified maximum size.
    /// - Parameters:
    ///   - data: The original image data
    ///   - maxBytes: Maximum allowed size in bytes
    ///   - quality: Initial JPEG compression quality (0.0 to 1.0)
    /// - Returns: Compressed JPEG data within the size limit
    func compress(data: Data, maxBytes: Int, quality: CGFloat) throws -> Data
}

// MARK: - ImageCompressor

/// Image compression service that reduces image size while maintaining quality.
struct ImageCompressor: ImageCompressing {

    // MARK: - Error Types

    enum CompressionError: Error, LocalizedError {
        case invalidImage
        case compressionFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "The provided data is not a valid image"
            case .compressionFailed:
                return "Failed to compress the image"
            }
        }
    }

    // MARK: - Constants

    /// Default maximum size for check-in photos (500KB)
    static let defaultMaxBytes = 500_000

    /// Default initial compression quality
    static let defaultQuality: CGFloat = 0.7

    /// Minimum quality before giving up compression
    private static let minimumQuality: CGFloat = 0.1

    /// Quality reduction step per iteration
    private static let qualityStep: CGFloat = 0.1

    // MARK: - Compression

    func compress(data: Data, maxBytes: Int, quality: CGFloat) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw CompressionError.invalidImage
        }

        var currentQuality = quality
        var compressed = image.jpegData(compressionQuality: currentQuality)

        // Progressively reduce quality until under maxBytes
        while let compressedData = compressed,
              compressedData.count > maxBytes,
              currentQuality > Self.minimumQuality {
            currentQuality -= Self.qualityStep
            compressed = image.jpegData(compressionQuality: max(currentQuality, Self.minimumQuality))
        }

        guard let result = compressed else {
            throw CompressionError.compressionFailed
        }

        return result
    }
}

// MARK: - Convenience Extension

extension ImageCompressor {
    /// Compresses image data using default settings for check-in photos.
    /// - Parameter data: The original image data
    /// - Returns: Compressed JPEG data within 500KB
    func compressForCheckIn(data: Data) throws -> Data {
        try compress(
            data: data,
            maxBytes: Self.defaultMaxBytes,
            quality: Self.defaultQuality
        )
    }
}
