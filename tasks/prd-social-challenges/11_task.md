# [11.0] Workout Sync Use Case (L)

## status: pending

<task_context>
<domain>domain/usecases</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>workout_history|leaderboard_repository|streak_computation</dependencies>
</task_context>

# Task 11.0: Workout Sync Use Case

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create the critical SyncWorkoutCompletionUseCase that connects workout completion to leaderboard updates. This use case computes user streaks, respects privacy settings, and triggers Firebase leaderboard writes.

<requirements>
- Create SyncWorkoutCompletionUseCase with streak computation logic
- Integrate with existing WorkoutHistoryRepository for local data
- Respect privacy toggle (skip sync if shareWorkoutData = false)
- Update both check-ins and streak challenges
- Compute consecutive day streak accurately
- Integrate into WorkoutCompletionView.onDismiss()
- Handle offline scenarios (queued in Task 13.0)
- Follow Swift 6 concurrency patterns
</requirements>

## Subtasks

- [ ] 11.1 Create SyncWorkoutCompletionUseCase
  - `/Domain/UseCases/SyncWorkoutCompletionUseCase.swift`
  - Dependencies: LeaderboardRepository, UserRepository, AuthenticationRepository, WorkoutHistoryRepository
  - Method: execute(entry: WorkoutHistoryEntry) async throws

- [ ] 11.2 Implement privacy gating
  - Check user.privacySettings.shareWorkoutData
  - Early-exit if false (don't sync to Firebase)

- [ ] 11.3 Implement authentication and group validation
  - Verify user is authenticated
  - Verify user is in a group (currentGroupId not nil)
  - Skip sync if either check fails

- [ ] 11.4 Fetch current week's challenges
  - Call LeaderboardRepository.getCurrentWeekChallenges(groupId)
  - Filter for check-ins and streak challenges

- [ ] 11.5 Implement check-ins challenge update
  - Call LeaderboardRepository.incrementCheckIn(challengeId, userId)
  - This increments workout count for the week

- [ ] 11.6 Implement streak computation logic
  - Private method: computeCurrentStreak(userId) async throws -> Int
  - Fetch all completed workouts from WorkoutHistoryRepository
  - Sort by date descending
  - Check if most recent is today or yesterday (streak still active)
  - Count consecutive days backward from most recent

- [ ] 11.7 Implement streak challenge update
  - Call LeaderboardRepository.updateStreak(challengeId, userId, streakDays)
  - Pass computed streak value

- [ ] 11.8 Add error handling
  - Catch and log errors (don't crash app if sync fails)
  - Network errors should be retried by offline queue (Task 13.0)

- [ ] 11.9 Integrate into WorkoutCompletionView
  - Modify `/Presentation/Features/WorkoutCompletion/WorkoutCompletionView.swift`
  - After saving workout to WorkoutHistoryRepository, call SyncWorkoutCompletionUseCase
  - Run in background Task (don't block UI dismissal)

- [ ] 11.10 Register SyncWorkoutCompletionUseCase in AppContainer

## Implementation Details

Reference **techspec.md** sections:
- "Implementation Design > Use Cases > SyncWorkoutCompletionUseCase"
- "Data Flow Scenarios > Complete Workout → Update Leaderboard"

### Use Case Implementation (from techspec.md)
```swift
struct SyncWorkoutCompletionUseCase {
  private let leaderboardRepo: LeaderboardRepository
  private let userRepo: UserRepository
  private let authRepo: AuthenticationRepository
  private let historyRepo: WorkoutHistoryRepository

  func execute(entry: WorkoutHistoryEntry) async throws {
    // 1. Skip if workout skipped (not completed)
    guard entry.status == .completed else { return }

    // 2. Verify authentication and group membership
    guard let user = try await authRepo.currentUser(),
          let groupId = user.currentGroupId else { return }

    // 3. Respect privacy settings
    guard user.privacySettings.shareWorkoutData else { return }

    // 4. Fetch current week's challenges
    let challenges = try await leaderboardRepo.getCurrentWeekChallenges(groupId: groupId)

    // 5. Update check-ins challenge
    if let checkInsChallenge = challenges.first(where: { $0.type == .checkIns }) {
      try await leaderboardRepo.incrementCheckIn(challengeId: checkInsChallenge.id, userId: user.id)
    }

    // 6. Compute and update streak challenge
    if let streakChallenge = challenges.first(where: { $0.type == .streak }) {
      let streak = try await computeCurrentStreak(userId: user.id)
      try await leaderboardRepo.updateStreak(challengeId: streakChallenge.id, userId: user.id, streakDays: streak)
    }
  }

  private func computeCurrentStreak(userId: String) async throws -> Int {
    let entries = try await historyRepo.listEntries()
    let completedDates = entries
      .filter { $0.status == .completed }
      .map { Calendar.current.startOfDay(for: $0.date) }
      .sorted(by: >)

    guard let mostRecent = completedDates.first else { return 0 }
    let today = Calendar.current.startOfDay(for: Date())

    // Streak broken if most recent is not today or yesterday
    guard mostRecent == today || Calendar.current.dateComponents([.day], from: mostRecent, to: today).day == 1 else {
      return 0
    }

    // Count consecutive days
    var streak = 1
    for i in 1..<completedDates.count {
      let prev = completedDates[i-1]
      let current = completedDates[i]
      if Calendar.current.dateComponents([.day], from: current, to: prev).day == 1 {
        streak += 1
      } else {
        break
      }
    }
    return streak
  }
}
```

### Integration into WorkoutCompletionView
```swift
// In WorkoutCompletionView.swift or WorkoutCompletionViewModel
func onDismiss() async {
  // Existing: Save to local SwiftData
  try? await historyRepo.saveEntry(entry)

  // NEW: Sync to Firebase leaderboard
  if let syncUseCase = resolver.resolve(SyncWorkoutCompletionUseCase.self) {
    Task.detached { // Don't block UI
      try? await syncUseCase.execute(entry: entry)
    }
  }
}
```

## Success Criteria

- [ ] Workout completion triggers leaderboard update
- [ ] Check-ins count increments by 1 after workout
- [ ] Streak value updates correctly (consecutive days)
- [ ] Privacy toggle prevents sync when disabled
- [ ] Unauthenticated users don't crash (gracefully skip sync)
- [ ] Users not in group don't crash (gracefully skip sync)
- [ ] Streak computation handles edge cases (no workouts, 1 workout, broken streak)
- [ ] Leaderboard reflects update within 5 seconds
- [ ] Sync errors don't block UI or crash app

## Dependencies

**Before starting this task:**
- Task 9.0 (Firebase Leaderboard Service) must provide repository methods
- Existing WorkoutHistoryRepository for streak computation
- Task 2.0 (Authentication) for user authentication check

**Blocks these tasks:**
- Task 16.0 (Integration Testing) - end-to-end flow requires this
- All leaderboard functionality depends on workouts syncing

## Notes

- **Streak Computation**: Most complex part. Test thoroughly with edge cases (no workouts, single workout, 2-day gap, etc.).
- **Privacy First**: Always check shareWorkoutData before syncing. Respect user consent.
- **Offline Handling**: Network errors should be caught here, but retry logic belongs in Task 13.0 (Offline Sync Queue).
- **Performance**: Streak computation fetches all history entries. For users with thousands of workouts, consider optimizing to fetch only recent entries (last 30 days).
- **Race Condition**: If user completes 2 workouts rapidly, both may compute same streak. Firebase transactions handle this correctly.

## Validation Steps

1. Complete workout → verify check-ins count increments
2. Complete workout on consecutive day → verify streak increments
3. Skip a day, then complete workout → verify streak resets to 1
4. Turn off privacy toggle → complete workout → verify NO sync to Firebase
5. Sign out → complete workout → verify NO crash, no sync
6. Leave group → complete workout → verify NO crash, no sync
7. Complete workout offline → verify graceful failure (queued in Task 13.0)

## Relevant Files

### Files to Create
- `/Domain/UseCases/SyncWorkoutCompletionUseCase.swift`

### Files to Modify
- `/Presentation/Features/WorkoutCompletion/WorkoutCompletionView.swift` - Add sync call
- `/Presentation/DI/AppContainer.swift` - Register use case

### Reference Files
- `/Domain/UseCases/ComputeHistoryInsightsUseCase.swift` - Example of streak computation (can reuse logic)
- `/Domain/Repositories/WorkoutHistoryRepository.swift` - Interface for fetching history
