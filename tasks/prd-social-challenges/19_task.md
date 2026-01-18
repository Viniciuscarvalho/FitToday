# [19.0] Firebase Data Layer Tests (M)

## status: done

<task_context>
<domain>testing/integration</domain>
<type>testing</type>
<scope>quality_assurance</scope>
<complexity>medium</complexity>
<dependencies>firebase_emulator|xctest</dependencies>
</task_context>

# Task 19.0: Firebase Data Layer Tests

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create integration tests for Firebase Data layer (services, repositories, mappers) using Firebase Emulator. Test Firestore operations, real-time listeners, transactions, and data mapping.

<requirements>
- Use Firebase Emulator for safe, isolated testing
- Test all Firebase services (Auth, Group, Leaderboard, Notification)
- Test Firestore transactions (add member with count increment)
- Test real-time listeners (AsyncStream)
- Test mappers (DTO ↔ Domain entity conversion)
- Test error scenarios (network failures, invalid data)
- Follow XCTest framework patterns
- Tests should be deterministic (no flakiness)
</requirements>

## Subtasks

- [ ] 19.1 Setup Firebase Emulator for testing
  - Configure test target to use emulator (localhost ports)
  - Create setUp method to clear emulator data before each test
  - Create tearDown to stop emulator connections

- [ ] 19.2 Create FirebaseAuthServiceTests
  - Test signInWithApple creates user in Firestore
  - Test user document contains correct fields
  - Test signOut clears authentication

- [ ] 19.3 Create FirebaseGroupServiceTests
  - Test createGroup writes to /groups collection
  - Test createGroup adds first member with role="admin"
  - Test addMember transaction (increment count, write member)
  - Test addMember fails when group full (count >= 10)
  - Test removeMember decrements count
  - Test deleteGroup removes group + all members

- [ ] 19.4 Create FirebaseLeaderboardServiceTests
  - Test getCurrentWeekChallenges fetches correct challenges
  - Test observeLeaderboard AsyncStream emits snapshots
  - Test incrementCheckIn updates entry value
  - Test recomputeRanks assigns correct ranks (1, 2, 3...)
  - Test updateStreak sets streak value

- [ ] 19.5 Test Firestore transactions
  - Test concurrent addMember calls (race condition)
  - Verify transaction prevents group from exceeding 10 members
  - Test rollback on transaction failure

- [ ] 19.6 Test real-time listeners (AsyncStream)
  - Subscribe to observeLeaderboard stream
  - Update entry value in Firestore
  - Verify stream emits new snapshot within 1 second
  - Cancel stream and verify no memory leaks

- [ ] 19.7 Create mapper tests
  - Test SocialUserMapper: FBUser ↔ SocialUser
  - Test GroupMapper: FBGroup ↔ Group
  - Test LeaderboardMapper: FBChallenge + [FBChallengeEntry] → LeaderboardSnapshot
  - Test edge cases (nil photoURL, empty displayName)

- [ ] 19.8 Test error scenarios
  - Test Firestore permission denied (security rules)
  - Test invalid document data (missing required fields)
  - Test network timeout (simulate with emulator offline mode)

- [ ] 19.9 Create test helpers
  - Helper: createTestUser(id, displayName) → writes to Firestore
  - Helper: createTestGroup(id, name, ownerId) → writes to Firestore
  - Helper: createTestChallenge(groupId, type) → writes to Firestore
  - Helper: waitForAsync(_ condition:, timeout:) → async assertion helper

- [ ] 19.10 Measure code coverage for Data layer
  - Run tests with coverage enabled
  - Verify meaningful coverage (aim for 50%+, Data layer harder to test)
  - Focus on critical paths (transactions, listeners)

## Implementation Details

Reference **techspec.md** sections:
- "Testing Strategy > Integration Tests > Firebase Emulator Tests"
- "Data Layer" component overview

### Test Configuration with Emulator
```swift
import XCTest
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
@testable import FitToday

final class FirebaseGroupServiceTests: XCTestCase {
  var firestore: Firestore!
  var auth: Auth!
  var sut: FirebaseGroupService!

  override func setUp() async throws {
    try await super.setUp()

    // Configure Firebase to use emulator
    let settings = Firestore.firestore().settings
    settings.host = "localhost:8080"
    settings.isSSLEnabled = false
    Firestore.firestore().settings = settings

    Auth.auth().useEmulator(withHost: "localhost", port: 9099)

    firestore = Firestore.firestore()
    auth = Auth.auth()
    sut = FirebaseGroupService()

    // Clear emulator data before each test
    try await clearFirestoreData()
  }

  override func tearDown() async throws {
    try await clearFirestoreData()
    try await super.tearDown()
  }

  private func clearFirestoreData() async throws {
    // Delete all documents in emulator (use HTTP API or batch delete)
    // For simplicity, can delete specific collections
    let groups = try await firestore.collection("groups").getDocuments()
    for doc in groups.documents {
      try await doc.reference.delete()
    }
  }
}
```

### Test Example: Group Creation
```swift
func test_createGroup_writesToFirestore() async throws {
  // Given
  let groupName = "Test Group"
  let ownerId = "user123"

  // When
  let group = try await sut.createGroup(name: groupName, ownerId: ownerId)

  // Then
  XCTAssertFalse(group.id.isEmpty)

  // Verify Firestore document exists
  let doc = try await firestore.collection("groups").document(group.id).getDocument()
  XCTAssertTrue(doc.exists)

  let data = doc.data()!
  XCTAssertEqual(data["name"] as? String, groupName)
  XCTAssertEqual(data["createdBy"] as? String, ownerId)
  XCTAssertEqual(data["memberCount"] as? Int, 1)
  XCTAssertEqual(data["isActive"] as? Bool, true)

  // Verify first member added
  let members = try await firestore.collection("groups").document(group.id)
    .collection("members")
    .getDocuments()

  XCTAssertEqual(members.count, 1)
  XCTAssertEqual(members.documents.first?.documentID, ownerId)
  XCTAssertEqual(members.documents.first?.data()["role"] as? String, "admin")
}
```

### Test Example: Transaction
```swift
func test_addMember_whenGroupFull_throwsError() async throws {
  // Given: Create group with 10 members
  let group = try await createTestGroup(memberCount: 10)

  // When/Then: Adding 11th member should fail
  do {
    try await sut.addMember(groupId: group.id, userId: "user11", displayName: "User 11", photoURL: nil)
    XCTFail("Expected groupFull error")
  } catch DomainError.groupFull {
    // Success
  } catch {
    XCTFail("Unexpected error: \(error)")
  }

  // Verify member count still 10
  let doc = try await firestore.collection("groups").document(group.id).getDocument()
  XCTAssertEqual(doc.data()?["memberCount"] as? Int, 10)
}
```

### Test Example: AsyncStream Listener
```swift
func test_observeLeaderboard_emitsUpdatesOnChange() async throws {
  // Given: Create challenge with one entry
  let challenge = try await createTestChallenge(groupId: "group1", type: "check-ins")
  try await createTestEntry(challengeId: challenge.id, userId: "user1", value: 5)

  // When: Subscribe to stream
  let stream = sut.observeLeaderboard(groupId: "group1", type: .checkIns)
  let expectation = XCTestExpectation(description: "Stream emits snapshot")

  Task {
    for await snapshot in stream {
      // Then: Verify snapshot contains entry
      XCTAssertEqual(snapshot.entries.count, 1)
      XCTAssertEqual(snapshot.entries.first?.value, 5)
      expectation.fulfill()
      break // Cancel stream after first emission
    }
  }

  // Wait for stream to emit
  await fulfillment(of: [expectation], timeout: 5.0)
}
```

## Success Criteria

- [ ] All Firebase services have corresponding test files
- [ ] createGroup writes to Firestore with correct structure
- [ ] addMember transaction works correctly (count increment + member write)
- [ ] addMember fails when group full (10 members)
- [ ] observeLeaderboard AsyncStream emits real-time updates
- [ ] recomputeRanks assigns correct ranks (1, 2, 3...)
- [ ] Mappers correctly convert DTOs ↔ Domain entities
- [ ] Tests run reliably with Firebase Emulator (no flakiness)
- [ ] All tests pass (Cmd+U green)
- [ ] No Firebase production data affected (emulator only)

## Dependencies

**Before starting this task:**
- Task 16.0 (Integration Testing) should have Firebase Emulator configured
- Task 5.0 (Firebase Group Service) must be implemented
- Task 9.0 (Firebase Leaderboard Service) must be implemented

**Blocks these tasks:**
- None (tests can run in parallel)

## Notes

- **Emulator Required**: NEVER run these tests against production Firebase. Always use emulator.
- **Test Isolation**: Clear Firestore data before each test to prevent cross-test pollution.
- **Async Testing**: Use `async/await` in test methods. XCTest handles async assertions with `await`.
- **Timeouts**: AsyncStream tests need timeouts to prevent hanging (default: 5s).
- **Determinism**: Tests should be deterministic (same input → same output). Avoid time-dependent assertions.
- **Performance**: Data layer tests slower than unit tests (Firestore I/O). Acceptable if <30s total.

## Validation Steps

1. Start Firebase Emulator → verify running
2. Run FirebaseGroupServiceTests → all pass
3. Run FirebaseLeaderboardServiceTests → all pass
4. Run MapperTests → all pass
5. Check Firestore Emulator UI → verify test data created and cleaned up
6. Run tests 5 times → verify no flaky failures
7. Stop emulator → verify tests fail gracefully (not hang)

## Relevant Files

### Files to Create
- `/FitTodayTests/Data/Services/FirebaseGroupServiceTests.swift`
- `/FitTodayTests/Data/Services/FirebaseLeaderboardServiceTests.swift`
- `/FitTodayTests/Data/Services/FirebaseAuthServiceTests.swift`
- `/FitTodayTests/Data/Mappers/SocialUserMapperTests.swift`
- `/FitTodayTests/Data/Mappers/GroupMapperTests.swift`
- `/FitTodayTests/Data/Mappers/LeaderboardMapperTests.swift`
- `/FitTodayTests/Helpers/FirebaseTestHelpers.swift` - Test data setup helpers

### Files to Modify
- `/FitTodayTests/Info.plist` - Add emulator configuration if needed

### External Resources
- Firebase Emulator: https://firebase.google.com/docs/emulator-suite
- XCTest Async: https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations
- Firestore Testing: https://firebase.google.com/docs/firestore/security/test-rules-emulator
