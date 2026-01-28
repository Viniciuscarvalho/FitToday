# Implementation Plan: FitToday Pivot - Fase 1

## Overview

**Total Tasks**: 19
**Estimated Duration**: ~17.5 days
**Priority Focus**: Balanced (Fixes P0 + Group Streaks)

---

## Sprint 1: Technical Fixes (Days 1-4)

### Goal
Resolve immediate issues with workout generation and exercise images.

### Tasks
1. **Task 1**: Include exercise catalog in OpenAI prompt
2. **Task 2**: Diversify cache key with history hash
3. **Task 3**: Add 5s timeout to media resolution
4. **Task 4**: Expand PT→EN translation dictionary

### Verification
- Generate 10 consecutive workouts → 90%+ correct images
- Generate 5 workouts same day → all different
- No media resolution > 5s

---

## Sprint 2: Group Streaks Backend (Days 5-9)

### Goal
Build the data layer and business logic for Group Streaks.

### Tasks
5. **Task 5**: Create domain models (GroupStreakWeek, MemberWeeklyStatus, etc.)
6. **Task 6**: Create Firebase DTOs
7. **Task 7**: Create GroupStreakRepository protocol and implementation
8. **Task 8**: Create UpdateGroupStreakUseCase
9. **Task 9**: Integrate streak tracking into SyncWorkoutCompletionUseCase

### Verification
- Models compile with Swift 6 strict concurrency
- Repository tests pass with mocks
- Completing workout increments workoutCount

---

## Sprint 3: Cloud Functions (Days 10-13)

### Goal
Implement server-side automation for weekly evaluation and notifications.

### Tasks
10. **Task 11**: Create weekly evaluation function (Sunday 23:59 UTC)
11. **Task 12**: Create weekly record creation function (Monday 00:00 UTC)
12. **Task 13**: Create at-risk notification function (Thursday 18:00 UTC)

### Verification
- Functions deploy successfully
- Emulator tests pass
- Notifications sent correctly

---

## Sprint 4: UI (Days 14-17)

### Goal
Build the user interface for Group Streaks.

### Tasks
13. **Task 14**: Create GroupStreakViewModel
14. **Task 15**: Create GroupStreakCardView
15. **Task 16**: Create GroupStreakDetailView
16. **Task 17**: Create MilestoneOverlayView
17. **Task 18**: Integrate into GroupDashboardView
18. **Task 10**: Create PauseGroupStreakUseCase

### Verification
- UI renders correctly on all device sizes
- Navigation works as expected
- Milestone overlay appears when triggered

---

## Sprint 5: Testing & Finalization (Day 17.5+)

### Goal
Ensure quality and prepare for release.

### Tasks
19. **Task 19**: Integration tests and coverage

### Verification
- `swift test` passes
- No Swift 6 concurrency warnings
- 80%+ coverage on business logic

---

## Critical Path

```
Task 1 (Prompt) ─────────┐
Task 2 (Cache) ─────────┤
Task 3 (Timeout) ───────┤
Task 4 (Translations) ──┴──► Sprint 1 Done

Task 5 (Models) ────────┐
Task 6 (DTOs) ──────────┤
                        │
Task 7 (Repository) ────┼──► Task 8 (UseCase) ──► Task 9 (Sync)
                        │         │
                        │         ▼
                        │    Task 11 (Eval)
                        │    Task 12 (Create)
                        │    Task 13 (Notify)
                        │
                        └──► Task 14 (VM) ──► Task 15 (Card)
                                  │               │
                                  ▼               ▼
                             Task 16 (Detail) ◄───┘
                                  │
                                  ▼
                             Task 17 (Milestone)
                                  │
                                  ▼
                             Task 18 (Dashboard)
                                  │
                                  ▼
                             Task 19 (Tests)
```

---

## Risk Management

### High Risk
- **Cloud Function scheduling**: Test with emulator before production
- **Firestore security rules**: Define before any writes

### Medium Risk
- **UTC week boundaries**: Use ISO 8601 calendar consistently
- **Notification delivery**: Test across time zones

### Low Risk
- **UI layout**: Preview on multiple devices during development

---

## Rollback Plan

If critical issues arise:
1. Disable Cloud Functions via Firebase Console
2. Feature flag for Group Streaks UI (hide card)
3. Technical fixes can remain as they improve existing functionality

---

## Definition of Done

- [ ] All 19 tasks completed
- [ ] `swift test` passes
- [ ] Build succeeds without warnings
- [ ] All acceptance criteria verified
- [ ] PR created with comprehensive description
