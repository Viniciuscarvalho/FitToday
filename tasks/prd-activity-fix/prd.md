# Product Requirements Document (PRD)

**Project Name:** FitToday - Activity Tab Fix & Exercise Description Normalization
**Document Version:** 1.0
**Date:** 2026-02-19
**Author:** Feature-Marker Agent
**Status:** Draft

---

## Executive Summary

**Problem Statement:**
Two bugs impact user experience in the Activity tab and exercise display:
1. The "Treinos Recentes" section in the Activity tab shows hardcoded mock workouts (Push Day, Pull Day, Leg Day) instead of the user's real workout history. Users see fake data they never performed.
2. Exercise descriptions from the Wger API arrive with mixed Spanish/English text. The existing `ExerciseTranslationService` dictionary-based translation produces incomplete or messy results, leaving fragments in the wrong language visible to users.

**Proposed Solution:**
- **Issue 1:** Replace `MockWorkoutData.recentSessions` in `WorkoutHistoryView` with real data from `WorkoutHistoryRepository`. If no app workouts exist, fallback to Apple Health imported workouts. If neither exists, show the existing empty state view.
- **Issue 2:** Improve the exercise description handling by stripping non-Portuguese/English descriptions at the API layer and enhancing the `ExerciseTranslationService` to better handle edge cases where mixed-language fragments slip through.

**Business Value:**
- Users see their actual workout history, building trust and engagement
- Exercise descriptions are clean and consistently in the user's language
- Eliminates tester-reported issues blocking release

**Success Metrics:**
- Activity tab shows only user-registered workouts or Apple Health workouts (zero mock data)
- Empty state shown when no workouts exist
- Exercise descriptions display in pt-BR without Spanish fragments

**Target Launch:** Current sprint

---

## Project Overview

### Background
FitToday is an iOS 17+ fitness app using Swift 6, SwiftUI, MVVM + @Observable. The Activity tab was recently redesigned with a calendar and "Treinos Recentes" section, but the data loading function still uses mock data from development. Meanwhile, exercise descriptions from the Wger API sometimes contain Spanish text due to the API's translation coverage gaps.

### Current State

**Issue 1 - Mock data in Activity tab:**
- `WorkoutHistoryView` in `ActivityTabView.swift` (line 187-194) calls `loadWorkouts()` which uses `MockWorkoutData.recentSessions` - a hardcoded array of 3 fake workouts
- The existing `HistoryView.swift` with `HistoryViewModel` correctly uses `WorkoutHistoryRepository` via SwiftData - this pattern should be reused
- `HealthKitHistorySyncService.importExternalWorkouts()` already imports Apple Health workouts with `source: .appleHealth`

**Issue 2 - Mixed language descriptions:**
- `WgerExerciseInfo.description(for:)` correctly filters to Portuguese -> English -> nil fallback
- `ExerciseTranslationService.ensureLocalizedDescription()` does dictionary-based word replacement
- The dictionary approach produces fragmented translations (e.g., "mantenha o costas reto" instead of proper Portuguese)
- Some descriptions still arrive with Spanish words when the API returns mixed-language content

### Desired State
- Activity tab "Treinos Recentes" shows real user workouts from `WorkoutHistoryRepository`
- If user has no app workouts, show Apple Health imported workouts (source == .appleHealth)
- If no workouts at all, show the empty state view
- Calendar highlights real workout days
- Exercise descriptions are consistently in Portuguese without foreign language fragments

---

## Functional Requirements

### FR-001: Replace Mock Data with Real Workout History [MUST]

**Description:**
`WorkoutHistoryView` must load workouts from `WorkoutHistoryRepository` instead of `MockWorkoutData`.

**Acceptance Criteria:**
- Workouts displayed are from the user's SwiftData history
- Data loads with pagination support (reuse existing `listEntries(limit:offset:)`)
- Calendar highlights actual workout days
- Loading state shown during data fetch
- Pull-to-refresh supported

**Priority:** CRITICAL

---

### FR-002: Fallback to Apple Health Workouts [SHOULD]

**Description:**
When no app-registered workouts exist, show workouts imported from Apple Health.

**Acceptance Criteria:**
- If `WorkoutHistoryRepository.listEntries()` returns empty, check for entries with `source == .appleHealth`
- Apple Health workouts display with a heart icon indicator (already implemented in `WorkoutSessionCard`)
- If no Apple Health workouts either, show empty state

**Priority:** HIGH

---

### FR-003: Clean Empty State [MUST]

**Description:**
When no workouts exist from any source, display the empty state view.

**Acceptance Criteria:**
- Empty state shows the existing design (icon + message)
- Message encourages user to complete their first workout
- No mock or placeholder data visible

**Priority:** HIGH

---

### FR-004: Improve Exercise Description Language Consistency [MUST]

**Description:**
Exercise descriptions must not show mixed Spanish/English fragments to users.

**Acceptance Criteria:**
- Descriptions from Wger API that cannot be properly translated show the Portuguese fallback message instead of garbled mixed-language text
- The `ExerciseTranslationService` better detects when translation quality is poor and falls back
- No Spanish words visible in exercise descriptions

**Priority:** HIGH

---

## Non-Functional Requirements

### NFR-001: No Regressions
All existing tests must pass. The `HistoryView` (separate from Activity tab) must continue working unchanged.

### NFR-002: Minimal Diff
Changes should be surgical - replace mock data loading, improve translation edge cases. No architectural rework.

### NFR-003: Swift 6 Concurrency
All new/modified code must compile without concurrency warnings.

---

## Out of Scope

1. Redesigning the Activity tab layout
2. Cloud-based translation API integration
3. Adding new workout types or session models
4. Changes to `HistoryView.swift` or `HistoryViewModel.swift`
5. UITests

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| WorkoutHistoryRepository not registered in Activity tab DI | High | Medium | Check Swinject container registration |
| Performance with large workout history | Medium | Low | Use existing pagination (limit/offset) |
| Translation fallback too aggressive | Low | Medium | Only fallback when Spanish pattern detected AND translation produces poor quality |
