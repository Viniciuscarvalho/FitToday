//
//  PendingSyncQueue.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import Foundation

// MARK: - PendingSyncQueue

/// Actor-based offline sync queue for buffering workout completions when network is unavailable.
/// Persists queue to UserDefaults to survive app restarts.
actor PendingSyncQueue {

    // MARK: - Properties

    private var queue: [WorkoutHistoryEntry] = []
    private var syncedEntryIds: Set<UUID> = []
    private var isProcessing = false

    private let storageKey = "PendingSyncQueue"
    private let syncedIdsKey = "PendingSyncQueueSyncedIds"
    private let maxQueueSize = 100

    // MARK: - Initialization

    init() {
        // Load persisted data synchronously from UserDefaults
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode([WorkoutHistoryEntry].self, from: data) {
            self.queue = loaded
            #if DEBUG
            print("[PendingSyncQueue] Loaded \(loaded.count) entries from persistence")
            #endif
        }

        if let idsArray = UserDefaults.standard.stringArray(forKey: syncedIdsKey) {
            self.syncedEntryIds = Set(idsArray.compactMap { UUID(uuidString: $0) })
            #if DEBUG
            print("[PendingSyncQueue] Loaded \(syncedEntryIds.count) synced IDs from persistence")
            #endif
        }
    }

    // MARK: - Public Methods

    /// Enqueue an entry for later sync.
    /// - Parameter entry: The workout history entry to sync later.
    func enqueue(_ entry: WorkoutHistoryEntry) {
        // Idempotency: Skip if already synced
        guard !syncedEntryIds.contains(entry.id) else {
            #if DEBUG
            print("[PendingSyncQueue] Entry \(entry.id) already synced, skipping enqueue")
            #endif
            return
        }

        // Avoid duplicate entries in queue
        guard !queue.contains(where: { $0.id == entry.id }) else {
            #if DEBUG
            print("[PendingSyncQueue] Entry \(entry.id) already in queue, skipping")
            #endif
            return
        }

        queue.append(entry)

        // Enforce max queue size (remove oldest if exceeded)
        if queue.count > maxQueueSize {
            queue.removeFirst(queue.count - maxQueueSize)
        }

        persistQueue()

        #if DEBUG
        print("[PendingSyncQueue] Enqueued entry \(entry.id), queue size: \(queue.count)")
        #endif
    }

    /// Process all pending entries in the queue.
    /// - Parameter syncClosure: Async closure that attempts to sync an entry.
    func processQueue(sync syncClosure: @Sendable (WorkoutHistoryEntry) async throws -> Void) async {
        guard !isProcessing, !queue.isEmpty else {
            #if DEBUG
            if isProcessing {
                print("[PendingSyncQueue] Already processing, skipping")
            } else {
                print("[PendingSyncQueue] Queue is empty, nothing to process")
            }
            #endif
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        #if DEBUG
        print("[PendingSyncQueue] Processing \(queue.count) entries...")
        #endif

        var failedEntries: [WorkoutHistoryEntry] = []

        for entry in queue {
            // Skip if already synced (idempotency check)
            if syncedEntryIds.contains(entry.id) {
                #if DEBUG
                print("[PendingSyncQueue] Entry \(entry.id) already synced, removing from queue")
                #endif
                continue
            }

            do {
                try await syncClosure(entry)

                // Success: Mark as synced
                syncedEntryIds.insert(entry.id)

                #if DEBUG
                print("[PendingSyncQueue] Successfully synced entry \(entry.id)")
                #endif
            } catch {
                // Failure: Keep in queue for retry
                failedEntries.append(entry)

                #if DEBUG
                print("[PendingSyncQueue] Sync failed for entry \(entry.id): \(error.localizedDescription)")
                #endif
            }
        }

        queue = failedEntries
        persistQueue()
        persistSyncedIds()

        #if DEBUG
        print("[PendingSyncQueue] Processing complete. Remaining: \(queue.count), Total synced: \(syncedEntryIds.count)")
        #endif
    }

    /// Returns the current queue size.
    var pendingCount: Int {
        queue.count
    }

    /// Returns whether the queue has pending entries.
    var hasPendingEntries: Bool {
        !queue.isEmpty
    }

    /// Clear all synced IDs older than the retention period (cleanup).
    /// Call periodically to prevent unbounded growth of syncedEntryIds.
    func cleanupOldSyncedIds(retentionDays: Int = 30) {
        // For simplicity, we limit the set size instead of tracking timestamps
        let maxSyncedIds = 1000
        if syncedEntryIds.count > maxSyncedIds {
            // Remove oldest entries (since Set is unordered, just remove randomly)
            let toRemove = syncedEntryIds.count - maxSyncedIds
            for _ in 0..<toRemove {
                if let first = syncedEntryIds.first {
                    syncedEntryIds.remove(first)
                }
            }
            persistSyncedIds()
        }
    }

    // MARK: - Persistence

    private func persistQueue() {
        guard let data = try? JSONEncoder().encode(queue) else {
            #if DEBUG
            print("[PendingSyncQueue] Failed to encode queue")
            #endif
            return
        }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func persistSyncedIds() {
        let idsArray = syncedEntryIds.map { $0.uuidString }
        UserDefaults.standard.set(idsArray, forKey: syncedIdsKey)
    }
}
