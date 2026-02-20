# Technical Specification

**Feature:** Activity Tab Fix & Exercise Description Normalization
**PRD Reference:** prd-activity-fix/prd.md
**Date:** 2026-02-19
**Status:** Draft

---

## Architecture Overview

### Current Architecture
- **Activity Tab**: `ActivityTabView` -> `WorkoutHistoryView` (uses mock data)
- **History Tab**: `HistoryView` -> `HistoryViewModel` -> `WorkoutHistoryRepository` (uses real data)
- **Translation**: `ExerciseTranslationService` (actor, dictionary-based EN/ES -> PT)
- **HealthKit**: `HealthKitHistorySyncService` imports external workouts with `source: .appleHealth`

### Target Architecture
- **Activity Tab**: `ActivityTabView` -> `WorkoutHistoryView` (uses `WorkoutHistoryRepository`)
- **Translation**: `ExerciseTranslationService` with improved mixed-language detection

---

## Technical Changes

### Change 1: Replace Mock Data in WorkoutHistoryView

**File:** `FitToday/Presentation/Features/Activity/Views/ActivityTabView.swift`

**What changes:**
1. Add `WorkoutHistoryRepository` dependency via `Resolver` (same pattern as `HistoryView`)
2. Replace `loadWorkouts()` to fetch from repository instead of `MockWorkoutData`
3. Convert `WorkoutHistoryEntry` to `UnifiedWorkoutSession` for display (or use `WorkoutHistoryEntry` directly with adapted card)
4. Remove `MockWorkoutData` enum

**Data flow:**
```
WorkoutHistoryView
  -> resolver.resolve(WorkoutHistoryRepository.self)
  -> repository.listEntries(limit: 20, offset: 0)
  -> Convert to display model
  -> Show in WorkoutSessionCard or HistoryRow
```

**Key decision:** Rather than converting `WorkoutHistoryEntry` to `UnifiedWorkoutSession`, adapt `WorkoutHistoryView` to display `WorkoutHistoryEntry` directly using `HistoryRow` (already exists in `HistoryView.swift`). This avoids creating unnecessary conversion logic.

**Alternative considered:** Reuse `HistoryViewModel` directly. Rejected because `WorkoutHistoryView` has its own calendar integration and different layout requirements.

### Change 2: Fallback Logic for Empty State

**File:** `FitToday/Presentation/Features/Activity/Views/ActivityTabView.swift`

**Logic:**
```swift
func loadWorkouts() async {
    let entries = try await repository.listEntries(limit: 20, offset: 0)
    if entries.isEmpty {
        // All entries include Apple Health imports already
        // Repository returns all sources, so empty truly means empty
    }
    workouts = entries
    isLoading = false
}
```

Note: `SwiftDataWorkoutHistoryRepository.listEntries()` already returns ALL entries including Apple Health imported ones (no source filter). So if the list is empty, it truly means no workouts from any source.

### Change 3: Improve Exercise Description Translation

**File:** `FitToday/Data/Services/Translation/ExerciseTranslationService.swift`

**What changes:**
1. After dictionary translation, check if result still contains Spanish patterns
2. If Spanish patterns remain after translation, use Portuguese fallback instead of garbled text
3. Add quality check: if translated text has too many untranslated foreign words, fallback

**Logic:**
```swift
func ensureLocalizedDescription(_ text: String, ...) -> String {
    // ... existing detection logic ...

    // After translation, validate quality
    let translated = translateToPortuguese(text, from: lang)

    // If translation still contains foreign patterns, use fallback
    if containsSpanishPatterns(translated) || containsEnglishPatterns(translated) {
        return getPortugueseFallback()
    }

    return translated
}
```

### Change 4: Remove MockWorkoutData

**File:** `FitToday/Presentation/Features/Activity/Views/ActivityTabView.swift`

Delete the `MockWorkoutData` enum entirely (lines 495-519).

---

## Files Modified

| File | Change Type | Description |
|------|------------|-------------|
| `ActivityTabView.swift` | Modified | Replace mock data with repository, remove MockWorkoutData |
| `ExerciseTranslationService.swift` | Modified | Add post-translation quality check |

## Files NOT Modified

| File | Reason |
|------|--------|
| `HistoryView.swift` | Different feature, works correctly |
| `HistoryViewModel.swift` | Not shared with Activity tab |
| `WgerAPIService.swift` | Already correctly filters languages |
| `WgerModels.swift` | Description fallback already correct |

---

## Testing Strategy

### Unit Tests
- Verify `ExerciseTranslationService` returns fallback when translation produces mixed-language text
- Existing `ExerciseTranslationServiceTests` must pass unchanged

### Manual Tests
- Open Activity tab with no workouts -> see empty state
- Complete a workout -> see it in Activity tab
- Import Apple Health workouts -> see them with heart icon
- Verify exercise descriptions show no Spanish/English fragments

---

## Dependencies

- `WorkoutHistoryRepository` must be registered in Swinject container (already is for `HistoryView`)
- No new packages or dependencies needed
