# Analysis: prd-activity-fix

## Issue 1: Mock Data in Activity Tab

### Root Cause
`WorkoutHistoryView` in `ActivityTabView.swift` line 187-194:
```swift
private func loadWorkouts() async {
    try? await Task.sleep(for: .milliseconds(500))
    workouts = MockWorkoutData.recentSessions  // <-- MOCK DATA
    isLoading = false
}
```

### Existing Infrastructure
- `WorkoutHistoryRepository` protocol in `Repositories.swift` with `listEntries(limit:offset:)`
- `SwiftDataWorkoutHistoryRepository` concrete implementation using SwiftData
- `HistoryViewModel` in `HistoryView.swift` already correctly uses this repository
- `HealthKitHistorySyncService.importExternalWorkouts()` imports Apple Health workouts with `source: .appleHealth`
- Repository returns ALL entries regardless of source, so Apple Health entries are included

### Fix Strategy
Replace mock data with repository call. Simple and direct.

## Issue 2: Mixed Language Exercise Descriptions

### Root Cause
1. Wger API sometimes returns descriptions in Spanish even when Portuguese is requested
2. `WgerExerciseInfo.description(for:)` correctly falls back PT -> EN -> nil
3. `ExerciseTranslationService` uses dictionary-based word replacement which can produce garbled results
4. After translation, no quality check validates the output

### Fix Strategy
Add post-translation validation: if translated text still contains foreign language patterns, use the Portuguese fallback message instead.
