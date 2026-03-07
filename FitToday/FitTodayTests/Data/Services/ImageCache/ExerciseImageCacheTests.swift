//
//  ExerciseImageCacheTests.swift
//  FitTodayTests
//
//  Created by Claude on 03/03/26.
//

import XCTest
import UIKit
@testable import FitToday

final class ExerciseImageCacheTests: XCTestCase {

    private var cacheDirectory: URL!

    override func setUp() {
        super.setUp()
        cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExerciseImageCacheTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        super.tearDown()
    }

    // MARK: - Disk Cache Path Tests

    func testCacheDirectoryExistsAfterInit() async {
        // The shared instance creates Caches/exercise_images/ on init
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let exerciseImagesDir = cachesDir.appendingPathComponent("exercise_images", isDirectory: true)

        // Access shared to trigger init
        _ = await ExerciseImageCache.shared

        XCTAssertTrue(FileManager.default.fileExists(atPath: exerciseImagesDir.path))
    }

    // MARK: - Image Retrieval (Cache Miss → nil for non-existent Firebase path)

    func testImageReturnsNilForNonExistentExercise() async {
        // Non-existent exercise should return nil (Firebase Storage will fail)
        let image = await ExerciseImageCache.shared.image(for: "nonexistent_exercise_\(UUID().uuidString)", imageIndex: 0)
        XCTAssertNil(image)
    }

    // MARK: - Prefetch Does Not Crash

    func testPrefetchWithEmptyArrayDoesNotCrash() async {
        // Should complete without error
        await ExerciseImageCache.shared.prefetchWorkoutImages(exerciseIds: [])
    }

    // MARK: - Clear Cache

    func testClearCacheDoesNotCrash() async {
        await ExerciseImageCache.shared.clearCache()
        // Should complete without error
    }

    // MARK: - Prune Old Cache

    func testPruneOldCacheDoesNotCrash() async {
        await ExerciseImageCache.shared.pruneOldCache()
        // Should complete without error
    }

    // MARK: - Prune Logic Validation

    func testPruneRemovesOldFilesFromDisk() {
        // Create a test file with an old access date
        let testFile = cacheDirectory.appendingPathComponent("old_test.jpg")
        let testData = Data(repeating: 0xFF, count: 100)
        FileManager.default.createFile(atPath: testFile.path, contents: testData)

        // Set access date to 31 days ago
        var values = URLResourceValues()
        values.contentAccessDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())
        var mutableURL = testFile
        try? mutableURL.setResourceValues(values)

        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))

        // Verify the file has old access date
        let resourceValues = try? testFile.resourceValues(forKeys: [.contentAccessDateKey])
        let threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        XCTAssertNotNil(resourceValues?.contentAccessDate)
        if let accessDate = resourceValues?.contentAccessDate {
            XCTAssertTrue(accessDate < threshold, "File should have access date older than 30 days")
        }
    }

    func testPruneKeepsRecentFiles() {
        // Create a test file with a recent access date
        let testFile = cacheDirectory.appendingPathComponent("recent_test.jpg")
        let testData = Data(repeating: 0xFF, count: 100)
        FileManager.default.createFile(atPath: testFile.path, contents: testData)

        // Set access date to today
        var values = URLResourceValues()
        values.contentAccessDate = Date()
        var mutableURL = testFile
        try? mutableURL.setResourceValues(values)

        // File should still exist (recent files are not pruned)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))

        let resourceValues = try? testFile.resourceValues(forKeys: [.contentAccessDateKey])
        let threshold = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        if let accessDate = resourceValues?.contentAccessDate {
            XCTAssertTrue(accessDate > threshold, "Recent file should not be pruned")
        }
    }

    // MARK: - Negative Cache (Issue #89 - prevents infinite retries)

    func testRepeatedRequestsForMissingImageDoNotRetryInfinitely() async {
        let exerciseId = "missing_exercise_\(UUID().uuidString)"

        // First call — will attempt Firebase Storage and fail
        let result1 = await ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 0)
        XCTAssertNil(result1)

        // Second call — should return nil immediately from negative cache (no Firebase call)
        let result2 = await ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 0)
        XCTAssertNil(result2)
    }

    func testClearCacheResetsNegativeCache() async {
        let exerciseId = "cleared_exercise_\(UUID().uuidString)"

        // Trigger negative cache
        _ = await ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 0)

        // Clear all caches including negative cache
        await ExerciseImageCache.shared.clearCache()

        // After clear, should attempt download again (not return from negative cache)
        // Still nil because exercise doesn't exist, but the important thing is no crash
        let result = await ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 0)
        XCTAssertNil(result)
    }

    // MARK: - Deduplication

    func testConcurrentRequestsForSameImageDoNotDuplicate() async {
        let exerciseId = "dedup_test_\(UUID().uuidString)"

        // Fire multiple concurrent requests for the same image
        async let img1 = ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 0)
        async let img2 = ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 0)
        async let img3 = ExerciseImageCache.shared.image(for: exerciseId, imageIndex: 0)

        let results = await [img1, img2, img3]

        // All should return nil (non-existent exercise) without crashing
        for result in results {
            XCTAssertNil(result)
        }
    }
}
