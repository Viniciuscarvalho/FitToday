//
//  ExerciseImageCache.swift
//  FitToday
//
//  Created by Claude on 03/03/26.
//

import FirebaseStorage
import Foundation
import UIKit

/// Actor thread-safe para cache de imagens de exercícios do Firebase Storage.
/// Dois níveis: memória (NSCache) + disco (Caches/exercise_images/).
/// Evita downloads duplicados via `downloadTasks`.
actor ExerciseImageCache {
    static let shared = ExerciseImageCache()

    // MARK: - Memory Cache

    private let memoryCache = NSCache<NSString, UIImage>()

    // MARK: - Disk Cache

    private let diskDirectory: URL
    private let fileManager = FileManager.default

    // MARK: - Download Deduplication

    private var downloadTasks: [String: Task<UIImage?, Error>] = [:]

    // MARK: - Negative Cache (prevents infinite retries for missing images)

    private var failedKeys: Set<String> = []

    // MARK: - Configuration

    private let maxDownloadSize: Int64 = 5 * 1024 * 1024 // 5MB
    private let compressionQuality: CGFloat = 0.85
    private let pruneThresholdDays: Int = 30

    // MARK: - Init

    private init() {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskDirectory = cacheDir.appendingPathComponent("exercise_images", isDirectory: true)

        // Create disk directory
        try? fileManager.createDirectory(at: diskDirectory, withIntermediateDirectories: true)

        // Configure memory cache limits
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    // MARK: - Public API

    /// Fetches an exercise image. Checks memory → disk → Firebase Storage.
    /// - Parameters:
    ///   - exerciseId: The exercise identifier
    ///   - imageIndex: The image index (0 or 1)
    /// - Returns: UIImage if found, nil otherwise
    func image(for exerciseId: String, imageIndex: Int = 0) async -> UIImage? {
        let key = cacheKey(exerciseId: exerciseId, imageIndex: imageIndex)

        // 1. Memory cache
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        // 2. Disk cache
        if let diskImage = loadFromDisk(key: key) {
            memoryCache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        }

        // 3. Check negative cache (avoid retrying known-missing images)
        if failedKeys.contains(key) {
            return nil
        }

        // 4. Firebase Storage download (deduplicated)
        return await downloadFromStorage(exerciseId: exerciseId, imageIndex: imageIndex, key: key)
    }

    /// Prefetches images for all exercises in a workout using TaskGroup.
    /// Downloads image 0 and image 1 for each exercise in parallel.
    func prefetchWorkoutImages(exerciseIds: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for exerciseId in exerciseIds {
                group.addTask {
                    _ = await self.image(for: exerciseId, imageIndex: 0)
                }
                group.addTask {
                    _ = await self.image(for: exerciseId, imageIndex: 1)
                }
            }
        }
    }

    /// Removes cache files not accessed in the last 30 days.
    func pruneOldCache() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: diskDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey]
        ) else { return }

        let threshold = Calendar.current.date(byAdding: .day, value: -pruneThresholdDays, to: Date()) ?? Date()

        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.contentAccessDateKey]),
                  let accessDate = values.contentAccessDate else {
                continue
            }
            if accessDate < threshold {
                try? fileManager.removeItem(at: file)
            }
        }

        #if DEBUG
        print("[ExerciseImageCache] pruneOldCache completed")
        #endif
    }

    /// Removes all cached exercise images from memory and disk.
    func clearCache() {
        memoryCache.removeAllObjects()
        failedKeys.removeAll()

        guard let files = try? fileManager.contentsOfDirectory(at: diskDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            try? fileManager.removeItem(at: file)
        }

        #if DEBUG
        print("[ExerciseImageCache] Cache cleared")
        #endif
    }

    // MARK: - Private

    private func cacheKey(exerciseId: String, imageIndex: Int) -> String {
        "\(exerciseId)_\(imageIndex)"
    }

    private func diskPath(for key: String) -> URL {
        diskDirectory.appendingPathComponent("\(key).jpg")
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let path = diskPath(for: key)
        guard fileManager.fileExists(atPath: path.path) else { return nil }

        // Update access time
        var mutableURL = path
        var values = URLResourceValues()
        values.contentAccessDate = Date()
        try? mutableURL.setResourceValues(values)

        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(image: UIImage, key: String) {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return }
        let path = diskPath(for: key)
        try? data.write(to: path, options: .atomic)
    }

    private func downloadFromStorage(exerciseId: String, imageIndex: Int, key: String) async -> UIImage? {
        // Deduplicate: reuse existing download task if in progress
        if let existingTask = downloadTasks[key] {
            return try? await existingTask.value
        }

        let task = Task<UIImage?, Error> {
            let storage = Storage.storage()

            // Try media/ path first (primary), then thumbnail/ as fallback
            let paths = [
                "exercises/\(exerciseId)/media/\(imageIndex).jpg",
                "exercises/\(exerciseId)/thumbnail/\(imageIndex).webp"
            ]

            for storagePath in paths {
                let ref = storage.reference().child(storagePath)
                do {
                    let data = try await ref.data(maxSize: maxDownloadSize)
                    guard let image = UIImage(data: data) else { continue }

                    // Save to both caches
                    memoryCache.setObject(image, forKey: key as NSString)
                    saveToDisk(image: image, key: key)

                    return image
                } catch {
                    #if DEBUG
                    print("[ExerciseImageCache] Path not found: \(storagePath)")
                    #endif
                    continue
                }
            }

            #if DEBUG
            print("[ExerciseImageCache] No image found for exercise: \(exerciseId)")
            #endif
            return nil
        }

        downloadTasks[key] = task
        let result = try? await task.value
        downloadTasks[key] = nil

        // Remember failures to avoid infinite retries
        if result == nil {
            failedKeys.insert(key)
        }

        return result
    }
}
