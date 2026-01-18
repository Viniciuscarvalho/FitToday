# [2.0] Create SDUserStats model for aggregated metrics (S)

## status: completed

<task_context>
<domain>data/models</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies>swiftdata</dependencies>
</task_context>

# Task 2.0: Create SDUserStats model for aggregated metrics

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create a new SwiftData model `SDUserStats` to store pre-calculated user statistics including workout streaks, weekly totals, and monthly aggregates. This singleton model improves performance by avoiding recalculation on every History tab access.

<requirements>
- Create SDUserStats as a singleton model (id = "current")
- Store streak data (current, longest, last workout date)
- Store weekly aggregates (workouts count, minutes, calories)
- Store monthly aggregates (workouts count, minutes, calories)
- Include lastUpdatedAt timestamp for cache validation
</requirements>

## Subtasks

- [ ] 2.1 Create `SDUserStats` SwiftData model with all fields
- [ ] 2.2 Add Date extension helpers (`startOfWeek`, `startOfMonth`)
- [ ] 2.3 Create `UserStats` domain entity
- [ ] 2.4 Create mapper between SD model and domain entity
- [ ] 2.5 Add repository protocol `UserStatsRepository`
- [ ] 2.6 Implement `SwiftDataUserStatsRepository`
- [ ] 2.7 Register model in SwiftData container
- [ ] 2.8 Write unit tests for model and mapping

## Implementation Details

Reference **techspec.md** section "Data Models" for the complete SDUserStats structure:

```swift
@Model
final class SDUserStats {
    @Attribute(.unique) var id: String  // "current" (singleton)

    // Streak
    var currentStreak: Int
    var longestStreak: Int
    var lastWorkoutDate: Date?

    // Weekly aggregates
    var weekStartDate: Date
    var weekWorkoutsCount: Int
    var weekTotalMinutes: Int
    var weekTotalCalories: Int

    // Monthly aggregates
    var monthStartDate: Date
    var monthWorkoutsCount: Int
    var monthTotalMinutes: Int
    var monthTotalCalories: Int

    // Metadata
    var lastUpdatedAt: Date
}
```

## Success Criteria

- [ ] `SDUserStats` model created with all fields from techspec
- [ ] Model registered in SwiftData ModelContainer
- [ ] `UserStats` domain entity created
- [ ] Repository protocol and implementation exist
- [ ] Date helpers work correctly for week/month boundaries
- [ ] Unit tests pass
- [ ] App builds and runs without SwiftData errors

## Dependencies

- None (can be developed in parallel with Task 1.0)

## Notes

- Use singleton pattern with `id = "current"` to ensure only one stats record
- Week starts on Monday (use `Calendar.current` with proper locale)
- Initialize all numeric fields to 0 in the initializer
- Consider timezone handling for streak calculation

## Relevant Files

### Files to Create
- `/FitToday/Data/Models/SDUserStats.swift`
- `/FitToday/Domain/Entities/UserStats.swift`
- `/FitToday/Domain/Protocols/UserStatsRepository.swift`
- `/FitToday/Data/Repositories/SwiftDataUserStatsRepository.swift`
- `/FitToday/Extensions/Date+Helpers.swift` (if not exists)
- `/FitTodayTests/Data/Models/SDUserStatsTests.swift`

### Files to Modify
- `/FitToday/App/FitTodayApp.swift` (register model in container)
- `/FitToday/Presentation/DI/AppContainer.swift` (register repository)
