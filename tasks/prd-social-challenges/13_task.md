# [13.0] Offline Sync Queue (M)

## status: done

<task_context>
<domain>data/services/offline</domain>
<type>implementation</type>
<scope>performance</scope>
<complexity>medium</complexity>
<dependencies>network_monitoring|persistence|retry_logic</dependencies>
</task_context>

# Task 13.0: Offline Sync Queue

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement a pending sync queue to buffer workout completions when offline, with automatic retry when connection is restored. This ensures no leaderboard updates are lost due to network issues.

<requirements>
- Create PendingSyncQueue actor for thread-safe queue management
- Persist queue to disk (survives app restarts)
- Implement network reachability monitoring
- Retry failed syncs when connection restored
- Prevent duplicate syncs (idempotency)
- Integrate into SyncWorkoutCompletionUseCase
- Handle edge cases (app killed while offline, multiple offline workouts)
</requirements>

## Subtasks

- [x] 13.1 Create PendingSyncQueue actor
  - `/Data/Services/Offline/PendingSyncQueue.swift`
  - Actor-isolated for thread safety
  - Properties: queue ([WorkoutHistoryEntry]), isProcessing (Bool)
  - Methods: enqueue(entry), processQueue(syncClosure)

- [x] 13.2 Implement queue persistence
  - Save queue to UserDefaults as JSON
  - Method: persistQueue() - called after enqueue/dequeue
  - Loading happens in init synchronously
  - Use Codable for serialization

- [x] 13.3 Implement network reachability monitoring
  - `/Data/Services/Offline/NetworkMonitor.swift`
  - Use NWPathMonitor from Network framework
  - Observe network status changes
  - Trigger processQueue() when connection restored via callback

- [x] 13.4 Implement retry logic
  - Method: processQueue(sync:) with async closure
  - Iterate through queue, attempt sync for each entry
  - Remove from queue on success (mark as synced)
  - Keep in queue on failure (retry later)

- [x] 13.5 Implement idempotency check
  - Track synced entry IDs in syncedEntryIds Set<UUID>
  - If entry already synced, remove from queue without re-syncing
  - Persisted to UserDefaults to survive app restarts

- [x] 13.6 Integrate into SyncWorkoutCompletionUseCase
  - Added pendingQueue dependency (optional)
  - execute() catches errors and enqueues for retry
  - performSync() is the internal method that throws
  - Graceful degradation - no error thrown to caller

- [x] 13.7 Trigger queue processing on app lifecycle events
  - App foreground: process queue via .onChange(of: scenePhase)
  - Network reconnects: process queue via NetworkMonitor callback
  - Implemented in FitTodayApp.swift

- [ ] 13.8 Add queue status indicator (optional)
  - Badge or text in Groups tab: "Syncing 2 workouts..."
  - Clear when queue empty
  - (Deferred - optional for MVP)

## Implementation Details

Reference **techspec.md** sections:
- "Technical Considerations > Key Decisions > Decision 3: Offline Sync Queue"
- "Technical Considerations > Known Risks > Firestore Concurrent Write Conflicts"

### PendingSyncQueue Implementation (from techspec.md)
```swift
import Foundation

actor PendingSyncQueue {
  private var queue: [WorkoutHistoryEntry] = []
  private var isProcessing = false
  private let storageKey = "PendingSyncQueue"

  init() {
    loadQueue()
  }

  func enqueue(_ entry: WorkoutHistoryEntry) {
    queue.append(entry)
    persistQueue()
  }

  func processQueue(syncUseCase: SyncWorkoutCompletionUseCase) async {
    guard !isProcessing, !queue.isEmpty else { return }
    isProcessing = true
    defer { isProcessing = false }

    var failedEntries: [WorkoutHistoryEntry] = []

    for entry in queue {
      do {
        try await syncUseCase.execute(entry: entry)
        // Success - remove from queue
      } catch {
        // Failure - keep in queue for retry
        print("Sync failed for entry \(entry.id): \(error)")
        failedEntries.append(entry)
      }
    }

    queue = failedEntries
    persistQueue()
  }

  private func persistQueue() {
    guard let data = try? JSONEncoder().encode(queue) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }

  private func loadQueue() {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
          let loaded = try? JSONDecoder().decode([WorkoutHistoryEntry].self, from: data) else {
      return
    }
    queue = loaded
  }
}
```

### Network Monitoring
```swift
import Network

@MainActor
@Observable final class NetworkMonitor {
  private(set) var isConnected = false
  private let monitor = NWPathMonitor()

  init() {
    monitor.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        self?.isConnected = path.status == .satisfied
      }
    }
    monitor.start(queue: DispatchQueue.global())
  }

  deinit {
    monitor.cancel()
  }
}
```

### Integration into SyncWorkoutCompletionUseCase
```swift
struct SyncWorkoutCompletionUseCase {
  // ... existing code

  private let pendingQueue: PendingSyncQueue

  func execute(entry: WorkoutHistoryEntry) async throws {
    do {
      // ... existing sync logic
    } catch {
      // Network error - enqueue for retry
      await pendingQueue.enqueue(entry)
      // Don't throw - graceful degradation
    }
  }
}
```

### App Lifecycle Integration
```swift
// In FitTodayApp.swift
@Environment(\.scenePhase) private var scenePhase

var body: some Scene {
  WindowGroup {
    ContentView()
  }
  .onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
      Task {
        await processPendingQueue()
      }
    }
  }
}

private func processPendingQueue() async {
  guard let syncUseCase = resolver.resolve(SyncWorkoutCompletionUseCase.self),
        let queue = resolver.resolve(PendingSyncQueue.self) else { return }
  await queue.processQueue(syncUseCase: syncUseCase)
}
```

## Success Criteria

- [x] Workout completed offline is enqueued successfully
- [x] Queue persists across app restarts (UserDefaults)
- [x] Queue processes automatically when connection restored
- [x] Successfully synced entries removed from queue
- [x] Failed entries remain in queue for retry
- [x] No duplicate syncs (idempotency check works)
- [x] App foreground triggers queue processing
- [x] Queue empty after all retries succeed
- [x] No crashes when processing empty queue or during sync failures

## Dependencies

**Before starting this task:**
- Task 11.0 (Workout Sync Use Case) must be implemented
- WorkoutHistoryEntry must be Codable for persistence

**Blocks these tasks:**
- None (offline sync is an enhancement, not blocker)

## Notes

- **Persistence**: UserDefaults simple for MVP. For thousands of queued entries, consider File Manager or Core Data.
- **Idempotency**: Firestore write timestamps can detect duplicates. If entry.id already synced (check Firestore), skip.
- **Exponential Backoff**: Optional for MVP. Simple retry on reconnect is sufficient. Future: wait 1s, 2s, 4s, 8s between retries.
- **Queue Size Limit**: Consider max queue size (e.g., 100 entries). Oldest entries auto-deleted if limit exceeded.
- **Network Framework**: NWPathMonitor requires iOS 12+, already targeting iOS 17+ so not a concern.
- **Testing**: Simulate offline by enabling Airplane Mode, complete workout, disable Airplane Mode, verify sync.

## Validation Steps

1. Enable Airplane Mode → complete workout → verify entry enqueued
2. Disable Airplane Mode → verify queue processes automatically
3. Check Firestore → verify entry synced
4. Force quit app while queue has pending entries → relaunch → verify queue reloads
5. Complete multiple workouts offline → verify all sync when online
6. Simulate network error (mock response) → verify entry re-queued
7. Check Groups tab → leaderboard updates after queue processes

## Relevant Files

### Files to Create
- `/Data/Services/PendingSyncQueue.swift` - Actor for queue management
- `/Data/Services/NetworkMonitor.swift` - Network reachability monitoring (optional, can use inline)

### Files to Modify
- `/Domain/UseCases/SyncWorkoutCompletionUseCase.swift` - Add queue integration
- `/FitTodayApp.swift` - Add app lifecycle queue processing
- `/Presentation/DI/AppContainer.swift` - Register PendingSyncQueue as singleton

### External Resources
- NWPathMonitor: https://developer.apple.com/documentation/network/nwpathmonitor
- UserDefaults: https://developer.apple.com/documentation/foundation/userdefaults
