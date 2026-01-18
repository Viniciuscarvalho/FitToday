# [1.0] Expand SDWorkoutHistoryEntry with userRating field (S)

## status: completed

<task_context>
<domain>data/models</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies>swiftdata</dependencies>
</task_context>

# Task 1.0: Expand SDWorkoutHistoryEntry with userRating field

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Extend the existing `SDWorkoutHistoryEntry` SwiftData model to include a new `userRating` field that stores the user's feedback about each completed workout. This is a foundational task that enables the feedback system.

<requirements>
- Add `userRating: String?` field to SDWorkoutHistoryEntry
- Add `completedExercisesJSON: Data?` field for tracking completed exercises
- Ensure backward compatibility with existing data
- SwiftData handles migration automatically for optional fields
</requirements>

## Subtasks

- [ ] 1.1 Add `userRating: String?` field to `SDWorkoutHistoryEntry`
- [ ] 1.2 Add `completedExercisesJSON: Data?` field for exercise tracking
- [ ] 1.3 Create `WorkoutRating` enum in Domain layer
- [ ] 1.4 Add helper methods for rating conversion (String ↔ WorkoutRating)
- [ ] 1.5 Update `WorkoutHistoryEntry` domain entity with rating field
- [ ] 1.6 Update mapper between SD model and domain entity
- [ ] 1.7 Write unit tests for new fields and mapping

## Implementation Details

Reference **techspec.md** section "Data Models" for the exact field definitions:

```swift
enum WorkoutRating: String, Codable, CaseIterable, Sendable {
    case tooEasy = "too_easy"
    case adequate = "adequate"
    case tooHard = "too_hard"
}
```

The `userRating` field stores raw string values ("too_easy", "adequate", "too_hard") for flexibility.

## Success Criteria

- [ ] `SDWorkoutHistoryEntry` has `userRating: String?` field
- [ ] `SDWorkoutHistoryEntry` has `completedExercisesJSON: Data?` field
- [ ] `WorkoutRating` enum exists in Domain layer
- [ ] Existing workout history data is preserved (no migration errors)
- [ ] Unit tests pass for field mapping
- [ ] App builds and runs without SwiftData errors

## Dependencies

- None (this is a foundational task)

## Notes

- SwiftData automatically handles schema evolution for new optional fields
- Use `String?` instead of enum directly for storage flexibility
- The `completedExercisesJSON` stores serialized `[CompletedExercise]` array

## Relevant Files

### Files to Modify
- `/FitToday/Data/Models/SDWorkoutHistoryEntry.swift`
- `/FitToday/Domain/Entities/HistoryModels.swift` (if WorkoutHistoryEntry exists here)
- `/FitToday/Data/Mappers/WorkoutHistoryMapper.swift` (if exists)

### Files to Create
- `/FitToday/Domain/Entities/WorkoutRating.swift`
- `/FitTodayTests/Data/Models/SDWorkoutHistoryEntryTests.swift`
