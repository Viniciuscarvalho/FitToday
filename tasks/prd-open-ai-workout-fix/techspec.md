# Technical Specification

**Project Name:** OpenAI Workout Generation Fix
**Version:** 1.0.0
**Date:** 2026-02-08
**Author:** AI Agent
**Status:** Draft

---

## Overview

### Problem Statement
1. Exercises in generated workouts cannot be tapped for navigation or deleted
2. OpenAI workout generation produces identical workouts due to aggressive caching and low temperature

### Proposed Solution
1. Fix gesture handling in exercise rows for proper navigation
2. Add swipe-to-delete for generated workout exercises
3. Increase temperature, reduce cache TTL, and add explicit randomization seeds

### Goals
- 100% of exercises are tappable with proper navigation
- Users can remove unwanted exercises from generated workouts
- Each workout generation produces unique exercise combinations

---

## Scope

### In Scope
- Fix exercise tap gesture in `PhaseSectionView`
- Add exercise deletion to generated workout views
- Modify `OpenAIConfiguration` for better variation
- Update `WorkoutBlueprint` variation seed logic
- Add cache invalidation for explicit regeneration

### Out of Scope
- Exercise reordering
- Exercise replacement suggestions
- Adding custom exercises to generated workouts

---

## Technical Approach

### Architecture Overview
The fix involves three layers:
1. **Presentation Layer**: UI fixes for gestures and delete actions
2. **Domain Layer**: Blueprint variation seed improvements
3. **Data Layer**: OpenAI configuration and cache management

---

## Component 1: Exercise Navigation Fix

### File: `PhaseSectionView.swift`

**Current Implementation (lines 45-48):**
```swift
.contentShape(Rectangle())
.onTapGesture {
    router.push(.workoutExercisePreview(prescription), on: .home)
}
```

**Issue:** The `LazyVStack` may interfere with gesture recognition. The `onTapGesture` may conflict with parent scroll view.

**Solution:**
```swift
WorkoutExerciseRow(
    index: localIndex,
    prescription: prescription,
    isCurrent: sessionStore.currentExerciseIndex == localIndex
)
.contentShape(Rectangle())
.onTapGesture {
    router.push(.workoutExercisePreview(prescription), on: .home)
}
.accessibilityHint("Toque para ver detalhes do exercício")
```

The current implementation appears correct. The issue may be in `WorkoutExerciseRow` itself. Need to ensure:
1. The row doesn't have `allowsHitTesting(false)`
2. No overlapping views blocking touches
3. Consider using `Button` instead of `onTapGesture` for better accessibility

**Recommended Change:**
```swift
Button {
    router.push(.workoutExercisePreview(prescription), on: .home)
} label: {
    WorkoutExerciseRow(
        index: localIndex,
        prescription: prescription,
        isCurrent: sessionStore.currentExerciseIndex == localIndex
    )
}
.buttonStyle(.plain)
```

---

## Component 2: Exercise Deletion

### File: `WorkoutSessionStore.swift`

**Add Method:**
```swift
func removeExercise(from phaseIndex: Int, exerciseIndex: Int) {
    guard var plan = plan else { return }
    guard phaseIndex < plan.phases.count else { return }

    var phase = plan.phases[phaseIndex]
    guard exerciseIndex < phase.items.count else { return }

    // Ensure at least 1 exercise remains in workout
    let totalExercises = plan.phases.flatMap { $0.items }.count
    guard totalExercises > 1 else { return }

    phase.items.remove(at: exerciseIndex)
    plan.phases[phaseIndex] = phase

    // Remove empty phases
    plan.phases.removeAll { $0.items.isEmpty }

    self.plan = plan
}
```

### File: `PhaseSectionView.swift`

**Add Swipe Action:**
```swift
case .exercise(let prescription):
    let localIndex = idx + 1
    WorkoutExerciseRow(
        index: localIndex,
        prescription: prescription,
        isCurrent: sessionStore.currentExerciseIndex == localIndex
    )
    .contentShape(Rectangle())
    .onTapGesture {
        router.push(.workoutExercisePreview(prescription), on: .home)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
        Button(role: .destructive) {
            removeExercise(at: idx)
        } label: {
            Label("Remover", systemImage: "trash")
        }
    }
```

**Note:** Swipe actions require being inside a `List`. May need to restructure `LazyVStack` to `List` with custom styling.

---

## Component 3: OpenAI Configuration Improvement

### File: `OpenAIConfiguration.swift`

**Current (lines 28-36):**
```swift
#if DEBUG
let temperature = 0.7
let cacheTTL: TimeInterval = 0
#else
let temperature = 0.3  // Too low - causes repetitive output
let cacheTTL: TimeInterval = 900  // 15 min - too long
#endif
```

**Proposed Change:**
```swift
#if DEBUG
let temperature = 0.7
let cacheTTL: TimeInterval = 0
#else
let temperature = 0.55  // Balanced: varied but coherent
let cacheTTL: TimeInterval = 300  // 5 minutes
#endif
```

---

## Component 4: Variation Seed Improvement

### File: `WorkoutBlueprint.swift`

**Current `cacheKey` (lines 276-300):**
```swift
var cacheKey: String {
    var components = [...]
    #if DEBUG
    components.append(String(minuteOfHour))
    components.append(String(secondOfMinute))
    #else
    components.append(String(minuteOfHour / 15))  // Only 4 buckets/hour
    #endif
    return components.joined(separator: ":")
}
```

**Proposed Change:**
```swift
var cacheKey: String {
    var components = [...]
    // Use per-minute variation for more diversity
    components.append(String(minuteOfHour))
    // Add explicit random component for regeneration cases
    return components.joined(separator: ":")
}
```

### Add Force Regeneration Support

**Add to `BlueprintInput`:**
```swift
struct BlueprintInput: Codable, Hashable, Sendable {
    // ... existing properties
    let forceNewVariation: Bool  // New property

    var cacheKey: String {
        var components = [...]
        components.append(String(minuteOfHour))
        if forceNewVariation {
            // Add random UUID component to force cache miss
            components.append(UUID().uuidString.prefix(8).description)
        }
        return components.joined(separator: ":")
    }
}
```

---

## Component 5: Cache Invalidation

### File: `OpenAIResponseCache.swift`

**Add Method:**
```swift
func invalidateAll() {
    cache.removeAll()
}

func invalidate(forKey key: String) {
    cache.removeValue(forKey: key)
}
```

### File: `WorkoutPlanView.swift`

**Update `regenerateWorkoutPlan()`:**
```swift
private func regenerateWorkoutPlan() {
    guard !isRegenerating else { return }
    isRegenerating = true

    Task {
        do {
            // Invalidate cache before regenerating
            if let composer = resolver.resolve(WorkoutPlanComposing.self) as? HybridWorkoutPlanComposer {
                composer.invalidateCache()
            }

            let newPlan = try await generateNewPlan(forceNewVariation: true)
            // ... rest of implementation
        }
    }
}
```

---

## Testing Strategy

### Unit Tests

**Test 1: Exercise Removal**
```swift
func test_removeExercise_updatesWorkoutPlan() {
    // Given
    let store = WorkoutSessionStore()
    store.start(with: mockWorkoutPlan)
    let initialCount = store.plan?.phases.flatMap { $0.items }.count ?? 0

    // When
    store.removeExercise(from: 0, exerciseIndex: 0)

    // Then
    let newCount = store.plan?.phases.flatMap { $0.items }.count ?? 0
    XCTAssertEqual(newCount, initialCount - 1)
}

func test_removeExercise_preventsEmptyWorkout() {
    // Given - workout with single exercise
    let store = WorkoutSessionStore()
    store.start(with: singleExerciseWorkout)

    // When
    store.removeExercise(from: 0, exerciseIndex: 0)

    // Then - exercise should NOT be removed
    XCTAssertEqual(store.plan?.phases.flatMap { $0.items }.count, 1)
}
```

**Test 2: Variation Seed Uniqueness**
```swift
func test_variationSeed_changesEachMinute() {
    let input1 = BlueprintInput.from(profile: mockProfile, checkIn: mockCheckIn, date: date1)
    let input2 = BlueprintInput.from(profile: mockProfile, checkIn: mockCheckIn, date: date1.addingTimeInterval(60))

    XCTAssertNotEqual(input1.variationSeed, input2.variationSeed)
}

func test_forceNewVariation_bypassesCache() {
    let input1 = BlueprintInput(/* ... */ forceNewVariation: false)
    let input2 = BlueprintInput(/* ... */ forceNewVariation: true)

    XCTAssertNotEqual(input1.cacheKey, input2.cacheKey)
}
```

### Integration Tests

**Test: Regeneration Produces Different Workout**
```swift
func test_regenerateWorkout_producesDifferentPlan() async {
    // Given
    let composer = HybridWorkoutPlanComposer()
    let plan1 = try await composer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn)

    // When - simulate regeneration
    composer.invalidateCache()
    let plan2 = try await composer.composePlan(blocks: blocks, profile: profile, checkIn: checkIn, forceNewVariation: true)

    // Then
    let exercises1 = plan1.phases.flatMap { $0.items }
    let exercises2 = plan2.phases.flatMap { $0.items }

    // At least 50% should differ
    let sameCount = zip(exercises1, exercises2).filter { $0 == $1 }.count
    let diffPercentage = Double(exercises1.count - sameCount) / Double(exercises1.count)
    XCTAssertGreaterThanOrEqual(diffPercentage, 0.5)
}
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `PhaseSectionView.swift` | Add Button wrapper for tap, add swipe delete |
| `WorkoutExerciseRow.swift` | Ensure no gesture blocking |
| `WorkoutSessionStore.swift` | Add `removeExercise(from:exerciseIndex:)` |
| `OpenAIConfiguration.swift` | Increase temperature to 0.55, reduce cacheTTL to 300 |
| `WorkoutBlueprint.swift` | Use per-minute variation, add `forceNewVariation` |
| `OpenAIResponseCache.swift` | Add `invalidateAll()` method |
| `WorkoutPlanView.swift` | Call cache invalidation before regeneration |
| `HybridWorkoutPlanComposer.swift` | Add `invalidateCache()` method |

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Higher temperature causes incoherent outputs | Medium | Keep at 0.55, monitor quality |
| Reduced cache increases API costs | Low | 5-min TTL still provides savings |
| List restructure breaks existing styling | Medium | Use `.listRowBackground(Color.clear)` |
| Exercise deletion causes UI inconsistency | Low | Animate removal, update indices |

---

## Success Criteria

- [ ] All exercises are tappable and navigate correctly
- [ ] Swipe-to-delete works for generated workout exercises
- [ ] Confirmation dialog appears before deletion
- [ ] Regeneration always produces different workout
- [ ] No two consecutive workouts are identical
- [ ] Unit tests pass with 80%+ coverage
- [ ] No regression in existing functionality

---

**Document End**
