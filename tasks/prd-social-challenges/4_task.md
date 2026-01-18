# [4.0] Domain Layer for Social Entities (M)

## status: completed

<task_context>
<domain>domain/entities</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>swift_concurrency</dependencies>
</task_context>

# Task 4.0: Domain Layer for Social Entities

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create all Domain layer entities and repository protocols required for the Social Challenges feature. This establishes the core business models (Group, Member, Challenge, Leaderboard) and defines contracts for data access.

<requirements>
- Create all social domain entities in SocialModels.swift
- Create repository protocols in SocialRepositories.swift
- All entities must be Codable, Hashable, Sendable (Swift 6 compliance)
- All repository protocols must be Sendable
- Follow existing FitToday domain entity patterns
- No implementation details - pure domain logic only
</requirements>

## Subtasks

- [ ] 4.1 Extend SocialModels.swift with Group entities
  - Group struct (id, name, createdAt, createdBy, memberCount, isActive)
  - GroupMember struct (id, displayName, photoURL, joinedAt, role, isActive)
  - GroupRole enum (admin, member)

- [ ] 4.2 Add Challenge entities to SocialModels.swift
  - Challenge struct (id, groupId, type, weekStartDate, weekEndDate, isActive, createdAt)
  - ChallengeType enum (checkIns, streak)
  - LeaderboardEntry struct (id, displayName, photoURL, value, rank, lastUpdated)
  - LeaderboardSnapshot struct (challenge, entries, currentUserEntry)

- [ ] 4.3 Add Notification entities to SocialModels.swift
  - GroupNotification struct (id, userId, groupId, type, message, isRead, createdAt)
  - NotificationType enum (newMember, rankChange, weekEnded)

- [ ] 4.4 Create GroupRepository protocol
  - Methods: createGroup, getGroup, addMember, removeMember, leaveGroup, deleteGroup, getMembers
  - All methods async throws

- [ ] 4.5 Create LeaderboardRepository protocol
  - Methods: getCurrentWeekChallenges, observeLeaderboard (AsyncStream), incrementCheckIn, updateStreak
  - observeLeaderboard returns AsyncStream<LeaderboardSnapshot> for real-time updates

- [ ] 4.6 Create UserRepository protocol
  - Methods: getUser, updateCurrentGroup, updatePrivacySettings
  - Manages social user data (separate from existing UserProfile)

- [ ] 4.7 Create NotificationRepository protocol
  - Methods: fetchNotifications, markAsRead, createNotification

- [ ] 4.8 Update existing DomainError enum
  - Add cases: notAuthenticated, alreadyInGroup, groupNotFound, groupFull, notGroupAdmin, networkUnavailable

## Implementation Details

Reference **techspec.md** section: "Implementation Design > Data Models > Domain Entities"

All code snippets are provided in techspec.md. Key highlights:

### Swift 6 Compliance
```swift
struct Group: Codable, Hashable, Sendable, Identifiable {
  let id: String
  var name: String
  let createdAt: Date
  let createdBy: String
  var memberCount: Int
  var isActive: Bool
}
```

### AsyncStream for Real-Time
```swift
protocol LeaderboardRepository: Sendable {
  func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot>
  // ... other methods
}
```

### Repository Protocols
All methods use `async throws` pattern, no completion handlers.

## Success Criteria

- [ ] All entities conform to Codable, Hashable, Sendable, Identifiable
- [ ] All repository protocols conform to Sendable
- [ ] No compiler warnings about Sendable conformance
- [ ] Entities contain only pure data (no business logic)
- [ ] Repository protocols define clear contracts (method signatures)
- [ ] DomainError enum has all required cases for social features
- [ ] Code compiles successfully (no implementation required yet)

## Dependencies

**Before starting this task:**
- Task 2.0 should be complete (SocialUser, AuthProvider, PrivacySettings already created)
- Understanding of existing Domain layer structure

**Blocks these tasks:**
- Task 5.0 (Firebase Group Service) - needs repository protocols
- Task 6.0 (Group Management Use Cases) - needs entities
- Task 8.0 (Challenge & Leaderboard Models) - needs base entities

## Notes

- **No Implementation**: This task creates protocols and entities only. Implementations come in Data layer tasks.
- **Sendable**: Critical for Swift 6. All entities must be value types (struct/enum) with Sendable members.
- **Identifiable**: Use `let id: String` to conform. Firestore document IDs will map to this.
- **Denormalization**: Some entities have denormalized fields (e.g., `memberCount` in Group). This is intentional for performance (see techspec.md).
- **AsyncStream**: New in Swift 5.5+. Used for real-time Firestore listeners. Learn more: https://developer.apple.com/documentation/swift/asyncstream

## Validation Steps

1. Build project: `⌘ + B` - should succeed without errors
2. Check Swift Concurrency diagnostics: No warnings about "non-Sendable type crossing actor boundaries"
3. Verify all entities are value types (struct/enum, not class)
4. Verify all repository protocols use `async throws`, not closures
5. Code review: Ensure entities contain only data, no business logic

## Relevant Files

### Files to Create/Modify
- `/Domain/Entities/SocialModels.swift` - Extend with Group, Challenge, Notification entities
- `/Domain/Protocols/SocialRepositories.swift` - Add GroupRepository, LeaderboardRepository, UserRepository, NotificationRepository
- `/Domain/Errors/DomainError.swift` - Add social-specific error cases

### Reference Files (Read Only)
- `/Domain/Entities/UserProfile.swift` - Example of existing domain entity
- `/Domain/Protocols/WorkoutHistoryRepository.swift` - Example of existing repository protocol
