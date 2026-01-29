# PRD: Treinos Dinâmicos (Dynamic Workouts)

## Overview

**Feature Name:** Treinos Dinâmicos (Dynamic Workouts)
**Priority:** High
**Target Release:** v2.0

### Problem Statement

Currently, FitToday users can only follow pre-defined workout plans from the library. Many users want the flexibility to:
- Create their own custom workout routines
- Add/remove exercises based on personal preference
- Track progress on exercises they choose
- Reuse their custom workouts as templates

This is a common expectation from fitness apps like Hevy, Strong, and other workout trackers.

### Goals

1. Allow users to create custom workout programs from scratch
2. Provide intuitive exercise selection with search and filtering
3. Enable flexible set/rep/weight configuration
4. Support drag-to-reorder for exercise sequencing
5. Save custom workouts as reusable templates
6. Track progress over time for custom exercises

## User Stories

### US-1: Create Custom Workout
**As a** fitness enthusiast
**I want to** create my own workout routine
**So that** I can train with exercises I prefer

**Acceptance Criteria:**
- User can create a new blank workout
- User can add exercises from ExerciseDB catalog
- User can configure sets, reps, and weight for each exercise
- User can save the workout with a custom name

### US-2: Exercise Selection
**As a** user creating a workout
**I want to** search and filter exercises
**So that** I can quickly find the exercises I want

**Acceptance Criteria:**
- Search by exercise name
- Filter by body part (chest, back, legs, etc.)
- Filter by equipment (barbell, dumbbell, machine, bodyweight)
- Show exercise GIF preview during selection
- Recent/favorite exercises shown at top

### US-3: Reorder Exercises
**As a** user customizing a workout
**I want to** drag exercises to reorder them
**So that** I can structure my workout flow properly

**Acceptance Criteria:**
- Long-press to enable drag mode
- Visual feedback during drag
- Drop to reorder with animation
- Order persists when saved

### US-4: Template Management
**As a** user who created workouts
**I want to** save and reuse my workouts as templates
**So that** I don't have to recreate them each time

**Acceptance Criteria:**
- Save workout as template
- List of saved templates in "My Workouts" section
- Start workout from template
- Edit/delete templates
- Templates count toward challenges (30+ min rule)

### US-5: Progress Tracking
**As a** user performing custom workouts
**I want to** see my progress over time
**So that** I can track my improvement

**Acceptance Criteria:**
- Log actual weight/reps performed
- View history per exercise
- Show previous session data during workout
- Visual progress charts (optional, Phase 2)

## Technical Requirements

### Data Model

```swift
// New entities needed
struct CustomWorkoutTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [CustomExerciseEntry]
    var createdAt: Date
    var lastUsedAt: Date?
    var estimatedDuration: Int? // minutes
}

struct CustomExerciseEntry: Identifiable, Codable {
    let id: UUID
    var exerciseId: String  // Reference to ExerciseDB
    var exerciseName: String // Cached for offline
    var orderIndex: Int
    var sets: [WorkoutSet]
    var notes: String?
}

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var targetReps: Int?
    var targetWeight: Double?
    var targetDuration: TimeInterval?  // For timed exercises
    var actualReps: Int?
    var actualWeight: Double?
    var isCompleted: Bool
}
```

### Repository Pattern

- `CustomWorkoutRepository` protocol
- `SwiftDataCustomWorkoutRepository` implementation
- CRUD operations for templates
- Query by date range for history

### UI Components

1. **CreateWorkoutView** - Main screen for building workouts
2. **ExercisePickerView** - Modal for selecting exercises
3. **SetConfigurationView** - Configure sets/reps/weight
4. **WorkoutTemplateListView** - List of saved templates
5. **ActiveCustomWorkoutView** - Execute a custom workout

### Integration Points

- ExerciseDB service for exercise data and GIFs
- HealthKit sync for completed workouts
- Challenge system (SyncWorkoutCompletionUseCase)
- Existing history tracking

## GIF Optimization Strategy

Problem: ExerciseDB GIFs can be slow to load and may fail.

Solution:
1. **Local caching**: Cache GIFs on first load using existing `ImageCacheService`
2. **Fallback to static images**: If GIF fails, show first frame as static image
3. **Rate limiting**: Queue requests with exponential backoff (already implemented)
4. **Lazy loading**: Only load GIF when exercise is visible

## Out of Scope (Phase 1)

- Superset/circuit configuration
- Rest timer customization
- Social sharing of templates
- Import/export templates
- AI-generated custom workouts

## Success Metrics

1. **Adoption**: 30% of active users create at least 1 custom workout within 30 days
2. **Retention**: Custom workout users have 20% higher weekly active rate
3. **Completion**: 70% of started custom workouts are completed

## Timeline

- **Week 1**: Data model, repository, basic CRUD
- **Week 2**: Exercise picker, workout builder UI
- **Week 3**: Active workout execution, HealthKit integration
- **Week 4**: Templates, polish, testing

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| GIF loading performance | High | Implement caching + static fallback |
| Complex drag-reorder on iOS | Medium | Use native SwiftUI .onMove modifier |
| Data migration | Low | New tables, no migration needed |
| ExerciseDB rate limits | Medium | Existing rate limiter handles this |

## Appendix

### Competitive Analysis

| App | Custom Workouts | Template Save | Progress Tracking |
|-----|----------------|---------------|-------------------|
| Hevy | Yes | Yes | Yes |
| Strong | Yes | Yes | Yes |
| FitToday (current) | No | No | Partial |
| **FitToday (target)** | **Yes** | **Yes** | **Yes** |
