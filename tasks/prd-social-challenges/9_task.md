# [9.0] Firebase Leaderboard Service (L)

## status: pending

<task_context>
<domain>data/services/firebase</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>firestore|asyncstream|transactions</dependencies>
</task_context>

# Task 9.0: Firebase Leaderboard Service

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement Firebase Firestore operations for leaderboards with real-time updates using AsyncStream. This includes creating challenges, updating entries, recomputing ranks, and exposing live data streams to ViewModels.

<requirements>
- Create FirebaseLeaderboardService actor with Firestore operations
- Implement AsyncStream wrapper for Firestore snapshot listeners
- Implement rank recomputation logic with transactions
- Create FBChallenge and FBChallengeEntry DTOs
- Implement mappers for Challenge and LeaderboardEntry
- Create FirebaseLeaderboardRepository implementing LeaderboardRepository protocol
- Handle week boundary calculations (Monday-Sunday)
- Optimize for read-heavy workload (denormalized schema)
</requirements>

## Subtasks

- [ ] 9.1 Create Firestore DTOs for challenges and entries
  - `/Data/Models/FirebaseModels.swift`: FBChallenge, FBChallengeEntry
  - Use @DocumentID and @ServerTimestamp property wrappers

- [ ] 9.2 Create mappers for Challenge entities
  - `/Data/Mappers/LeaderboardMapper.swift`
  - Extensions: FBChallenge.toDomain(), Challenge.toFirestore()
  - Extensions: FBChallengeEntry.toDomain(), LeaderboardEntry.toFirestore()
  - Mapper: [FBChallengeEntry] + FBChallenge → LeaderboardSnapshot

- [ ] 9.3 Implement week boundary calculation
  - Helper function: currentWeekBounds() -> (start: Timestamp, end: Timestamp)
  - Monday 00:00 UTC to Sunday 23:59 UTC
  - Use Calendar.current with weekOfYear and yearForWeekOfYear

- [ ] 9.4 Implement FirebaseLeaderboardService actor
  - `/Data/Services/Firebase/FirebaseLeaderboardService.swift`
  - Method: getCurrentWeekChallenges(groupId) async throws -> [FBChallenge]
  - Method: observeLeaderboard(groupId, type) -> AsyncStream<LeaderboardSnapshot>
  - Method: incrementCheckIn(challengeId, userId) async throws
  - Method: updateStreak(challengeId, userId, streakDays) async throws
  - Private method: recomputeRanks(challengeId) async throws

- [ ] 9.5 Implement AsyncStream for real-time leaderboard updates
  - Wrap Firestore addSnapshotListener in AsyncStream
  - Listen to /challenges collection (filtered by groupId, weekStart, type)
  - Listen to /challenges/{id}/entries subcollection for entry updates
  - Emit LeaderboardSnapshot on each snapshot update
  - Handle listener cleanup on stream termination

- [ ] 9.6 Implement incrementCheckIn with transaction
  - Read current entry value
  - Increment value by 1
  - Update lastUpdated timestamp
  - Call recomputeRanks after successful write

- [ ] 9.7 Implement updateStreak with transaction
  - Read or create entry
  - Set value to streakDays
  - Update lastUpdated timestamp
  - Call recomputeRanks after successful write

- [ ] 9.8 Implement recomputeRanks logic
  - Query all entries for challenge, ordered by value descending
  - Assign rank 1 to highest value, rank 2 to second, etc.
  - Handle ties: same value gets same rank (optional for MVP: always assign unique ranks)
  - Batch write all rank updates (avoid N writes in transaction)

- [ ] 9.9 Create FirebaseLeaderboardRepository
  - `/Data/Repositories/FirebaseLeaderboardRepository.swift`
  - Wraps FirebaseLeaderboardService
  - Conforms to LeaderboardRepository protocol
  - Maps between DTOs and domain entities

- [ ] 9.10 Register FirebaseLeaderboardRepository in AppContainer

## Implementation Details

Reference **techspec.md** sections:
- "Implementation Design > Core Interfaces > LeaderboardRepository"
- "Integration Points > Real-Time Leaderboard Updates"
- "Firestore Schema Design > /challenges collection"

### AsyncStream Implementation (from techspec.md)
```swift
func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot> {
  AsyncStream { continuation in
    let (weekStart, weekEnd) = currentWeekBounds()

    let challengeListener = db.collection("challenges")
      .whereField("groupId", isEqualTo: groupId)
      .whereField("weekStartDate", isEqualTo: weekStart)
      .whereField("type", isEqualTo: type.rawValue)
      .whereField("isActive", isEqualTo: true)
      .addSnapshotListener { snapshot, error in
        guard let challengeDoc = snapshot?.documents.first else { return }
        guard let challenge = try? challengeDoc.data(as: FBChallenge.self).toDomain() else { return }

        // Nested listener for entries subcollection
        challengeDoc.reference.collection("entries")
          .order(by: "rank", descending: false)
          .addSnapshotListener { entriesSnapshot, _ in
            guard let entryDocs = entriesSnapshot?.documents else { return }
            let entries = entryDocs.compactMap { try? $0.data(as: FBChallengeEntry.self).toDomain() }
            let snapshot = LeaderboardSnapshot(
              challenge: challenge,
              entries: entries,
              currentUserEntry: nil // Computed in ViewModel
            )
            continuation.yield(snapshot)
          }
      }

    continuation.onTermination = { _ in
      challengeListener.remove()
    }
  }
}
```

### Rank Recomputation
```swift
private func recomputeRanks(challengeId: String) async throws {
  let entriesSnapshot = try await db.collection("challenges").document(challengeId)
    .collection("entries")
    .order(by: "value", descending: true)
    .getDocuments()

  let batch = db.batch()
  for (index, doc) in entriesSnapshot.documents.enumerated() {
    batch.updateData(["rank": index + 1], forDocument: doc.reference)
  }
  try await batch.commit()
}
```

### Week Bounds Calculation
```swift
private func currentWeekBounds() -> (start: Timestamp, end: Timestamp) {
  let calendar = Calendar.current
  var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
  components.weekday = 2 // Monday (1 = Sunday, 2 = Monday)
  let start = calendar.date(from: components)!
  let end = calendar.date(byAdding: .day, value: 6, to: start)!
  return (Timestamp(date: start), Timestamp(date: end))
}
```

## Success Criteria

- [ ] getCurrentWeekChallenges fetches challenges for current Monday-Sunday week
- [ ] observeLeaderboard returns AsyncStream that emits real-time updates
- [ ] AsyncStream emits new LeaderboardSnapshot when any entry changes
- [ ] incrementCheckIn increases value by 1 and recomputes ranks
- [ ] updateStreak sets streak value and recomputes ranks
- [ ] Ranks are correct after recomputation (1 = highest value)
- [ ] Listener cleanup prevents memory leaks when stream terminates
- [ ] Leaderboard updates reflect within 5 seconds of workout completion
- [ ] All operations handle errors gracefully (network issues, Firestore limits)

## Dependencies

**Before starting this task:**
- Task 1.0 (Firebase SDK Setup) must be complete
- Task 8.0 (Challenge & Leaderboard Models) must provide entities and protocol
- Firestore database and indexes configured

**Blocks these tasks:**
- Task 10.0 (Leaderboard UI) - needs repository to fetch data
- Task 11.0 (Workout Sync) - needs incrementCheckIn/updateStreak methods

## Notes

- **AsyncStream**: New in Swift 5.5. Requires understanding of async sequences and stream lifecycle.
- **Nested Listeners**: We listen to both challenge document AND entries subcollection. Both trigger snapshot updates.
- **Rank Recomputation**: Expensive operation (N writes). Consider debouncing (batch every 30s) in future optimization.
- **Firestore Limits**: Free tier: 50K reads/day, 20K writes/day. Monitor usage. Each rank recomputation = 10 writes (for 10 members).
- **Testing**: Use Firebase Emulator for local testing. Avoids production data pollution.
- **Debouncing (Future)**: If rank recomputation becomes bottleneck, implement debounce: only recompute once every 30 seconds instead of per-write.

## Validation Steps

1. Create challenge manually in Firestore Console → verify getCurrentWeekChallenges returns it
2. Start observeLeaderboard stream → verify initial LeaderboardSnapshot emitted
3. Update entry value in Firestore → verify new snapshot emitted within 5s
4. Call incrementCheckIn → verify entry value incremented, ranks recomputed
5. Call updateStreak → verify streak value updated, ranks correct
6. Complete workout → verify leaderboard updates automatically
7. Monitor Firestore Console → verify rank values are 1, 2, 3, etc. (not all 0)

## Relevant Files

### Files to Create
- `/Data/Models/FirebaseModels.swift` - Add FBChallenge, FBChallengeEntry DTOs
- `/Data/Mappers/LeaderboardMapper.swift` - Mapping logic
- `/Data/Services/Firebase/FirebaseLeaderboardService.swift` - Core service with AsyncStream
- `/Data/Repositories/FirebaseLeaderboardRepository.swift` - Repository implementation

### Files to Modify
- `/Presentation/DI/AppContainer.swift` - Register LeaderboardRepository

### Firebase Console Configuration
- Firestore → Indexes → Create composite index: (groupId, weekStartDate, type, isActive)
- Firestore → Rules → Update security rules for /challenges collection (user can write own entry only)

### External Resources
- AsyncStream: https://developer.apple.com/documentation/swift/asyncstream
- Firestore Transactions: https://firebase.google.com/docs/firestore/manage-data/transactions
- Firestore Batch Writes: https://firebase.google.com/docs/firestore/manage-data/transactions#batched-writes
