//
//  WgerExerciseCacheManager.swift
//  FitToday
//
//  Manages persistent caching for Wger exercise data.
//

@preconcurrency import Foundation

/// Manages persistent file-based caching for Wger exercise data.
/// Uses actor isolation for thread safety.
actor WgerExerciseCacheManager {
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let configuration: WgerConfiguration

    /// Subdirectory names for organizing cached data.
    private enum CacheDirectory: String {
        case exercises
        case images
        case metadata
    }

    init(configuration: WgerConfiguration = .default) throws {
        self.fileManager = .default
        self.configuration = configuration

        // Create cache directory in app's caches folder
        let cachesURL = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        self.cacheDirectory = cachesURL.appendingPathComponent("WgerCache", isDirectory: true)

        // Ensure cache directory exists
        try createDirectoryIfNeeded(at: cacheDirectory)
        for subdir in [CacheDirectory.exercises, .images, .metadata] {
            try createDirectoryIfNeeded(at: cacheDirectory.appendingPathComponent(subdir.rawValue))
        }
    }

    // MARK: - Exercises

    /// Caches a list of exercises.
    func cacheExercises(_ exercises: [WgerExercise], forLanguage language: WgerLanguageCode) throws {
        let url = exercisesCacheURL(for: language)
        let data = try JSONEncoder().encode(exercises)
        try data.write(to: url)

        // Update metadata with timestamp
        try updateMetadata(key: "exercises_\(language.rawValue)", date: Date())

        #if DEBUG
        print("[WgerCache] Cached \(exercises.count) exercises for language \(language.code)")
        #endif
    }

    /// Retrieves cached exercises if available and not expired.
    func getCachedExercises(forLanguage language: WgerLanguageCode) -> [WgerExercise]? {
        let url = exercisesCacheURL(for: language)

        guard fileManager.fileExists(atPath: url.path),
              let cachedDate = getMetadata(key: "exercises_\(language.rawValue)"),
              !isCacheExpired(cachedDate) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let exercises = try JSONDecoder().decode([WgerExercise].self, from: data)
            #if DEBUG
            print("[WgerCache] Cache hit: \(exercises.count) exercises for language \(language.code)")
            #endif
            return exercises
        } catch {
            #if DEBUG
            print("[WgerCache] Failed to read exercises cache: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Images

    /// Caches image data for an exercise.
    func cacheImage(_ data: Data, forExerciseId exerciseId: Int, isMain: Bool) throws {
        let suffix = isMain ? "main" : "secondary"
        let url = imagesCacheURL(for: exerciseId, suffix: suffix)
        try data.write(to: url)

        #if DEBUG
        print("[WgerCache] Cached image for exercise \(exerciseId) (\(suffix))")
        #endif
    }

    /// Retrieves cached image data for an exercise.
    func getCachedImage(forExerciseId exerciseId: Int, isMain: Bool) -> Data? {
        let suffix = isMain ? "main" : "secondary"
        let url = imagesCacheURL(for: exerciseId, suffix: suffix)

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        return try? Data(contentsOf: url)
    }

    // MARK: - Categories & Equipment

    /// Caches categories list.
    func cacheCategories(_ categories: [WgerCategory]) throws {
        let url = cacheDirectory
            .appendingPathComponent(CacheDirectory.metadata.rawValue)
            .appendingPathComponent("categories.json")
        let data = try JSONEncoder().encode(categories)
        try data.write(to: url)
        try updateMetadata(key: "categories", date: Date())
    }

    /// Retrieves cached categories.
    func getCachedCategories() -> [WgerCategory]? {
        let url = cacheDirectory
            .appendingPathComponent(CacheDirectory.metadata.rawValue)
            .appendingPathComponent("categories.json")

        guard fileManager.fileExists(atPath: url.path),
              let cachedDate = getMetadata(key: "categories"),
              !isCacheExpired(cachedDate) else {
            return nil
        }

        return try? JSONDecoder().decode([WgerCategory].self, from: Data(contentsOf: url))
    }

    /// Caches equipment list.
    func cacheEquipment(_ equipment: [WgerEquipment]) throws {
        let url = cacheDirectory
            .appendingPathComponent(CacheDirectory.metadata.rawValue)
            .appendingPathComponent("equipment.json")
        let data = try JSONEncoder().encode(equipment)
        try data.write(to: url)
        try updateMetadata(key: "equipment", date: Date())
    }

    /// Retrieves cached equipment.
    func getCachedEquipment() -> [WgerEquipment]? {
        let url = cacheDirectory
            .appendingPathComponent(CacheDirectory.metadata.rawValue)
            .appendingPathComponent("equipment.json")

        guard fileManager.fileExists(atPath: url.path),
              let cachedDate = getMetadata(key: "equipment"),
              !isCacheExpired(cachedDate) else {
            return nil
        }

        return try? JSONDecoder().decode([WgerEquipment].self, from: Data(contentsOf: url))
    }

    // MARK: - Cache Management

    /// Clears all expired cache entries.
    func clearExpiredCache() throws {
        let metadata = getAllMetadata()
        var keysToRemove: [String] = []

        for (key, date) in metadata {
            if isCacheExpired(date) {
                keysToRemove.append(key)
            }
        }

        // Remove expired exercise caches
        for key in keysToRemove where key.hasPrefix("exercises_") {
            let languageId = key.replacingOccurrences(of: "exercises_", with: "")
            if let langId = Int(languageId),
               let language = WgerLanguageCode(rawValue: langId) {
                let url = exercisesCacheURL(for: language)
                try? fileManager.removeItem(at: url)
            }
        }

        // Update metadata to remove expired keys
        try clearMetadata(keys: keysToRemove)

        #if DEBUG
        print("[WgerCache] Cleared \(keysToRemove.count) expired cache entries")
        #endif
    }

    /// Clears all cache data.
    func clearAllCache() throws {
        try fileManager.removeItem(at: cacheDirectory)
        try createDirectoryIfNeeded(at: cacheDirectory)
        for subdir in [CacheDirectory.exercises, .images, .metadata] {
            try createDirectoryIfNeeded(at: cacheDirectory.appendingPathComponent(subdir.rawValue))
        }

        #if DEBUG
        print("[WgerCache] Cleared all cache")
        #endif
    }

    /// Returns the total size of the cache in bytes.
    func cacheSize() -> Int {
        var totalSize = 0

        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += fileSize
                }
            }
        }

        return totalSize
    }

    // MARK: - Private Helpers

    private func exercisesCacheURL(for language: WgerLanguageCode) -> URL {
        cacheDirectory
            .appendingPathComponent(CacheDirectory.exercises.rawValue)
            .appendingPathComponent("exercises_\(language.rawValue).json")
    }

    private func imagesCacheURL(for exerciseId: Int, suffix: String) -> URL {
        cacheDirectory
            .appendingPathComponent(CacheDirectory.images.rawValue)
            .appendingPathComponent("\(exerciseId)_\(suffix).jpg")
    }

    private func metadataURL() -> URL {
        cacheDirectory
            .appendingPathComponent(CacheDirectory.metadata.rawValue)
            .appendingPathComponent("metadata.json")
    }

    private func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func isCacheExpired(_ date: Date) -> Bool {
        Date().timeIntervalSince(date) > configuration.cacheTTL
    }

    private func updateMetadata(key: String, date: Date) throws {
        var metadata = getAllMetadata()
        metadata[key] = date
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL())
    }

    private func getMetadata(key: String) -> Date? {
        getAllMetadata()[key]
    }

    private func getAllMetadata() -> [String: Date] {
        let url = metadataURL()
        guard let data = try? Data(contentsOf: url),
              let metadata = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        return metadata
    }

    private func clearMetadata(keys: [String]) throws {
        var metadata = getAllMetadata()
        for key in keys {
            metadata.removeValue(forKey: key)
        }
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL())
    }
}
