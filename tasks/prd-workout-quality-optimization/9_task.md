# [9.0] Implement UserStatsCalculator service (M)

## status: pending

<task_context>
<domain>domain/services</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_2,task_7</dependencies>
</task_context>

# Task 9.0: Implement UserStatsCalculator service

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement the `UserStatsCalculator` service that computes user statistics including workout streaks, weekly totals, and monthly aggregates. The service updates the `SDUserStats` model and provides data for the stats dashboard.

<requirements>
- Calculate current workout streak (consecutive days)
- Calculate weekly stats (workouts, minutes, calories)
- Calculate monthly stats (workouts, minutes, calories)
- Update SDUserStats model after each workout
- Handle timezone correctly for streak calculation
- Optimize for performance (<100ms calculation)
</requirements>

## Subtasks

- [ ] 9.1 Create `UserStatsCalculating` protocol
- [ ] 9.2 Create `WeeklyStats` and `MonthlyStats` structs
- [ ] 9.3 Implement `UserStatsCalculator` concrete class
- [ ] 9.4 Implement streak calculation with gap detection
- [ ] 9.5 Implement weekly aggregation
- [ ] 9.6 Implement monthly aggregation
- [ ] 9.7 Create `UpdateUserStatsUseCase`
- [ ] 9.8 Trigger stats update after workout completion
- [ ] 9.9 Write comprehensive unit tests for edge cases

## Implementation Details

Reference **techspec.md** section "Core Interfaces" for the protocol:

```swift
protocol UserStatsCalculating: Sendable {
    func calculateCurrentStreak(from history: [WorkoutHistoryEntry]) -> Int
    func calculateWeeklyStats(from history: [WorkoutHistoryEntry]) -> WeeklyStats
    func calculateMonthlyStats(from history: [WorkoutHistoryEntry]) -> MonthlyStats
}

struct WeeklyStats: Codable, Sendable {
    let weekStartDate: Date
    let workoutsCompleted: Int
    let totalDurationMinutes: Int
    let totalCaloriesBurned: Int
    let averageRating: Double?
}
```

### Streak Calculation Rules

```swift
func calculateCurrentStreak(from history: [WorkoutHistoryEntry]) -> Int {
    // Sort by date descending
    let sorted = history.sorted { $0.date > $1.date }

    // Check if most recent workout is today or yesterday
    guard let mostRecent = sorted.first else { return 0 }

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let mostRecentDay = calendar.startOfDay(for: mostRecent.date)

    let daysDiff = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0

    // If last workout was more than 1 day ago, streak is broken
    if daysDiff > 1 { return 0 }

    // Count consecutive days backwards
    var streak = 0
    var checkDate = mostRecentDay

    for entry in sorted {
        let entryDay = calendar.startOfDay(for: entry.date)
        let diff = calendar.dateComponents([.day], from: entryDay, to: checkDate).day ?? 0

        if diff == 0 {
            // Same day, continue
            continue
        } else if diff == 1 {
            // Consecutive day
            streak += 1
            checkDate = entryDay
        } else {
            // Gap found, stop
            break
        }
    }

    return streak + 1  // Include today/yesterday
}
```

### Aggregation Logic

| Period | Date Range | Metrics |
|--------|------------|---------|
| Weekly | Monday 00:00 to Sunday 23:59 | Count, Duration, Calories |
| Monthly | 1st 00:00 to last day 23:59 | Count, Duration, Calories |

## Success Criteria

- [ ] Streak calculated correctly for consecutive days
- [ ] Streak resets when gap > 1 day
- [ ] Weekly stats aggregate correctly
- [ ] Monthly stats aggregate correctly
- [ ] SDUserStats updated after workout completion
- [ ] Calculation completes in <100ms
- [ ] Unit tests cover all edge cases (empty history, gaps, timezone)

## Dependencies

- Task 2.0: SDUserStats model
- Task 7.0: HealthKit sync (for accurate calorie data)

## Notes

- Use `Calendar.current` with user's timezone
- Consider caching stats to avoid recalculation
- Week starts on Monday (ISO 8601)
- Handle nil calories gracefully (don't count as 0)

## Relevant Files

### Files to Create
- `/FitToday/Domain/Protocols/UserStatsCalculating.swift`
- `/FitToday/Domain/Services/UserStatsCalculator.swift`
- `/FitToday/Domain/Entities/WeeklyStats.swift`
- `/FitToday/Domain/Entities/MonthlyStats.swift`
- `/FitToday/Domain/UseCases/UpdateUserStatsUseCase.swift`
- `/FitTodayTests/Domain/Services/UserStatsCalculatorTests.swift`

### Files to Modify
- `/FitToday/Domain/UseCases/CompleteWorkoutSessionUseCase.swift`
- `/FitToday/Presentation/DI/AppContainer.swift`
