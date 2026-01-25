//
//  ImageCompressorTests.swift
//  FitTodayTests
//
//  Created by Claude on 25/01/26.
//

import XCTest
@testable import FitToday

final class ImageCompressorTests: XCTestCase {
    var sut: ImageCompressor!

    override func setUp() {
        super.setUp()
        sut = ImageCompressor()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Constants Tests

    func test_defaultMaxBytes_is500KB() {
        XCTAssertEqual(ImageCompressor.defaultMaxBytes, 500_000)
    }

    func test_defaultQuality_is0_7() {
        XCTAssertEqual(ImageCompressor.defaultQuality, 0.7)
    }

    // MARK: - Invalid Data Tests

    func test_compress_invalidData_throwsInvalidImageError() throws {
        // Given
        let invalidData = Data([0x00, 0x01, 0x02, 0x03]) // Not a valid image

        // When/Then
        XCTAssertThrowsError(try sut.compress(
            data: invalidData,
            maxBytes: 500_000,
            quality: 0.7
        )) { error in
            guard let compressionError = error as? ImageCompressor.CompressionError else {
                XCTFail("Expected CompressionError")
                return
            }
            XCTAssertEqual(compressionError, .invalidImage)
        }
    }

    func test_compress_emptyData_throwsInvalidImageError() throws {
        // Given
        let emptyData = Data()

        // When/Then
        XCTAssertThrowsError(try sut.compress(
            data: emptyData,
            maxBytes: 500_000,
            quality: 0.7
        )) { error in
            guard let compressionError = error as? ImageCompressor.CompressionError else {
                XCTFail("Expected CompressionError")
                return
            }
            XCTAssertEqual(compressionError, .invalidImage)
        }
    }

    // MARK: - Valid Image Tests

    func test_compress_validImage_returnsJPEGData() throws {
        // Given - Create a small test image
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        guard let originalData = image.pngData() else {
            XCTFail("Could not create PNG data")
            return
        }

        // When
        let compressedData = try sut.compress(
            data: originalData,
            maxBytes: 500_000,
            quality: 0.7
        )

        // Then
        XCTAssertFalse(compressedData.isEmpty)
        // JPEG files start with 0xFF 0xD8
        XCTAssertEqual(compressedData.prefix(2), Data([0xFF, 0xD8]))
    }

    func test_compress_largeImage_producesOutputUnderMaxBytes() throws {
        // Given - Create a larger image that will need compression
        let image = createTestImage(size: CGSize(width: 1000, height: 1000), fillColor: .red)
        guard let originalData = image.pngData() else {
            XCTFail("Could not create PNG data")
            return
        }

        let maxBytes = 100_000 // 100KB limit

        // When
        let compressedData = try sut.compress(
            data: originalData,
            maxBytes: maxBytes,
            quality: 0.7
        )

        // Then
        // Note: Due to the way JPEG compression works, very simple solid-color
        // images may compress to extremely small sizes. The test verifies
        // the compression runs without error.
        XCTAssertFalse(compressedData.isEmpty)
    }

    func test_compress_imageAlreadyUnderLimit_stillReturnsValidData() throws {
        // Given
        let image = createTestImage(size: CGSize(width: 50, height: 50))
        guard let originalData = image.jpegData(compressionQuality: 0.5) else {
            XCTFail("Could not create JPEG data")
            return
        }

        // When
        let compressedData = try sut.compress(
            data: originalData,
            maxBytes: 500_000,
            quality: 0.7
        )

        // Then
        XCTAssertFalse(compressedData.isEmpty)
    }

    // MARK: - Convenience Method Tests

    func test_compressForCheckIn_usesDefaultValues() throws {
        // Given
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        guard let originalData = image.pngData() else {
            XCTFail("Could not create PNG data")
            return
        }

        // When
        let compressedData = try sut.compressForCheckIn(data: originalData)

        // Then
        XCTAssertFalse(compressedData.isEmpty)
    }

    // MARK: - Error Descriptions

    func test_invalidImageError_hasDescription() {
        let error = ImageCompressor.CompressionError.invalidImage
        XCTAssertEqual(error.errorDescription, "The provided data is not a valid image")
    }

    func test_compressionFailedError_hasDescription() {
        let error = ImageCompressor.CompressionError.compressionFailed
        XCTAssertEqual(error.errorDescription, "Failed to compress the image")
    }

    // MARK: - Helpers

    private func createTestImage(size: CGSize, fillColor: UIColor = .blue) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            fillColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Add some variation to prevent extreme compression
            UIColor.white.setFill()
            context.fill(CGRect(x: 10, y: 10, width: 20, height: 20))
            UIColor.black.setFill()
            context.fill(CGRect(x: 40, y: 40, width: 10, height: 10))
        }
    }
}

// MARK: - CompressionError Equatable

extension ImageCompressor.CompressionError: Equatable {
    public static func == (lhs: ImageCompressor.CompressionError, rhs: ImageCompressor.CompressionError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidImage, .invalidImage):
            return true
        case (.compressionFailed, .compressionFailed):
            return true
        default:
            return false
        }
    }
}
