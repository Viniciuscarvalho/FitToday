# [7.0] Complete bidirectional HealthKit sync (M)

## status: completed

<task_context>
<domain>data/services</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_1</dependencies>
</task_context>

# Task 7.0: Complete bidirectional HealthKit sync

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Complete the bidirectional HealthKit integration: (1) automatically export completed workouts to Apple Health, and (2) import calories burned from HealthKit after the workout. The existing `HealthKitService` already has basic export capability; this task extends it with calorie import and automatic sync.

<requirements>
- Auto-export workouts to HealthKit after completion (if authorized)
- Import calories from HealthKit after workout (with 5s delay for sync)
- Update workout history entry with HealthKit data
- Store HealthKit workout UUID for tracking
- Handle authorization denied gracefully
</requirements>

## Subtasks

- [x] 7.1 Add `fetchCaloriesForWorkout` method to HealthKitService
- [x] 7.2 Create `SyncWorkoutWithHealthKitUseCase`
- [x] 7.3 Implement automatic export on workout completion
- [x] 7.4 Implement calorie import with 5s delay
- [x] 7.5 Update SDWorkoutHistoryEntry with HealthKit data
- [x] 7.6 Add `healthKitSyncEnabled` user preference
- [x] 7.7 Handle edge cases (no Apple Watch, authorization denied)
- [x] 7.8 Write unit tests with mock HealthKit service

## Implementation Details

Reference **techspec.md** section "Integration Points > Apple HealthKit" for the complete flow:

```swift
func completeWorkout(
    plan: WorkoutPlan,
    rating: WorkoutRating?,
    completedAt: Date
) async throws {
    // 1. Save to local history
    let entry = await saveToHistory(plan, rating: rating, completedAt: completedAt)

    // 2. Export to HealthKit (if authorized)
    if await healthKitService.authorizationState() == .authorized {
        let receipt = try await healthKitService.exportWorkout(plan: plan, completedAt: completedAt)

        // 3. Fetch calories from HealthKit (after ~5s for sync)
        try await Task.sleep(for: .seconds(5))
        let metrics = try await healthKitService.fetchWorkouts(
            in: DateInterval(start: completedAt.addingTimeInterval(-3600), end: completedAt)
        )

        if let matched = metrics.first(where: { $0.workoutUUID == receipt.workoutUUID }) {
            await updateEntryWithHealthKitData(entry, calories: matched.caloriesBurned)
        }
    }
}
```

### HealthKit Sync Flow

```
Workout Completed
       │
       ▼
┌──────────────────┐     ┌──────────────────┐
│ Save to History  │────▶│ HealthKit Auth?  │
└──────────────────┘     └────────┬─────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                 Authorized                   Denied
                    │                           │
                    ▼                           ▼
           ┌────────────────┐          ┌────────────────┐
           │ Export Workout │          │ Skip HealthKit │
           └───────┬────────┘          └────────────────┘
                   │
                   ▼
           ┌────────────────┐
           │  Wait 5 sec    │
           └───────┬────────┘
                   │
                   ▼
           ┌────────────────┐
           │ Fetch Calories │
           └───────┬────────┘
                   │
                   ▼
           ┌────────────────┐
           │ Update Entry   │
           └────────────────┘
```

## Success Criteria

- [x] Workouts auto-export to HealthKit when authorized
- [x] Calories imported from HealthKit after workout
- [x] History entry updated with actual calories (not estimated)
- [x] HealthKit UUID stored in entry for tracking
- [x] Graceful handling when HealthKit denied
- [x] No blocking/freezing during sync (async)
- [x] Unit tests pass with mock HealthKit service

## Dependencies

- Task 1.0: SDWorkoutHistoryEntry with HealthKit fields

## Notes

- 5-second delay is necessary for Apple Watch data to sync
- Use background task for calorie fetch (don't block UI)
- If calorie fetch fails, entry still saved (just without calories)
- Consider retry logic for calorie fetch (max 2 retries)

## Relevant Files

### Files to Modify
- `/FitToday/Data/Services/HealthKit/HealthKitService.swift`
- `/FitToday/Domain/UseCases/CompleteWorkoutSessionUseCase.swift`
- `/FitToday/Data/Repositories/SwiftDataWorkoutHistoryRepository.swift`

### Files to Create
- `/FitToday/Domain/UseCases/SyncWorkoutWithHealthKitUseCase.swift`
- `/FitTodayTests/Domain/UseCases/SyncWorkoutWithHealthKitUseCaseTests.swift`
