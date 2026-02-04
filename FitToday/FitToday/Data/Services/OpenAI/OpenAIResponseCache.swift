//
//  OpenAIResponseCache.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

actor OpenAIResponseCache {
    struct CachedEntry {
        let payload: Data
        let expiry: Date
        let focus: String?
    }

    private var storage: [String: CachedEntry] = [:]
    private let ttl: TimeInterval
    private var lastFocus: String?

    init(ttl: TimeInterval) {
        self.ttl = ttl
    }

    /// Retrieves cached value, automatically invalidating if focus changed.
    /// - Parameters:
    ///   - key: The cache key
    ///   - focus: The current workout focus (muscle group)
    /// - Returns: Cached data if valid, nil otherwise
    func value(for key: String, focus: String? = nil) -> Data? {
        // Invalidate cache if focus changed
        if let currentFocus = focus, let previousFocus = lastFocus, currentFocus != previousFocus {
            #if DEBUG
            print("[OpenAICache] 🔄 Focus changed from '\(previousFocus)' to '\(currentFocus)' - invalidating cache")
            #endif
            clearForFocusChange()
        }

        // Update last focus
        if let focus = focus {
            lastFocus = focus
        }

        guard let entry = storage[key], entry.expiry > Date() else {
            storage.removeValue(forKey: key)
            #if DEBUG
            if storage[key] != nil {
                print("[OpenAICache] ⏰ Entrada expirada para key: \(key.prefix(20))...")
            }
            #endif
            return nil
        }

        // Additional check: ensure cached entry matches current focus
        if let currentFocus = focus, let entryFocus = entry.focus, entryFocus != currentFocus {
            #if DEBUG
            print("[OpenAICache] ⚠️ Cache entry focus mismatch: cached='\(entryFocus)' current='\(currentFocus)' - invalidating")
            #endif
            storage.removeValue(forKey: key)
            return nil
        }

        #if DEBUG
        let remaining = entry.expiry.timeIntervalSince(Date())
        print("[OpenAICache] ✅ HIT: key=\(key.prefix(20))... TTL=\(Int(remaining))s focus=\(focus ?? "nil")")
        #endif
        return entry.payload
    }

    /// Legacy method for backward compatibility
    func value(for key: String) -> Data? {
        return value(for: key, focus: nil)
    }

    /// Inserts data into cache with optional focus tracking.
    /// - Parameters:
    ///   - data: The data to cache
    ///   - key: The cache key
    ///   - focus: The workout focus associated with this entry
    func insert(_ data: Data, for key: String, focus: String? = nil) {
        let entry = CachedEntry(
            payload: data,
            expiry: Date().addingTimeInterval(ttl),
            focus: focus ?? lastFocus
        )
        storage[key] = entry
        if let focus = focus {
            lastFocus = focus
        }
        #if DEBUG
        print("[OpenAICache] 💾 Salvando: key=\(key.prefix(20))... TTL=\(Int(ttl))s focus=\(focus ?? "nil")")
        #endif
    }

    /// Legacy insert method for backward compatibility
    func insert(_ data: Data, for key: String) {
        insert(data, for: key, focus: nil)
    }

    /// Clears all cache entries when focus changes.
    /// This ensures fresh workout generation for different muscle groups.
    private func clearForFocusChange() {
        let count = storage.count
        storage.removeAll()
        #if DEBUG
        print("[OpenAICache] 🔄 Focus change: cleared \(count) entries")
        #endif
    }
    
    /// Limpa todo o cache (DEBUG)
    func clearAll() {
        let count = storage.count
        storage.removeAll()
        #if DEBUG
        print("[OpenAICache] 🗑️ Cache limpo: \(count) entradas removidas")
        #endif
    }

    /// Clears cache entries for a specific workout type/focus.
    /// Used when user swaps a workout to force new generation.
    /// - Parameter focus: The DailyFocus to clear from cache
    func clearForWorkoutFocus(_ focus: String) {
        let keysToRemove = storage.keys.filter { $0.contains(focus) }
        for key in keysToRemove {
            storage.removeValue(forKey: key)
        }
        #if DEBUG
        print("[OpenAICache] 🔄 Cleared \(keysToRemove.count) entries for focus: \(focus)")
        #endif
    }

    /// Invalidates cache when user requests a workout swap.
    /// Clears all entries to ensure fresh generation.
    func invalidateOnSwap() {
        let count = storage.count
        storage.removeAll()
        #if DEBUG
        print("[OpenAICache] 🔄 Cache invalidated for swap: \(count) entries cleared")
        #endif
    }
}




