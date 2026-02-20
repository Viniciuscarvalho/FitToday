# Product Requirements Document (PRD)

**Project Name:** FitToday — Production Bugfix Bundle
**Document Version:** 1.0
**Date:** 2026-02-19
**Author:** Feature-Marker Agent
**Status:** Approved

---

## Executive Summary

**Problem Statement:**
Four issues currently block the production release of the FitToday iOS app. Two cause hard crashes or data-quality regressions that immediately impact users; two cause visual artifacts that degrade perceived quality. Together they must be fixed before App Store submission.

**Proposed Solution:**
Targeted, minimal surgical fixes for each of the four issues — no architectural rework, no new features. Each fix addresses exactly the root cause identified during codebase analysis.

**Business Value:**
- Unblocks production release on the current branch (`feature/app-store-review-request`)
- Eliminates crash reports from Crashlytics and AppStore Connect
- Improves UI polish for App Store screenshot quality
- Ensures exercise descriptions are consistently in pt-BR for all users

**Success Metrics:**
- Zero crash on "Finalizar Treino" tap in 100 manual test runs
- No visual flick on rest-timer overlay presentation (tested on iPhone 14/15 devices)
- No navigation flick when opening Create Workout sheet
- Exercise descriptions displayed in pt-BR for both Program workouts and AI-generated workouts

**Target Launch:** Immediately after PR approval

---

## Project Overview

### Background
FitToday is an iOS 17+ fitness app (Swift 6, SwiftUI, MVVM + @Observable) that lets users execute AI-generated workouts, track history, and join social groups. The app is preparing for App Store release on branch `feature/app-store-review-request`.

### Current State
Four issues exist simultaneously on the active branch:

1. **CRASH (Issue #16)**: Tapping "Finalizar Treino" in `WorkoutExecutionView` crashes the app. Root cause: `WorkoutCompletionView` reads `@Environment(WorkoutTimerStore.self)` but `WorkoutExecutionView` never injects that object into its environment chain — it only creates a local `@State private var workoutTimerStore`. When the navigation destination resolves `WorkoutCompletionView`, the environment lookup finds no `WorkoutTimerStore` and produces a fatal environment-object crash.

2. **FLICK (Issue #15)**: The rest-timer overlay in `WorkoutExecutionView` uses a raw ZStack `if showRestTimer || restTimerStore.isActive` conditional rendered inside the outer ZStack. SwiftUI flickers because the overlay has no stable identity, the animation modifier is placed on the wrong container, and there is no Reduce Motion support.

3. **FLICK (Issue #14)**: Creating a new workout from the FAB button in `WorkoutTabView` or from the create tab in `TabRootView` presents `CreateWorkoutView` as a `.sheet`. The sheet contains its own `NavigationStack`. When the first keyboard/focus event fires on the TextField inside the sheet, SwiftUI re-renders the sheet content and may flicker during the initial presentation because the `NavigationStack` inside the sheet is created on presentation without a stable identity.

4. **MIXED LANGUAGE**: `ExerciseTranslationService.ensureLocalizedDescription(_:)` is an `actor` method but is called with `await` in an async context (`loadExerciseDescription`) in `WorkoutExecutionView`. However, the method signature is `func ensureLocalizedDescription(_ text: String, ...) -> String` — not `async`. The call `await translationService.ensureLocalizedDescription(instructions)` implies actor isolation hop but the function performs all logic synchronously inside the actor. More critically, CMS workout notes (`CMSWorkoutItem.notes`) are written by personal trainers in English (e.g., "Keep your back straight") and flow directly into `ExercisePrescription.exercise.instructions` without passing through the translation service. Program workout descriptions from Wger API are also in English and may bypass translation.

### Desired State
- "Finalizar Treino" navigates smoothly to the summary screen with correct workout time shown
- Rest timer overlay presents and dismisses with a smooth, flick-free animation
- Create Workout sheet opens smoothly without visual artifacts
- All exercise description/instruction text is displayed in pt-BR regardless of source

---

## Functional Requirements

### FR-001: Fix Workout Completion Crash [MUST]

**Description:**
`WorkoutCompletionView` must not crash when accessed from `WorkoutExecutionView`. The `WorkoutTimerStore` must be available in the environment when the summary screen is shown.

**Acceptance Criteria:**
- Tapping "Finalizar Treino" in `WorkoutExecutionView` navigates to `WorkoutCompletionView` without crashing
- The workout time displayed in `WorkoutCompletionView` is correct (either from the local execution timer or shows a default)
- The fix does not break the existing path from `WorkoutPlanView` → `WorkoutCompletionView`

**Priority:** CRITICAL
**Related Epic:** EPIC-001 Stability

---

### FR-002: Fix Rest Timer Overlay Visual Flick [MUST]

**Description:**
The rest timer overlay in `WorkoutExecutionView` must present and dismiss without visual flickering on iPhone 14/15 running iOS 17+.

**Acceptance Criteria:**
- Overlay appears with a smooth spring animation (no flick)
- Overlay dismisses with a smooth fade/scale animation
- Reduce Motion (`UIAccessibility.isReduceMotionEnabled`) produces a simple opacity transition instead of scale
- No layout jump when toggling the overlay visibility

**Priority:** HIGH
**Related Epic:** EPIC-002 Polish

---

### FR-003: Fix Navigation Flick on Create Workout [MUST]

**Description:**
Opening the Create Workout sheet from the FAB button or the create tab must not produce visual artifacts or flickers on iPhone 14/15 running iOS 17+.

**Acceptance Criteria:**
- Sheet presents smoothly without any frame flash
- The `NavigationStack` inside the sheet renders its initial content without a flick on first appearance
- Keyboard presentation inside the sheet does not cause layout reflow artifacts

**Priority:** HIGH
**Related Epic:** EPIC-002 Polish

---

### FR-004: Normalize Exercise Descriptions to pt-BR [MUST]

**Description:**
Exercise instructions/descriptions displayed during workout execution must always be in Portuguese (pt-BR), regardless of their source (Wger API, CMS personal-trainer notes, OpenAI-generated workouts).

**Acceptance Criteria:**
- CMS workout notes (English from personal trainer) are translated to pt-BR before display
- AI-generated workout instructions containing English text are translated to pt-BR
- Program workout (Wger) descriptions already handled by `ExerciseTranslationService` continue to work
- Translation happens transparently — users see only Portuguese text
- If translation produces an empty result, a fallback Portuguese string is shown

**Priority:** HIGH
**Related Epic:** EPIC-003 Localization

---

## Non-Functional Requirements

### NFR-001: No Regressions [MUST]
All existing tests must continue to pass after the changes.

### NFR-002: Swift 6 Concurrency [MUST]
All new or modified code must compile without concurrency warnings under Swift 6 strict concurrency.

### NFR-003: Minimal Diff [MUST]
Each fix must be the smallest possible change that addresses the root cause. No refactoring of unrelated code.

---

## Out of Scope

1. Full UI redesign of the rest timer overlay — only fix the flick
2. Cloud-based translation API — local dictionary translation only
3. Adding new exercise descriptions to the database
4. UITests
5. Any changes to the WorkoutSessionStore architecture

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| WorkoutTimerStore fix breaks WorkoutPlanView path | High | Low | Explicit testing of both navigation paths |
| Translation service changes break existing tests | Medium | Low | ExerciseTranslationServiceTests must pass unchanged |
| Sheet fix interferes with keyboard avoidance | Low | Low | Test with and without keyboard |
