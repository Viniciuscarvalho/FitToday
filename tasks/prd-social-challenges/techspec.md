# Technical Specification
# Social Challenges Feature ("GymRats")

## Executive Summary

This specification defines the technical implementation of the Social Challenges feature for FitToday, extending the app from a single-user local fitness tracker to a multi-user social platform. The solution introduces Firebase Authentication and Firestore for cloud sync while preserving the existing MVVM + Repository architecture. Key technical decisions include: (1) denormalized Firestore schema for read-optimized leaderboards, (2) real-time AsyncStream-based data flow for live updates, (3) offline-first sync queue with conflict resolution, and (4) privacy-respecting workout data sharing controls.

**Architecture Pattern**: MVVM + Repository + Firebase
**Primary Technologies**: Swift 6, SwiftUI, Firebase SDK (Auth + Firestore), Swift Concurrency
**Integration Approach**: Non-invasive extension of existing Domain/Data/Presentation layers

---

## System Architecture

### Component Overview

The Social Challenges feature follows FitToday's established 3-layer architecture:

**Presentation Layer**:
- New 5th tab ("Groups") added to TabRootView
- ViewModels: `GroupsViewModel`, `CreateGroupViewModel`, `JoinGroupViewModel`, `LeaderboardViewModel`
- Views: `GroupsView`, `LeaderboardView`, `InviteShareSheet`, `NotificationFeedView`
- Navigation: Deep link handler for `fittoday://group/invite/{groupId}`

**Domain Layer**:
- Entities: `SocialUser`, `Group`, `GroupMember`, `Challenge`, `LeaderboardEntry`, `LeaderboardSnapshot`
- Use Cases: `CreateGroupUseCase`, `JoinGroupUseCase`, `SyncWorkoutCompletionUseCase`, `FetchLeaderboardUseCase`
- Repository Protocols: `AuthenticationRepository`, `GroupRepository`, `LeaderboardRepository`, `UserRepository`

**Data Layer**:
- Services: `FirebaseAuthService`, `FirebaseGroupService`, `FirebaseLeaderboardService`
- Repository Implementations: `FirebaseAuthenticationRepository`, `FirebaseGroupRepository`, `FirebaseLeaderboardRepository`
- DTOs: `FBUser`, `FBGroup`, `FBChallenge`, `FBChallengeEntry`
- Mappers: `SocialUserMapper`, `GroupMapper`, `LeaderboardMapper`

**Integration Points with Existing Code**:
- `AppContainer`: Register Firebase repositories via Swinject
- `TabRootView`: Add `.groups` tab with icon `person.3.fill`
- `WorkoutCompletionView`: Call `SyncWorkoutCompletionUseCase` after workout save
- `AppRouter`: Handle deep links for group invites
- `UserProfile`: Add optional `socialUserId` property for Firebase UID

---

## Implementation Design

### Core Interfaces

#### AuthenticationRepository (Domain/Protocols/SocialRepositories.swift)

```swift
protocol AuthenticationRepository: Sendable {
  func currentUser() async throws -> SocialUser?
  func signInWithApple() async throws -> SocialUser
  func signInWithGoogle() async throws -> SocialUser
  func signInWithEmail(_ email: String, password: String) async throws -> SocialUser
  func signOut() async throws
}
```

#### GroupRepository (Domain/Protocols/SocialRepositories.swift)

```swift
protocol GroupRepository: Sendable {
  func createGroup(name: String, ownerId: String) async throws -> Group
  func getGroup(_ groupId: String) async throws -> Group?
  func addMember(groupId: String, userId: String, displayName: String, photoURL: URL?) async throws
  func removeMember(groupId: String, userId: String) async throws
  func leaveGroup(groupId: String, userId: String) async throws
  func deleteGroup(_ groupId: String) async throws
  func getMembers(groupId: String) async throws -> [GroupMember]
}
```

#### LeaderboardRepository (Domain/Protocols/SocialRepositories.swift)

```swift
protocol LeaderboardRepository: Sendable {
  func getCurrentWeekChallenges(groupId: String) async throws -> [Challenge]
  func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot>
  func incrementCheckIn(challengeId: String, userId: String) async throws
  func updateStreak(challengeId: String, userId: String, streakDays: Int) async throws
}
```

**Key Design Decisions**:
- All repositories are `Sendable` for Swift 6 concurrency compliance
- Async/await throughout (no completion handlers)
- `observeLeaderboard` returns `AsyncStream` for real-time Firestore snapshots

### Data Models

#### Domain Entities (Domain/Entities/SocialModels.swift)

```swift
struct SocialUser: Codable, Hashable, Sendable, Identifiable {
  let id: String // Firebase UID
  var displayName: String
  var email: String?
  var photoURL: URL?
  var authProvider: AuthProvider
  var currentGroupId: String?
  var privacySettings: PrivacySettings
  let createdAt: Date
}

struct PrivacySettings: Codable, Hashable, Sendable {
  var shareWorkoutData: Bool // Default: true
}

enum AuthProvider: String, Codable, Sendable {
  case apple, google, email
}

struct Group: Codable, Hashable, Sendable, Identifiable {
  let id: String // UUID
  var name: String
  let createdAt: Date
  let createdBy: String // userId
  var memberCount: Int // Denormalized from Firestore
  var isActive: Bool
}

struct GroupMember: Codable, Hashable, Sendable, Identifiable {
  let id: String // userId
  var displayName: String
  var photoURL: URL?
  let joinedAt: Date
  var role: GroupRole
  var isActive: Bool
}

enum GroupRole: String, Codable, Sendable {
  case admin, member
}

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

struct LeaderboardEntry: Codable, Hashable, Sendable, Identifiable {
  let id: String // userId
  var displayName: String
  var photoURL: URL?
  var value: Int // check-ins count or streak days
  var rank: Int  // 1-indexed
  let lastUpdated: Date
}

struct LeaderboardSnapshot: Sendable {
  let challenge: Challenge
  let entries: [LeaderboardEntry] // Sorted by rank ASC
  let currentUserEntry: LeaderboardEntry? // Highlighted in UI
}

struct GroupNotification: Codable, Hashable, Sendable, Identifiable {
  let id: String
  let userId: String // Recipient
  let groupId: String
  var type: NotificationType
  var message: String
  var isRead: Bool
  let createdAt: Date
}

enum NotificationType: String, Codable, Sendable {
  case newMember = "new_member"
  case rankChange = "rank_change"
  case weekEnded = "week_ended"
}
```

#### Firestore DTOs (Data/Models/FirebaseModels.swift)

```swift
import FirebaseFirestore

struct FBUser: Codable {
  @DocumentID var id: String?
  var displayName: String
  var email: String?
  var photoURL: String?
  var authProvider: String
  var currentGroupId: String?
  var privacySettings: FBPrivacySettings
  @ServerTimestamp var createdAt: Timestamp?
}

struct FBPrivacySettings: Codable {
  var shareWorkoutData: Bool
}

struct FBGroup: Codable {
  @DocumentID var id: String?
  var name: String
  @ServerTimestamp var createdAt: Timestamp?
  var createdBy: String
  var memberCount: Int
  var isActive: Bool
}

struct FBMember: Codable {
  @DocumentID var id: String?
  var displayName: String
  var photoURL: String?
  @ServerTimestamp var joinedAt: Timestamp?
  var role: String
  var isActive: Bool
}

struct FBChallenge: Codable {
  @DocumentID var id: String?
  var groupId: String
  var type: String
  @ServerTimestamp var weekStartDate: Timestamp?
  @ServerTimestamp var weekEndDate: Timestamp?
  var isActive: Bool
  @ServerTimestamp var createdAt: Timestamp?
}

struct FBChallengeEntry: Codable {
  @DocumentID var id: String?
  var displayName: String
  var photoURL: String?
  var value: Int
  var rank: Int
  @ServerTimestamp var lastUpdated: Timestamp?
}
```

**Mapper Pattern**:
```swift
extension FBUser {
  func toDomain() -> SocialUser {
    SocialUser(
      id: id ?? "",
      displayName: displayName,
      email: email,
      photoURL: photoURL.flatMap { URL(string: $0) },
      authProvider: AuthProvider(rawValue: authProvider) ?? .email,
      currentGroupId: currentGroupId,
      privacySettings: PrivacySettings(shareWorkoutData: privacySettings.shareWorkoutData),
      createdAt: createdAt?.dateValue() ?? Date()
    )
  }
}

extension SocialUser {
  func toFirestore() -> FBUser {
    FBUser(
      id: id,
      displayName: displayName,
      email: email,
      photoURL: photoURL?.absoluteString,
      authProvider: authProvider.rawValue,
      currentGroupId: currentGroupId,
      privacySettings: FBPrivacySettings(shareWorkoutData: privacySettings.shareWorkoutData),
      createdAt: Timestamp(date: createdAt)
    )
  }
}
```

### Firestore Schema Design

```
/users/{userId}
  ├─ displayName: String
  ├─ email: String?
  ├─ photoURL: String?
  ├─ authProvider: String (apple/google/email)
  ├─ createdAt: Timestamp
  ├─ currentGroupId: String?
  └─ privacySettings: Map
      └─ shareWorkoutData: Bool

/groups/{groupId}
  ├─ name: String
  ├─ createdAt: Timestamp
  ├─ createdBy: String (userId)
  ├─ memberCount: Int (denormalized)
  ├─ isActive: Bool
  └─ /members (subcollection)
      └─ {userId}
          ├─ displayName: String
          ├─ photoURL: String?
          ├─ joinedAt: Timestamp
          ├─ role: String (admin/member)
          └─ isActive: Bool

/challenges/{challengeId}
  ├─ groupId: String (indexed)
  ├─ type: String (check-ins/streak)
  ├─ weekStartDate: Timestamp (indexed)
  ├─ weekEndDate: Timestamp
  ├─ isActive: Bool
  ├─ createdAt: Timestamp
  └─ /entries (subcollection)
      └─ {userId}
          ├─ displayName: String (denormalized)
          ├─ photoURL: String?
          ├─ value: Int (check-ins count or streak days)
          ├─ rank: Int (computed on write)
          └─ lastUpdated: Timestamp

/notifications/{notificationId}
  ├─ userId: String (indexed - recipient)
  ├─ groupId: String
  ├─ type: String (new_member/rank_change/week_ended)
  ├─ message: String
  ├─ isRead: Bool
  ├─ createdAt: Timestamp
  └─ expiresAt: Timestamp (7 days from creation)
```

**Denormalization Rationale**:
- `memberCount` in Group: Avoids expensive subcollection count queries
- `displayName/photoURL` in ChallengeEntry: Prevents N+1 user lookups during leaderboard fetch
- `rank` pre-computed: Read-optimized leaderboard sorting (no client-side sorting required)

**Firestore Indexes Required**:
```
challenges: (groupId, weekStartDate, type, isActive)
notifications: (userId, createdAt DESC)
```

**Security Rules** (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Group members can read group data
    match /groups/{groupId} {
      allow read: if request.auth != null &&
        exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid));
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        get(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid)).data.role == 'admin';

      match /members/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Challenge entries writable only by entry owner
    match /challenges/{challengeId} {
      allow read: if request.auth != null;

      match /entries/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Notifications readable only by recipient
    match /notifications/{notificationId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
  }
}
```

---

## Integration Points

### Firebase SDK Integration

**Dependencies** (Package.swift / Xcode SPM):
```
https://github.com/firebase/firebase-ios-sdk.git (Version: 10.20.0+)

Products:
- FirebaseAuth
- FirebaseFirestore
- FirebaseFirestoreSwift
```

**Firebase Configuration** (`GoogleService-Info.plist`):
- Download from Firebase Console
- Add to FitToday target (not committed to Git)
- Initialize in `FitTodayApp.init()`:

```swift
import FirebaseCore

@main
struct FitTodayApp: App {
  init() {
    FirebaseApp.configure()
    // ... existing setup
  }
}
```

### Authentication Flow

**Apple Sign-In** (Primary):
```swift
import AuthenticationServices
import FirebaseAuth

actor FirebaseAuthService {
  func signInWithApple() async throws -> SocialUser {
    let nonce = randomNonceString()
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)

    let authController = ASAuthorizationController(authorizationRequests: [request])
    let result = try await authController.performRequests()

    guard let appleIDCredential = result.first?.credential as? ASAuthorizationAppleIDCredential else {
      throw AuthError.invalidCredential
    }

    let oAuthCredential = OAuthProvider.credential(
      withProviderID: "apple.com",
      idToken: String(data: appleIDCredential.identityToken!, encoding: .utf8)!,
      rawNonce: nonce
    )

    let authResult = try await Auth.auth().signIn(with: oAuthCredential)
    let user = authResult.user

    // Create or update user in Firestore
    let socialUser = SocialUser(
      id: user.uid,
      displayName: appleIDCredential.fullName?.givenName ?? "User",
      email: user.email,
      photoURL: user.photoURL,
      authProvider: .apple,
      currentGroupId: nil,
      privacySettings: PrivacySettings(shareWorkoutData: true),
      createdAt: Date()
    )

    try await saveUserToFirestore(socialUser)
    return socialUser
  }

  private func saveUserToFirestore(_ user: SocialUser) async throws {
    let db = Firestore.firestore()
    try await db.collection("users").document(user.id).setData(user.toFirestore().toDictionary())
  }
}
```

**Google Sign-In** (Secondary):
- Use Firebase Auth Google provider
- Similar flow to Apple Sign-In

**Email/Password** (Fallback):
```swift
func signInWithEmail(_ email: String, password: String) async throws -> SocialUser {
  let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
  let user = authResult.user

  let socialUser = SocialUser(
    id: user.uid,
    displayName: user.displayName ?? "User",
    email: user.email,
    photoURL: user.photoURL,
    authProvider: .email,
    currentGroupId: nil,
    privacySettings: PrivacySettings(shareWorkoutData: true),
    createdAt: Date()
  )

  try await saveUserToFirestore(socialUser)
  return socialUser
}
```

### Deep Linking for Invites

**URL Scheme**: `fittoday://group/invite/{groupId}`
**Universal Link**: `https://fittoday.app/group/invite/{groupId}`

**Implementation** (FitTodayApp.swift):
```swift
.onOpenURL { url in
  if let deepLink = DeepLink(url: url) {
    switch deepLink.destination {
    case .groupInvite(let groupId):
      Task {
        await handleGroupInvite(groupId: groupId)
      }
    }
  }
}

private func handleGroupInvite(groupId: String) async {
  guard let authRepo = resolver.resolve(AuthenticationRepository.self) else { return }

  let currentUser = try? await authRepo.currentUser()
  if currentUser == nil {
    // Navigate to auth flow with groupId context
    router.navigate(to: .groupInviteAuth(groupId: groupId))
  } else {
    // Navigate directly to join preview
    router.navigate(to: .groupInvitePreview(groupId: groupId))
  }
}
```

**Universal Link Setup** (Associated Domains):
- Add `fittoday.app` to Xcode entitlements
- Host `apple-app-site-association` file on server

### Real-Time Leaderboard Updates

**FirebaseLeaderboardService** (Data/Services/Firebase/FirebaseLeaderboardService.swift):
```swift
import FirebaseFirestore

actor FirebaseLeaderboardService {
  private let db = Firestore.firestore()

  func observeLeaderboard(groupId: String, type: ChallengeType) -> AsyncStream<LeaderboardSnapshot> {
    AsyncStream { continuation in
      let (weekStart, weekEnd) = currentWeekBounds()

      // Listener for challenge document
      let challengeListener = db.collection("challenges")
        .whereField("groupId", isEqualTo: groupId)
        .whereField("weekStartDate", isEqualTo: weekStart)
        .whereField("type", isEqualTo: type.rawValue)
        .whereField("isActive", isEqualTo: true)
        .addSnapshotListener { snapshot, error in
          guard let challengeDoc = snapshot?.documents.first else { return }
          guard let challenge = try? challengeDoc.data(as: FBChallenge.self).toDomain() else { return }

          // Listener for entries subcollection
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

  private func currentWeekBounds() -> (start: Timestamp, end: Timestamp) {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
    components.weekday = 2 // Monday
    let start = calendar.date(from: components)!
    let end = calendar.date(byAdding: .day, value: 6, to: start)!
    return (Timestamp(date: start), Timestamp(date: end))
  }
}
```

**ViewModel Consumption** (Presentation/Features/Groups/GroupsViewModel.swift):
```swift
@MainActor
@Observable final class GroupsViewModel {
  private(set) var checkInsLeaderboard: LeaderboardSnapshot?
  private var leaderboardTask: Task<Void, Never>?

  func startListeningToLeaderboards(groupId: String) {
    guard let repo = resolver.resolve(LeaderboardRepository.self) else { return }

    leaderboardTask = Task {
      for await snapshot in repo.observeLeaderboard(groupId: groupId, type: .checkIns) {
        self.checkInsLeaderboard = snapshot
      }
    }
  }

  func stopListening() {
    leaderboardTask?.cancel()
  }
}
```

---

## Testing Strategy

### Unit Tests

**Domain Layer**:
- `SyncWorkoutCompletionUseCaseTests`:
  - Test privacy gating (shareWorkoutData = false → no Firebase write)
  - Test streak computation accuracy (consecutive days, broken streaks)
  - Test check-in increment logic
- `CreateGroupUseCaseTests`:
  - Validate 1-group limit enforcement
  - Validate authenticated user check
- `JoinGroupUseCaseTests`:
  - Test group full scenario (10 members)
  - Test duplicate join prevention

**Data Layer**:
- `FirebaseLeaderboardRepositoryTests`:
  - Mock Firestore SDK using protocol conformance
  - Verify transaction logic for incrementCheckIn
  - Verify rank recomputation correctness
- `LeaderboardMapperTests`:
  - Test FBChallenge ↔ Challenge mapping
  - Test FBChallengeEntry ↔ LeaderboardEntry mapping

**Mocking Strategy**:
```swift
final class MockGroupRepository: GroupRepository {
  var createGroupCalled = false
  var mockGroup: Group?

  func createGroup(name: String, ownerId: String) async throws -> Group {
    createGroupCalled = true
    return mockGroup ?? Group(id: "mock-id", name: name, createdAt: Date(), createdBy: ownerId, memberCount: 1, isActive: true)
  }
}
```

### Integration Tests

**Firebase Emulator Tests**:
- Use Firebase Emulator Suite for local testing (no production data)
- Test end-to-end flow: create group → add member → complete workout → verify leaderboard update
- Verify Firestore security rules enforce user access controls

**Deep Linking Tests**:
- Test URL parsing: `fittoday://group/invite/abc123` → `DeepLink.groupInvite(groupId: "abc123")`
- Test routing: authenticated user vs. new user flows

### Manual Testing Checklist

- [ ] Create group as new user (no existing group)
- [ ] Attempt to create second group (expect error: "already in group")
- [ ] Generate invite link, share via iMessage
- [ ] Tap invite link from second device (new user flow → auth → auto-join)
- [ ] Complete workout → verify both leaderboards update within 5 seconds
- [ ] Turn off "Share workout data" → complete workout → verify no Firebase sync
- [ ] Test offline: complete workout offline → go online → verify sync occurs
- [ ] Leave group → verify user removed from members, currentGroupId cleared
- [ ] Admin deletes group → verify all members' currentGroupId cleared

---

## Development Sequencing

### Build Order

#### Phase 1: Infrastructure & Authentication (Week 1)
**Dependencies**: None
1. Add Firebase SDK via SPM (FirebaseAuth, Firestore, FirestoreSwift)
2. Configure Firebase project in console (create iOS app, download GoogleService-Info.plist)
3. Implement `FirebaseAuthService` with Apple Sign-In
4. Create `FirebaseAuthenticationRepository`
5. Add login/signup screens (AuthenticationView, AuthenticationViewModel)
6. Register AuthenticationRepository in AppContainer
7. Store `socialUserId` in UserDefaults on successful auth

**Validation**: User can sign in with Apple ID, view authenticated user ID in debug console

#### Phase 2: Groups & Members (Week 2)
**Dependencies**: Phase 1 complete
1. Create Domain entities: `Group`, `GroupMember`, `SocialUser`
2. Create `GroupRepository` protocol and `FirebaseGroupRepository` implementation
3. Implement `FirebaseGroupService` with Firestore CRUD operations
4. Create `CreateGroupUseCase` and `JoinGroupUseCase`
5. Add Groups tab to TabRootView (5th tab, icon: `person.3.fill`)
6. Build `GroupsView`, `CreateGroupView`, and corresponding ViewModels
7. Implement deep link handler for `fittoday://group/invite/{groupId}`

**Validation**: User can create group, generate invite link, share link, join group from link

#### Phase 3: Leaderboards & Challenges (Week 3)
**Dependencies**: Phase 2 complete
1. Create Domain entities: `Challenge`, `LeaderboardEntry`, `LeaderboardSnapshot`
2. Create `LeaderboardRepository` protocol and `FirebaseLeaderboardRepository`
3. Implement `FirebaseLeaderboardService` with real-time listeners (AsyncStream)
4. Build LeaderboardView with two tabs (Check-Ins, Streak)
5. Implement `FetchLeaderboardUseCase`
6. Add leaderboard real-time subscription to GroupsViewModel

**Validation**: User can view live leaderboards with mock data, see real-time updates when Firestore data changes

#### Phase 4: Workout Sync Integration (Week 4)
**Dependencies**: Phase 3 complete
1. Create `SyncWorkoutCompletionUseCase` with streak computation logic
2. Integrate with `WorkoutCompletionView.onDismiss()` to call SyncWorkoutCompletionUseCase
3. Implement privacy controls: PrivacySettingsView with "Share workout data" toggle
4. Test end-to-end flow: complete workout → Firebase write → leaderboard update
5. Implement offline sync queue (PendingSyncQueue actor)
6. Add network reachability monitoring to trigger queue processing

**Validation**: Complete workout → leaderboard updates within 5 seconds, offline workout syncs when online

#### Phase 5: Notifications & Polish (Week 5)
**Dependencies**: Phase 4 complete
1. Implement in-app notification feed (NotificationFeedView)
2. Create `NotificationRepository` and `FirebaseNotificationRepository`
3. Add badge count to Groups tab icon
4. Implement group management (leave group, remove member, delete group)
5. Add error handling for all edge cases (group full, already in group, etc.)
6. Integration testing with Firebase Emulator
7. Beta rollout to 10% of users via remote config

**Validation**: All user flows complete, error states handled gracefully, notifications appear correctly

### Technical Dependencies

**External Dependencies**:
- Firebase project created in Firebase Console (with Authentication and Firestore enabled)
- Apple Developer account for Associated Domains (Universal Links)
- Firestore indexes created manually via Firebase Console

**Blocking Risks**:
- Firebase SDK version incompatibility with Swift 6 → Mitigation: Use latest stable release (10.20.0+)
- Apple Sign-In entitlement approval delay → Mitigation: Start Apple Developer setup in Week 1

---

## Technical Considerations

### Key Decisions

#### Decision 1: Firestore Denormalization for Leaderboards

**Chosen Approach**: Store `displayName`, `photoURL`, and `rank` directly in ChallengeEntry documents

**Rationale**:
- Avoids N+1 queries to fetch user details during leaderboard render
- Pre-computed ranks eliminate client-side sorting overhead
- Read-optimized for real-time updates (leaderboard fetched frequently)

**Trade-offs**:
- Data duplication (displayName/photoURL stored in multiple places)
- Stale data risk if user updates profile (acceptable: leaderboards show snapshot at workout time)
- Write complexity (rank recomputation requires batch writes)

**Rejected Alternatives**:
- Normalized schema with separate User lookups → Too slow for real-time leaderboards (N+1 problem)
- Client-side sorting → Inconsistent results across devices if data changes mid-render

#### Decision 2: AsyncStream for Real-Time Updates

**Chosen Approach**: Use Swift Concurrency `AsyncStream` to wrap Firestore snapshot listeners

**Rationale**:
- Native Swift async/await integration (no Combine complexity)
- Automatic cancellation when task is cancelled (prevents memory leaks)
- Type-safe: `AsyncStream<LeaderboardSnapshot>` enforces return type

**Trade-offs**:
- Requires iOS 15+ (already targeting iOS 17+, not a concern)
- Learning curve for team unfamiliar with AsyncStream

**Rejected Alternatives**:
- Combine publishers → Adds dependency, overkill for simple pub/sub
- Callback-based listeners → Manual memory management, not @Sendable compatible

#### Decision 3: Offline Sync Queue

**Chosen Approach**: Implement `PendingSyncQueue` actor to buffer workout completions during offline periods

**Rationale**:
- Ensures no leaderboard updates are lost due to network issues
- Retry mechanism with exponential backoff
- User experience: workout always saves locally first (offline-first design)

**Trade-offs**:
- Complexity: need to handle duplicate writes if user opens app multiple times offline
- Storage: queue persisted to disk (UserDefaults or CoreData) to survive app restarts

**Implementation**:
```swift
actor PendingSyncQueue {
  private var queue: [WorkoutHistoryEntry] = []

  func enqueue(_ entry: WorkoutHistoryEntry) {
    queue.append(entry)
    persistQueue()
  }

  func processQueue(syncUseCase: SyncWorkoutCompletionUseCase) async {
    for entry in queue {
      do {
        try await syncUseCase.execute(entry: entry)
        queue.removeAll { $0.id == entry.id }
        persistQueue()
      } catch {
        // Keep in queue, retry later
        print("Sync failed for entry \(entry.id): \(error)")
      }
    }
  }

  private func persistQueue() {
    let data = try? JSONEncoder().encode(queue)
    UserDefaults.standard.set(data, forKey: "PendingSyncQueue")
  }
}
```

### Known Risks

#### Risk 1: Firestore Concurrent Write Conflicts

**Problem**: Two users in the same group complete workouts simultaneously → rank recomputation race condition

**Mitigation**:
- Use Firestore transactions for all rank updates
- Last-write-wins semantics (Firestore transactions are serializable)
- Debounce rank recomputation (batch updates every 30 seconds instead of per-write)

**Contingency**: If conflicts persist, move to Cloud Functions for server-side rank computation

#### Risk 2: Apple Sign-In User Data Privacy

**Problem**: If user selects "Hide My Email", we receive obfuscated email from Apple → displayName might be empty

**Mitigation**:
- Prompt user to set display name during onboarding if `fullName` is nil
- Default to "User" + random number if no name provided
- Store display name in Firestore (not relying on Firebase Auth display name)

**Contingency**: Add separate "Edit Profile" screen for users to update display name post-auth

#### Risk 3: Firestore Free Tier Limits

**Problem**: MVP exceeds free tier (50K reads/day, 20K writes/day) with high user adoption

**Estimation**:
- 100 active users × 3 leaderboard views/day × 11 reads each = 3,300 reads/day
- 100 users × 1 workout/day × 12 writes each = 1,200 writes/day
- **Total: ~4,500 operations/day** (within free tier)

**Mitigation**:
- Monitor Firestore usage via Firebase Console
- Implement read caching (fetch leaderboard once on app open, rely on real-time updates thereafter)
- Debounce rank recomputation to reduce writes

**Contingency**: If usage spikes, enable Firestore caching (`persistenceEnabled = true`) to reduce reads

### Special Requirements

#### Performance Requirements

1. **Leaderboard Update Latency**: Must reflect within 5 seconds of workout completion
   - Achieved via Firestore real-time listeners (typical latency: <1 second)
2. **Offline Support**: Users can complete workouts offline, sync when connection restored
   - Implemented via PendingSyncQueue with retry logic
3. **App Launch Time**: Firebase initialization should not increase app launch time by >500ms
   - Mitigation: Initialize Firebase asynchronously after SwiftUI view loads

#### Security Considerations

1. **Firestore Security Rules**: Enforce that users can only write their own challenge entries
   - Rule: `allow write: if request.auth.uid == userId`
2. **Invite Link Security**: Group IDs must be non-guessable to prevent unauthorized joins
   - Implementation: Use UUID for groupId (128-bit randomness)
3. **User Data Privacy**: Respect "Share workout data" toggle
   - Enforcement: SyncWorkoutCompletionUseCase early-exits if `shareWorkoutData == false`

#### Monitoring Needs

1. **Firebase Analytics Events**:
   - `group_created`: Track group creation rate
   - `group_joined`: Track invite conversion rate
   - `workout_synced`: Track sync success/failure rate
2. **Crashlytics**:
   - Report Firestore write failures
   - Report deep link parsing errors
3. **Performance Monitoring**:
   - Track leaderboard fetch duration (should be <2s)

---

## Standards Compliance

### Swift 6 Concurrency Standards

This implementation fully adopts Swift 6 strict concurrency:

1. **Sendable Conformance**: All Domain entities and DTOs conform to `Sendable`
2. **Actor Isolation**: Firebase services are `actor`-isolated for thread safety
3. **@MainActor**: All ViewModels marked `@MainActor` for UI updates
4. **Async/Await**: No completion handlers, all async code uses `async/await`

**Example**:
```swift
actor FirebaseLeaderboardService { // Actor-isolated
  func incrementCheckIn(challengeId: String, userId: String) async throws {
    // Thread-safe Firestore operations
  }
}

@MainActor // UI-bound
@Observable final class GroupsViewModel {
  private(set) var leaderboard: LeaderboardSnapshot?

  func startListening() {
    Task {
      for await snapshot in repo.observeLeaderboard(...) {
        self.leaderboard = snapshot // Safe: already on MainActor
      }
    }
  }
}
```

### SwiftUI Best Practices (from code-standards.md)

1. **Extract Views >100 Lines**: LeaderboardView will extract `LeaderboardRowView`, `LeaderboardHeaderView`
2. **Use @Observable**: GroupsViewModel uses @Observable (not ObservableObject)
3. **Router Navigation Pattern**: AppRouter extended with `.groupInvitePreview`, `.createGroup` routes
4. **@Bindable for Bindings**: Use `@Bindable` when binding to @Observable objects

### Kodeco Swift Style Guide Compliance

1. **Naming Conventions**:
   - Types: UpperCamelCase (`SocialUser`, `GroupRepository`)
   - Variables/Functions: lowerCamelCase (`currentUser()`, `displayName`)
   - Protocols ending in "ing" for capabilities: `ErrorPresenting`
2. **Code Organization**:
   - Extensions for protocol conformance (e.g., `extension FBUser { func toDomain() }`)
   - MARK comments for logical sections
3. **Access Control**:
   - Prefer `private` over `fileprivate`
   - Use `private(set)` for read-only published properties in ViewModels
4. **Golden Path**:
   - Use `guard` for early exits
   - Example:
     ```swift
     func execute(groupId: String) async throws {
       guard let user = try await authRepo.currentUser() else {
         throw DomainError.notAuthenticated
       }
       guard user.currentGroupId == nil else {
         throw DomainError.alreadyInGroup
       }
       // Happy path continues
     }
     ```

---

## Relevant Files

### Files to Create

#### Domain Layer
- `/Domain/Entities/SocialModels.swift` - Core social domain entities (SocialUser, Group, Challenge, LeaderboardEntry)
- `/Domain/Protocols/SocialRepositories.swift` - Repository protocols (AuthenticationRepository, GroupRepository, LeaderboardRepository, UserRepository, NotificationRepository)
- `/Domain/UseCases/CreateGroupUseCase.swift` - Use case for creating groups
- `/Domain/UseCases/JoinGroupUseCase.swift` - Use case for joining groups
- `/Domain/UseCases/SyncWorkoutCompletionUseCase.swift` - **CRITICAL** use case connecting workout completion to leaderboard updates
- `/Domain/UseCases/FetchLeaderboardUseCase.swift` - Use case for fetching leaderboards
- `/Domain/UseCases/LeaveGroupUseCase.swift` - Use case for leaving groups
- `/Domain/UseCases/GenerateInviteLinkUseCase.swift` - Use case for generating invite links

#### Data Layer
- `/Data/Models/FirebaseModels.swift` - Firestore DTOs (FBUser, FBGroup, FBChallenge, FBChallengeEntry)
- `/Data/Mappers/SocialUserMapper.swift` - FBUser ↔ SocialUser mapping
- `/Data/Mappers/GroupMapper.swift` - FBGroup ↔ Group mapping
- `/Data/Mappers/LeaderboardMapper.swift` - FBChallenge + Entries → LeaderboardSnapshot
- `/Data/Services/Firebase/FirebaseAuthService.swift` - Firebase Authentication operations (Apple/Google/Email sign-in)
- `/Data/Services/Firebase/FirebaseGroupService.swift` - Firestore group CRUD operations
- `/Data/Services/Firebase/FirebaseLeaderboardService.swift` - **CRITICAL** Firestore real-time listener implementation for leaderboards
- `/Data/Services/Firebase/FirebaseUserService.swift` - Firestore user operations
- `/Data/Services/Firebase/FirebaseNotificationService.swift` - Firestore notification operations
- `/Data/Repositories/FirebaseAuthenticationRepository.swift` - AuthenticationRepository implementation
- `/Data/Repositories/FirebaseGroupRepository.swift` - GroupRepository implementation
- `/Data/Repositories/FirebaseLeaderboardRepository.swift` - LeaderboardRepository implementation
- `/Data/Repositories/FirebaseUserRepository.swift` - UserRepository implementation
- `/Data/Repositories/FirebaseNotificationRepository.swift` - NotificationRepository implementation
- `/Data/Services/PendingSyncQueue.swift` - Actor-based offline sync queue

#### Presentation Layer
- `/Presentation/Features/Groups/GroupsView.swift` - Main groups tab view
- `/Presentation/Features/Groups/GroupsViewModel.swift` - **CRITICAL** Main ViewModel orchestrating group data, leaderboards, and real-time updates
- `/Presentation/Features/Groups/CreateGroupView.swift` - Create group modal
- `/Presentation/Features/Groups/CreateGroupViewModel.swift` - ViewModel for group creation
- `/Presentation/Features/Groups/JoinGroupView.swift` - Join group preview/confirmation
- `/Presentation/Features/Groups/JoinGroupViewModel.swift` - ViewModel for joining groups
- `/Presentation/Features/Groups/LeaderboardView.swift` - Leaderboard display with tabs (Check-Ins, Streak)
- `/Presentation/Features/Groups/LeaderboardViewModel.swift` - ViewModel for leaderboard data
- `/Presentation/Features/Groups/LeaderboardRowView.swift` - Single leaderboard entry row
- `/Presentation/Features/Groups/InviteShareSheet.swift` - iOS Share Sheet wrapper for invite links
- `/Presentation/Features/Groups/NotificationFeedView.swift` - In-app notification feed
- `/Presentation/Features/Groups/NotificationFeedViewModel.swift` - ViewModel for notifications
- `/Presentation/Features/Authentication/AuthenticationView.swift` - Login/Signup screen
- `/Presentation/Features/Authentication/AuthenticationViewModel.swift` - ViewModel for auth flows
- `/Presentation/Features/Profile/PrivacySettingsView.swift` - Privacy controls (Share workout data toggle)

### Files to Modify

#### Dependency Injection
- `/Presentation/DI/AppContainer.swift` - Register Firebase repositories (AuthenticationRepository, GroupRepository, LeaderboardRepository, UserRepository, NotificationRepository)

#### Navigation
- `/Presentation/Router/AppTab.swift` - Add `.groups` tab enum case
- `/Presentation/Router/AppRoute.swift` - Add `.groupInviteAuth`, `.groupInvitePreview`, `.createGroup` routes
- `/Presentation/Router/AppRouter.swift` - Add deep link handler for `fittoday://group/invite/{groupId}`
- `/Presentation/TabRootView.swift` - Add 5th tab for Groups with icon `person.3.fill`

#### Integration Points
- `/Presentation/Features/WorkoutCompletion/WorkoutCompletionView.swift` - Call `SyncWorkoutCompletionUseCase` after workout save
- `/Domain/Entities/UserProfile.swift` - Add optional `socialUserId: String?` property
- `/FitTodayApp.swift` - Add `FirebaseApp.configure()` in `init()`
- `/.gitignore` - Add `GoogleService-Info.plist` to prevent committing Firebase credentials

#### Configuration
- `/FitToday.xcodeproj/project.pbxproj` - Add `GoogleService-Info.plist` to Copy Bundle Resources
- `/FitToday/Info.plist` - Add URL scheme `fittoday` and Associated Domains for Universal Links

### External Configuration Files

- `GoogleService-Info.plist` - Firebase configuration (download from Firebase Console)
- `firestore.rules` - Firestore security rules (deployed via Firebase Console or CLI)
- `firestore.indexes.json` - Firestore composite indexes (auto-generated or manually created)

---

## Open Questions for Stakeholders

1. **Week Start Day Configuration**: Should week start be fixed to Monday globally, or allow users to configure (Monday vs. Sunday)?
   - **Impact**: Affects challenge period computation and leaderboard reset timing
   - **Recommendation**: Fixed Monday start for MVP simplicity

2. **Privacy Default**: Should "Share workout data" be opt-in or opt-out by default?
   - **Impact**: Opt-out (default ON) increases feature adoption but may concern privacy-conscious users
   - **Recommendation**: Opt-out (default ON) for higher engagement, clearly communicated during onboarding

3. **Gamification Elements**: Should we add celebratory animations when users climb ranks or win weekly challenges?
   - **Impact**: Increases delight but adds scope to MVP
   - **Recommendation**: Defer to v2, focus on core functionality for MVP

4. **Profile Photo Requirement**: If user authenticates with Apple (hides email), how do we ensure they have a display name?
   - **Impact**: Empty display names reduce leaderboard usability
   - **Recommendation**: Prompt for display name during onboarding if Apple ID doesn't provide one

5. **Historical Leaderboard Data Retention**: How long should we store archived weekly challenge data before purging?
   - **Impact**: Affects future "history" feature scope and Firestore storage costs
   - **Recommendation**: Retain for 90 days, then auto-delete (configurable in Cloud Functions)

---

**Document Version**: 1.0
**Last Updated**: 2026-01-15
**Author**: Engineering Team
**Reviewers**: Product, Design, Backend, QA
