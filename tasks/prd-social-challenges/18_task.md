# [18.0] Unit Tests for Domain Layer (M)

## status: done

<task_context>
<domain>testing/unit</domain>
<type>testing</type>
<scope>quality_assurance</scope>
<complexity>medium</complexity>
<dependencies>xctest|mocking</dependencies>
</task_context>

# Task 18.0: Unit Tests for Domain Layer

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create comprehensive unit tests for all Domain layer use cases. Mock repository dependencies to isolate business logic. Aim for 70%+ code coverage on Domain layer as per project standards.

<requirements>
- Create unit tests for all use cases (CreateGroup, JoinGroup, SyncWorkout, etc.)
- Mock all repository dependencies
- Test happy paths and error scenarios
- Test validation logic (authentication checks, group limits, privacy gates)
- Test streak computation accuracy in SyncWorkoutCompletionUseCase
- Follow XCTest framework patterns
- Achieve 70%+ code coverage for Domain layer
- Use spies, stubs, mocks, fixtures for test data
</requirements>

## Subtasks

- [ ] 18.1 Setup test target infrastructure
  - Verify FitTodayTests target exists
  - Add Domain layer classes to test target membership
  - Create Mocks/ directory for mock repositories

- [ ] 18.2 Create mock repositories
  - MockAuthenticationRepository
  - MockGroupRepository
  - MockUserRepository
  - MockLeaderboardRepository
  - Each mock tracks method calls and returns configurable values

- [ ] 18.3 Create CreateGroupUseCaseTests
  - Test successful group creation
  - Test failure when user not authenticated
  - Test failure when user already in group (alreadyInGroup error)
  - Test repository called with correct parameters

- [ ] 18.4 Create JoinGroupUseCaseTests
  - Test successful group join
  - Test failure when user not authenticated
  - Test failure when user already in group
  - Test failure when group not found
  - Test failure when group full (10 members)

- [ ] 18.5 Create LeaveGroupUseCaseTests
  - Test successful leave
  - Test user.currentGroupId cleared
  - Test failure when user not authenticated

- [ ] 18.6 Create SyncWorkoutCompletionUseCaseTests
  - Test successful sync (check-ins incremented, streak updated)
  - Test skipped when workout status != completed
  - Test skipped when user not authenticated
  - Test skipped when user not in group
  - Test skipped when privacy disabled (shareWorkoutData = false)
  - Test streak computation accuracy (0 workouts, 1 workout, consecutive days, broken streak)

- [ ] 18.7 Create streak computation unit tests
  - Test computeCurrentStreak() private method (make internal for testing)
  - Test edge cases:
    - No workouts → streak = 0
    - Single workout today → streak = 1
    - Consecutive days (Mon, Tue, Wed) → streak = 3
    - Gap in days (Mon, Wed) → streak = 1 (resets)
    - Most recent workout yesterday → streak continues
    - Most recent workout 2 days ago → streak = 0 (broken)

- [ ] 18.8 Add test fixtures
  - Create SocialUser fixtures (authenticated, unauthenticated)
  - Create Group fixtures (empty, partial, full)
  - Create WorkoutHistoryEntry fixtures
  - Create Challenge fixtures

- [ ] 18.9 Measure code coverage
  - Run tests with coverage enabled: Cmd+U
  - View coverage report: Report Navigator → Coverage tab
  - Verify 70%+ coverage for Domain layer
  - Identify uncovered lines and add tests

- [ ] 18.10 Document testing patterns
  - Add TESTING.md section on "Running Unit Tests"
  - Document mock repository patterns for future developers

## Implementation Details

Reference **techspec.md** sections:
- "Testing Strategy > Unit Tests"
- Project standards: "Minimum 70% code coverage for business logic"

### Mock Repository Example
```swift
final class MockAuthenticationRepository: AuthenticationRepository {
  var currentUserResult: Result<SocialUser?, Error> = .success(nil)
  var currentUserCalled = false

  func currentUser() async throws -> SocialUser? {
    currentUserCalled = true
    return try currentUserResult.get()
  }

  // ... other methods
}

final class MockGroupRepository: GroupRepository {
  var createGroupResult: Result<Group, Error>?
  var createGroupCalled = false
  var capturedGroupName: String?
  var capturedOwnerId: String?

  func createGroup(name: String, ownerId: String) async throws -> Group {
    createGroupCalled = true
    capturedGroupName = name
    capturedOwnerId = ownerId
    return try createGroupResult!.get()
  }

  // ... other methods
}
```

### Test Example: CreateGroupUseCaseTests
```swift
import XCTest
@testable import FitToday

final class CreateGroupUseCaseTests: XCTestCase {
  var sut: CreateGroupUseCase!
  var mockAuthRepo: MockAuthenticationRepository!
  var mockGroupRepo: MockGroupRepository!
  var mockUserRepo: MockUserRepository!

  override func setUp() {
    super.setUp()
    mockAuthRepo = MockAuthenticationRepository()
    mockGroupRepo = MockGroupRepository()
    mockUserRepo = MockUserRepository()

    sut = CreateGroupUseCase(
      groupRepo: mockGroupRepo,
      userRepo: mockUserRepo,
      authRepo: mockAuthRepo
    )
  }

  func test_execute_whenUserAuthenticated_createsGroup() async throws {
    // Given
    let authenticatedUser = SocialUser.fixture(id: "user1", currentGroupId: nil)
    mockAuthRepo.currentUserResult = .success(authenticatedUser)

    let createdGroup = Group.fixture(id: "group1", name: "Test Group", createdBy: "user1")
    mockGroupRepo.createGroupResult = .success(createdGroup)
    mockUserRepo.updateCurrentGroupResult = .success(())

    // When
    let result = try await sut.execute(name: "Test Group")

    // Then
    XCTAssertEqual(result.id, "group1")
    XCTAssertEqual(result.name, "Test Group")
    XCTAssertTrue(mockGroupRepo.createGroupCalled)
    XCTAssertEqual(mockGroupRepo.capturedGroupName, "Test Group")
    XCTAssertEqual(mockGroupRepo.capturedOwnerId, "user1")
    XCTAssertTrue(mockUserRepo.updateCurrentGroupCalled)
  }

  func test_execute_whenUserNotAuthenticated_throwsError() async {
    // Given
    mockAuthRepo.currentUserResult = .success(nil)

    // When/Then
    do {
      _ = try await sut.execute(name: "Test Group")
      XCTFail("Expected notAuthenticated error")
    } catch DomainError.notAuthenticated {
      // Success
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func test_execute_whenUserAlreadyInGroup_throwsError() async {
    // Given
    let userInGroup = SocialUser.fixture(id: "user1", currentGroupId: "existing-group")
    mockAuthRepo.currentUserResult = .success(userInGroup)

    // When/Then
    do {
      _ = try await sut.execute(name: "Test Group")
      XCTFail("Expected alreadyInGroup error")
    } catch DomainError.alreadyInGroup {
      // Success
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
```

### Fixture Example
```swift
extension SocialUser {
  static func fixture(
    id: String = "user1",
    displayName: String = "Test User",
    currentGroupId: String? = nil,
    shareWorkoutData: Bool = true
  ) -> SocialUser {
    SocialUser(
      id: id,
      displayName: displayName,
      email: "test@example.com",
      photoURL: nil,
      authProvider: .apple,
      currentGroupId: currentGroupId,
      privacySettings: PrivacySettings(shareWorkoutData: shareWorkoutData),
      createdAt: Date()
    )
  }
}
```

## Success Criteria

- [ ] All use cases have corresponding test files
- [ ] Each use case tested for happy path and error scenarios
- [ ] Mocks created for all repository dependencies
- [ ] Fixtures created for common domain entities
- [ ] 70%+ code coverage achieved for Domain layer
- [ ] All tests pass (Cmd+U green)
- [ ] No flaky tests (run multiple times to verify)
- [ ] Tests execute quickly (<5 seconds total for all Domain tests)

## Dependencies

**Before starting this task:**
- Task 6.0 (Group Management Use Cases) must be complete
- Task 11.0 (Workout Sync Use Case) must be complete
- All Domain layer entities finalized

**Blocks these tasks:**
- None (tests can run in parallel with implementation)

## Notes

- **Mocking vs Stubbing**: Use mocks to verify method calls and parameters. Use stubs to return fixed values.
- **Fixtures**: Reduce test setup boilerplate with fixture factory methods.
- **Async Testing**: Use `async/await` in test methods. XCTest supports async test functions.
- **Code Coverage**: Enable in scheme settings: Edit Scheme → Test → Options → Code Coverage
- **Test Organization**: Group tests by use case (one test file per use case)
- **Naming Convention**: `test_methodName_whenCondition_thenExpectedBehavior()`

## Validation Steps

1. Run all tests: Cmd+U → verify all pass
2. Check coverage report → verify 70%+ for Domain layer
3. Identify uncovered lines → add tests to cover
4. Run tests 5 times → verify no flaky failures
5. Review test readability → ensure clear Given/When/Then structure
6. Code review with team → ensure test quality

## Relevant Files

### Files to Create
- `/FitTodayTests/Domain/UseCases/CreateGroupUseCaseTests.swift`
- `/FitTodayTests/Domain/UseCases/JoinGroupUseCaseTests.swift`
- `/FitTodayTests/Domain/UseCases/LeaveGroupUseCaseTests.swift`
- `/FitTodayTests/Domain/UseCases/SyncWorkoutCompletionUseCaseTests.swift`
- `/FitTodayTests/Mocks/MockAuthenticationRepository.swift`
- `/FitTodayTests/Mocks/MockGroupRepository.swift`
- `/FitTodayTests/Mocks/MockLeaderboardRepository.swift`
- `/FitTodayTests/Mocks/MockUserRepository.swift`
- `/FitTodayTests/Fixtures/SocialModelFixtures.swift`

### Files to Modify
- `/TESTING.md` - Add section on running unit tests

### External Resources
- XCTest: https://developer.apple.com/documentation/xctest
- Swift Testing Best Practices: https://www.swiftbysundell.com/articles/testing-swift-code/
