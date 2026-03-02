# Task 6.0: ChatSystemPromptBuilder (M)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create a builder that constructs a personalized system prompt injecting user context (profile, stats, recent workouts).

<requirements>
- Sendable struct with section-based prompt assembly
- Handles nil profile/stats gracefully (generic fallback)
- Output under ~2000 tokens
- Persona: motivador, direto, baseado em ciencia
</requirements>

## Subtasks

- [ ] 6.1 Create `Data/Services/OpenAI/ChatSystemPromptBuilder.swift`:
  ```swift
  struct ChatSystemPromptBuilder: Sendable {
      func buildSystemPrompt(
          profile: UserProfile?,
          stats: UserStats?,
          recentWorkouts: [WorkoutHistoryEntry]
      ) -> String
  }
  ```
- [ ] 6.2 Implement private section methods:
  - `basePersonality()` — FitOrb persona: friendly, motivating, concise, science-based
  - `userProfileSection(_ profile: UserProfile)` — goal, level, equipment, health conditions, frequency
  - `userStatsSection(_ stats: UserStats)` — currentStreak, weekWorkoutsCount, weekTotalCalories, lastWorkoutDate
  - `recentWorkoutsSection(_ workouts: [WorkoutHistoryEntry])` — last 3: title, focus, duration, calories
  - `responseGuidelines()` — respond in user's language, max 300 words, use markdown for structure
- [ ] 6.3 Write `FitTodayTests/Data/Services/OpenAI/ChatSystemPromptBuilderTests.swift`:
  - Test: full profile produces prompt with goal, level, equipment
  - Test: nil profile falls back to generic (no personal data sections)
  - Test: stats section includes streak and weekly data
  - Test: recent workouts included with title and focus
  - Test: empty workouts array omits that section
  - Test: output is non-empty and reasonable length

## Implementation Details

- **Pattern**: Follow `Data/Services/OpenAI/NewWorkoutPromptBuilder.swift` structure
- **Sections joined**: `sections.joined(separator: "\n\n")`
- **Profile data**: Use `UserProfile.mainGoal.rawValue`, `.level.rawValue`, `.availableStructure.rawValue`
- **Stats data**: Use `UserStats.currentStreak`, `.weekWorkoutsCount`, `.weekTotalCalories`
- **Workout data**: Use `WorkoutHistoryEntry.title`, `.focus.rawValue`, `.durationMinutes`, `.caloriesBurned`

## Success Criteria

- Produces coherent prompt with user context
- Handles nil inputs without crash
- All 6 tests pass
- Project builds

## Relevant Files
- `Data/Services/OpenAI/NewWorkoutPromptBuilder.swift` — pattern reference
- `Domain/Entities/UserProfile.swift` — profile fields
- `Domain/Entities/UserStats.swift` — stats fields
- `Domain/Entities/HistoryModels.swift` — workout history fields

## Dependencies
- None (can run in parallel with all Phase 1 tasks)

## status: pending

<task_context>
<domain>data</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>none</dependencies>
</task_context>
