# PRD: Expand Program Workout Templates & Show Exercise Composition

## Problem Statement

Currently, FitToday has 26 workout programs but only 8 workout templates in the `LibraryWorkoutsSeed.json`. Many programs reuse the same templates regardless of level or goal, resulting in:

1. **Lack of variety**: A beginner PPL program uses the same workouts as an advanced strength program
2. **No differentiation by level**: Exercises, sets, reps should vary by skill level
3. **Hidden exercise composition**: Users can't see what exercises make up a workout until they navigate into it

### Current State
- **26 programs** defined in `ProgramsSeed.json`
- **8 workout templates** in `LibraryWorkoutsSeed.json`
- Programs reference workouts via `workoutTemplateIds`
- Exercises ARE defined but reused across all levels

### Desired Matrix (26 Programs)
```
┌──────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│ PROGRAMA         │ INICIANTE   │ INTERMED.   │ AVANÇADO    │ TOTAL       │
├──────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ Push Pull Legs   │ 1 (Gym)     │ 1 (Gym)     │ 1 (Gym)     │ 3           │
│ Full Body        │ 3 (G/D/BW)  │ 1 (Gym)     │ -           │ 4           │
│ Upper Lower      │ 1 (Gym)     │ 2 (G/D)     │ 1 (Gym)     │ 4           │
│ Bro Split        │ -           │ 1 (Gym)     │ 1 (Gym)     │ 2           │
│ Strength         │ 1 (Gym)     │ 1 (Gym)     │ -           │ 2           │
│ Weight Loss      │ 1 (Gym)     │ 1 (BW)      │ 1 (Gym)     │ 3           │
│ Home Gym         │ 1 (Home)    │ 1 (Home)    │ -           │ 2           │
│ Specialized      │ 2           │ 3           │ 1           │ 6           │
├──────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ TOTAL            │ 10          │ 11          │ 5           │ 26          │
└──────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

## Goals

1. **Expand workout templates** to provide level-appropriate exercises for each program type
2. **Show exercise preview** in `ProgramDetailView` so users see workout composition before navigating
3. **Differentiate by skill level** with appropriate:
   - Exercise selection (compound vs isolation)
   - Set/rep ranges
   - Rest intervals
   - Intensity techniques

## Requirements

### R1: Expand LibraryWorkoutsSeed.json
Create distinct workout templates for each program/level combination:

**Beginner workouts** (simpler exercises, higher reps, longer rest):
- Focus on machine and cable exercises
- 3 sets of 10-12 reps
- 90-120 second rest

**Intermediate workouts** (balanced approach):
- Mix of compound and isolation
- 3-4 sets of 8-12 reps
- 60-90 second rest

**Advanced workouts** (complex movements, intensity techniques):
- Heavy compound focus
- 4-5 sets of 6-10 reps
- 60-120 second rest
- Drop sets, supersets mentioned in tips

### R2: Show Exercise Preview in ProgramDetailView
Enhance `WorkoutRowCard` to show:
- First 3-4 exercise names as preview
- Expandable section to see all exercises
- Muscle groups targeted

### R3: Update ProgramsSeed.json
Map each program to its level-appropriate workout templates.

## Success Metrics

- [ ] Each program uses distinct, level-appropriate workout templates
- [ ] Users can preview exercises without leaving the program detail screen
- [ ] Build compiles without errors
- [ ] All 26 programs have proper workout template references

## Out of Scope

- Adding new exercise definitions (use existing exercise data)
- Changing the program structure or count
- API integration (keep bundle-based approach)

## Technical Notes

### File Locations
- Programs: `FitToday/Data/Resources/ProgramsSeed.json`
- Workouts: `FitToday/Data/Resources/LibraryWorkoutsSeed.json`
- Program Detail: `FitToday/Presentation/Features/Programs/ProgramDetailView.swift`
- Library Detail: `FitToday/Presentation/Features/Library/LibraryDetailView.swift`

### Data Models
```swift
// Program references workouts by ID
struct Program {
    let workoutTemplateIds: [String]  // Maps to LibraryWorkout.id
}

// LibraryWorkout contains exercises
struct LibraryWorkout {
    let id: String
    let exercises: [ExercisePrescription]
}

// ExercisePrescription has details
struct ExercisePrescription {
    let exercise: WorkoutExercise
    let sets: Int
    let reps: IntRange
    let restInterval: TimeInterval
    let tip: String?
}
```
