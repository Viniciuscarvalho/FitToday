# Tasks — Sistema de Streaks & XP com Níveis (PRO-90)

## Summary

| Task | Title                                 | Size | Status |
| ---- | ------------------------------------- | ---- | ------ |
| 1.0  | Domain Entities + Feature Flag        | S    | done   |
| 2.0  | XP Repository (SwiftData + Firestore) | M    | done   |
| 3.0  | AwardXP Use Case                      | M    | done   |
| 4.0  | Home Screen XP Level Card             | M    | done   |
| 5.0  | Level-Up Celebration View             | M    | done   |
| 6.0  | Workout Completion Integration        | S    | done   |
| 7.0  | Unit Tests                            | M    | done   |

---

# Task 1.0: Domain Entities + Feature Flag (S)

<critical>Read the prd.md and techspec.md files in this folder.</critical>

## Overview

Create the core domain entities for the XP/Level system and add the feature flag.

## Subtasks

- [ ] 1.1 Create `UserXP` struct in `Domain/Entities/UserXP.swift` with `totalXP`, `lastAwardDate`, computed `level`, `currentLevelXP`, `xpToNextLevel`, `levelProgress`, `levelTitle`
- [ ] 1.2 Create `XPLevel` enum in `Domain/Entities/XPLevel.swift` with cases (iniciante, guerreiro, tita, lenda, imortal), `init(level:)`, `icon`, `rawValue` (display name)
- [ ] 1.3 Create `XPTransaction` struct and `XPTransactionType` enum in `Domain/Entities/XPTransaction.swift` with static `xpAmount(for:)` method
- [ ] 1.4 Add `gamificationEnabled` case to `FeatureFlagKey` with default `false`

## Success Criteria

- All entities compile and follow project conventions (@Sendable, Codable)
- Feature flag registered with correct raw value and default
- No force unwraps, proper value types

## Dependencies

- None (foundational task)

## Relevant Files

- `FitToday/Domain/Entities/UserStats.swift` (reference for patterns)
- `FitToday/Domain/Entities/FeatureFlag.swift`
- `FitToday/Domain/Entities/GroupStreakModels.swift` (reference for similar enums)

---

# Task 2.0: XP Repository (SwiftData + Firestore) (M)

<critical>Read the prd.md and techspec.md files in this folder.</critical>

## Overview

Create the repository layer for XP persistence (local SwiftData + remote Firestore).

## Subtasks

- [ ] 2.1 Create `XPRepository` protocol in `Domain/Protocols/XPRepository.swift`
- [ ] 2.2 Create `SDUserXP` SwiftData model in `Data/Models/SDUserXP.swift` (singleton pattern with `id = "current"`)
- [ ] 2.3 Create `FBUserXP` Firestore DTO in `Data/DTOs/FBUserXP.swift`
- [ ] 2.4 Create `SwiftDataXPRepository` in `Data/Repositories/SwiftDataXPRepository.swift` implementing `XPRepository`
- [ ] 2.5 Register `SDUserXP` in the SwiftData ModelContainer (check existing registration pattern)
- [ ] 2.6 Register `XPRepository` in `AppContainer.swift`

## Success Criteria

- Repository reads/writes XP locally via SwiftData
- Firestore sync via existing `FirebaseUserService` (add XP fields to user document)
- Follows existing singleton pattern from `SDUserStats`

## Dependencies

- Task 1.0 (entities)

## Relevant Files

- `FitToday/Data/Models/SDUserStats.swift` (pattern reference)
- `FitToday/Data/Repositories/SwiftDataUserStatsRepository.swift` (pattern reference)
- `FitToday/Presentation/DI/AppContainer.swift`

---

# Task 3.0: AwardXP Use Case (M)

<critical>Read the prd.md and techspec.md files in this folder.</critical>

## Overview

Create the use case that awards XP after workout completion, calculates streak bonuses, and detects level-up.

## Subtasks

- [ ] 3.1 Create `XPAwardResult` struct with `previousLevel`, `newLevel`, `xpAwarded`, `totalXP`, `didLevelUp`
- [ ] 3.2 Create `AwardXPUseCase` in `Domain/UseCases/AwardXPUseCase.swift`
- [ ] 3.3 Implement `execute(type:currentStreak:)` method with XP calculation + streak bonus logic
- [ ] 3.4 Register `AwardXPUseCase` in `AppContainer.swift`

## Success Criteria

- Awards correct XP per transaction type (100 workout, 200 streak-7d, 500 streak-30d, 500 challenge)
- Correctly detects level-up (level before != level after)
- Returns complete `XPAwardResult`
- Pure business logic, no UI dependencies

## Dependencies

- Task 2.0 (repository)

## Relevant Files

- `FitToday/Domain/UseCases/UpdateUserStatsUseCase.swift` (pattern reference)

---

# Task 4.0: Home Screen XP Level Card (M)

<critical>Read the prd.md and techspec.md files in this folder.</critical>

## Overview

Create the XP/Level display component for the home screen and integrate with HomeViewModel.

## Subtasks

- [ ] 4.1 Create `XPLevelCard` view in `Presentation/Features/Home/Components/XPLevelCard.swift`
- [ ] 4.2 Add `userXP: UserXP?` and `isGamificationEnabled: Bool` to `HomeViewModel`
- [ ] 4.3 Load XP data in `HomeViewModel.loadUserData()` (gated by feature flag)
- [ ] 4.4 Add `XPLevelCard` to `HomeView` body after `WeekStreakRow` (gated by flag)

## Success Criteria

- Shows level number, nome temático, SF Symbol icon
- Progress bar with XP current / 1000
- Animates progress bar smoothly
- Hidden when `gamification_enabled` flag is off
- Follows FitToday design system (FitTodayColor, FitTodayFont, FitTodaySpacing)

## Dependencies

- Task 1.0 (entities)
- Task 2.0 (repository)

## Relevant Files

- `FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/Presentation/Features/Home/HomeViewModel.swift`
- `FitToday/Presentation/Features/Home/Components/WeekStreakRow.swift` (style reference)
- `FitToday/Presentation/Features/Home/Components/DailyStatsCard.swift` (style reference)

---

# Task 5.0: Level-Up Celebration View (M)

<critical>Read the prd.md and techspec.md files in this folder.</critical>

## Overview

Create the confetti celebration overlay for level-up moments during workout completion.

## Subtasks

- [ ] 5.1 Create `ConfettiView` using Canvas + TimelineView for particle animation
- [ ] 5.2 Create `LevelUpCelebrationView` overlay with new level, nome temático, confetti
- [ ] 5.3 Add auto-dismiss after 5s or on tap
- [ ] 5.4 Respect `accessibilityReduceMotion` (skip animation, show static)

## Success Criteria

- Confetti animation is smooth (60fps)
- Shows new level number + nome temático + icon
- Dismisses on tap or after 5s timeout
- Respects reduce motion accessibility setting
- Follows FitToday design system

## Dependencies

- Task 1.0 (entities for XPLevel display)

## Relevant Files

- `FitToday/Presentation/Features/Workout/WorkoutCompletionView.swift` (integration target)

---

# Task 6.0: Workout Completion Integration (S)

<critical>Read the prd.md and techspec.md files in this folder.</critical>

## Overview

Wire the XP award system into the existing workout completion flow.

## Subtasks

- [ ] 6.1 Add `AwardXPUseCase` dependency to `WorkoutCompletionView`
- [ ] 6.2 Call `AwardXPUseCase.execute()` after `UpdateUserStatsUseCase` in the completion task
- [ ] 6.3 Gate XP award behind `gamification_enabled` feature flag
- [ ] 6.4 Show `LevelUpCelebrationView` overlay when `didLevelUp == true`
- [ ] 6.5 Show XP earned summary in completion view ("+100 XP")

## Success Criteria

- XP awarded after every workout completion (when flag is on)
- Level-up celebration displays correctly
- Existing completion flow is not broken
- No performance regression (< 100ms added)

## Dependencies

- Task 3.0 (use case)
- Task 5.0 (celebration view)

## Relevant Files

- `FitToday/Presentation/Features/Workout/WorkoutCompletionView.swift`
- `FitToday/Domain/UseCases/UpdateUserStatsUseCase.swift`

---

# Task 7.0: Unit Tests (M)

<critical>Read the prd.md and techspec.md files in this folder.</critical>

## Overview

Write unit tests for all business logic: entities, use case, and repository.

## Subtasks

- [ ] 7.1 `UserXPTests` — test level calculation, progress, title mapping for various XP amounts
- [ ] 7.2 `XPLevelTests` — test all level ranges and icons
- [ ] 7.3 `AwardXPUseCaseTests` — test workout XP award, streak-7 bonus, streak-30 bonus, challenge bonus, level-up detection
- [ ] 7.4 `XPTransactionTests` — test `xpAmount(for:)` for all types

## Success Criteria

- 80%+ coverage on `UserXP`, `XPLevel`, `AwardXPUseCase`
- Tests use mocks/stubs for repository (follow existing `MockFeedRepository` pattern)
- All tests pass

## Dependencies

- Task 1.0, 2.0, 3.0

## Relevant Files

- `FitTodayTests/Presentation/Features/SocialFeed/SocialFeedViewModelTests.swift` (mock pattern reference)
