# [8.0] Challenge & Leaderboard Domain Models (M)

## status: pending

<task_context>
<domain>domain/entities</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>swift_concurrency</dependencies>
</task_context>

# Task 8.0: Challenge & Leaderboard Domain Models

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Extend the Domain layer with Challenge and Leaderboard entities. Create the LeaderboardRepository protocol that defines real-time leaderboard operations using AsyncStream for live updates.

<requirements>
- Add Challenge and LeaderboardEntry entities to SocialModels.swift
- Create LeaderboardSnapshot aggregate for UI consumption
- Create LeaderboardRepository protocol with AsyncStream support
- All entities must be Codable, Hashable, Sendable (Swift 6 compliance)
- Protocol methods use async/await and AsyncStream for real-time updates
- Follow existing domain entity patterns
</requirements>

## Subtasks

- [ ] 8.1 Add Challenge entity to SocialModels.swift
  - Properties: id, groupId, type, weekStartDate, weekEndDate, isActive, createdAt
  - ChallengeType enum: checkIns (total workouts), streak (consecutive days)
  - Week bounds: Monday 00:00 to Sunday 23:59 (user's local timezone)

- [ ] 8.2 Add LeaderboardEntry entity to SocialModels.swift
  - Properties: id (userId), displayName, photoURL, value, rank, lastUpdated
  - value: Int (check-ins count OR streak days depending on challenge type)
  - rank: 1-indexed (1 = first place)

- [ ] 8.3 Create LeaderboardSnapshot aggregate
  - Properties: challenge (Challenge), entries ([LeaderboardEntry]), currentUserEntry (LeaderboardEntry?)
  - Sendable conformance for cross-actor data transfer
  - Convenience computed property: sortedEntries (sorted by rank ascending)

- [ ] 8.4 Update LeaderboardRepository protocol in SocialRepositories.swift
  - Method: getCurrentWeekChallenges(groupId) async throws -> [Challenge]
  - Method: observeLeaderboard(groupId, type) -> AsyncStream<LeaderboardSnapshot>
  - Method: incrementCheckIn(challengeId, userId) async throws
  - Method: updateStreak(challengeId, userId, streakDays) async throws

- [ ] 8.5 Add challenge-related errors to DomainError
  - challengeNotFound
  - invalidChallengeType
  - challengeExpired (if needed)

## Implementation Details

Reference **techspec.md** section: "Implementation Design > Data Models > Domain Entities"

All code snippets provided in techspec.md. Key highlights:

### Challenge Entity
```swift
struct Challenge: Codable, Hashable, Sendable, Identifiable {
  let id: String
  let groupId: String
  var type: ChallengeType
  let weekStartDate: Date // Monday 00:00 UTC
  let weekEndDate: Date   // Sunday 23:59 UTC
  var isActive: Bool
  let createdAt: Date
}

enum ChallengeType: String, Codable, CaseIterable, Sendable {
  case checkIns = "check-ins" // Total workouts this week
  case streak = "streak"      // Consecutive days trained
}
```

### LeaderboardSnapshot
```swift
struct LeaderboardSnapshot: Sendable {
  let challenge: Challenge
  let entries: [LeaderboardEntry] // Pre-sorted by rank
  let currentUserEntry: LeaderboardEntry? // Highlighted in UI

  var sortedEntries: [LeaderboardEntry] {
    entries.sorted { $0.rank < $1.rank }
  }
}
```

### AsyncStream for Real-Time Updates
```swift
protocol LeaderboardRepository: Sendable {
  /// Returns AsyncStream for real-time leaderboard updates
  /// Stream emits new LeaderboardSnapshot whenever Firestore data changes
  func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot>

  // ... other methods
}
```

## Success Criteria

- [ ] Challenge entity contains all required fields for weekly challenges
- [ ] ChallengeType enum supports check-ins and streak
- [ ] LeaderboardEntry contains denormalized fields (displayName, photoURL) for UI
- [ ] LeaderboardSnapshot aggregates challenge + entries for single data source
- [ ] LeaderboardRepository protocol defines real-time stream via AsyncStream
- [ ] All entities conform to Codable, Hashable, Sendable
- [ ] No compiler warnings about Sendable conformance
- [ ] Code compiles successfully (no implementation required yet)

## Dependencies

**Before starting this task:**
- Task 4.0 (Domain Layer) should have base social entities
- Understanding of AsyncStream for real-time data (new in Swift 5.5+)

**Blocks these tasks:**
- Task 9.0 (Firebase Leaderboard Service) - needs entities and protocol
- Task 10.0 (Leaderboard UI) - needs LeaderboardSnapshot for view rendering
- Task 11.0 (Workout Sync) - needs Challenge entity to update entries

## Notes

- **AsyncStream**: New in Swift 5.5. Used for real-time Firestore snapshot listeners. Learn more: https://developer.apple.com/documentation/swift/asyncstream
- **Week Bounds**: Challenges run Monday-Sunday. Backend (Firestore) stores as UTC, but UI displays in user's local timezone.
- **Denormalization**: LeaderboardEntry includes displayName/photoURL to avoid N+1 queries during UI rendering.
- **Rank Computation**: Rank is pre-computed in Firestore during write operations (see Task 9.0). Domain entity just stores the value.
- **currentUserEntry**: Optional field in LeaderboardSnapshot. Used to highlight current user's position in UI (e.g., bold text, colored background).

## Validation Steps

1. Build project: `⌘ + B` - should succeed without errors
2. Check Swift Concurrency diagnostics: No warnings about Sendable conformance
3. Verify LeaderboardRepository protocol compiles with AsyncStream return type
4. Verify all entities are value types (struct/enum, not class)
5. Code review: Ensure entities contain only data, no business logic

## Relevant Files

### Files to Modify
- `/Domain/Entities/SocialModels.swift` - Add Challenge, LeaderboardEntry, LeaderboardSnapshot
- `/Domain/Protocols/SocialRepositories.swift` - Add/update LeaderboardRepository protocol
- `/Domain/Errors/DomainError.swift` - Add challenge-related errors

### Reference Files
- `/Domain/Entities/HistoryModels.swift` - Example of existing challenge-like entities (WorkoutHistoryEntry)
- AsyncStream documentation: https://developer.apple.com/documentation/swift/asyncstream
