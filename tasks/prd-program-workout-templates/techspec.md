# Technical Specification: Program Workout Templates Expansion

## Overview

This document specifies the technical implementation for expanding workout templates and showing exercise composition in the FitToday app.

## Architecture

### Current Data Flow
```
ProgramsSeed.json → BundleProgramRepository → Program entity
                                                    ↓
                                           workoutTemplateIds
                                                    ↓
LibraryWorkoutsSeed.json → BundleLibraryWorkoutsRepository → LibraryWorkout entity
                                                                      ↓
                                                              exercises array
```

### No Architecture Changes Required
The existing architecture supports distinct workouts per program - we just need to:
1. Add more workout templates to `LibraryWorkoutsSeed.json`
2. Update program references in `ProgramsSeed.json`
3. Enhance UI to show exercise preview

## Implementation Details

### Task 1: Create Level-Specific Workout Templates

#### Naming Convention
```
lib_{split}_{level}_{equipment}

Examples:
- lib_push_beginner_gym
- lib_push_intermediate_gym
- lib_push_advanced_gym
- lib_fullbody_beginner_bodyweight
```

#### Template Structure by Level

**Beginner Templates:**
- 4-5 exercises per workout
- Machine/cable focus for safety
- 3 sets × 10-15 reps
- 90-120s rest
- No supersets/drop sets

**Intermediate Templates:**
- 5-6 exercises per workout
- Mix of free weights and machines
- 3-4 sets × 8-12 reps
- 60-90s rest
- Basic intensity techniques

**Advanced Templates:**
- 6-8 exercises per workout
- Compound barbell focus
- 4-5 sets × 6-10 reps
- 60-120s rest
- Advanced techniques (drop sets, etc.)

### Task 2: Exercise Selection by Muscle Group

#### Push Day Exercises
| Beginner | Intermediate | Advanced |
|----------|--------------|----------|
| Machine Chest Press | Barbell Bench Press | Barbell Bench Press |
| Pec Deck | Incline Dumbbell Press | Incline Barbell Press |
| Shoulder Press Machine | Dumbbell Shoulder Press | Military Press |
| Tricep Pushdown | Cable Crossover | Weighted Dips |
| | Overhead Tricep Extension | Close Grip Bench |
| | | Lateral Raises |

#### Pull Day Exercises
| Beginner | Intermediate | Advanced |
|----------|--------------|----------|
| Lat Pulldown | Pull-ups/Lat Pulldown | Weighted Pull-ups |
| Seated Cable Row | Barbell Row | Deadlift |
| Face Pulls | Dumbbell Row | Barbell Row |
| Machine Curl | EZ Bar Curl | Heavy Barbell Curl |
| | Hammer Curl | Preacher Curl |
| | | Rear Delt Flyes |

#### Leg Day Exercises
| Beginner | Intermediate | Advanced |
|----------|--------------|----------|
| Leg Press | Barbell Squat | Barbell Squat |
| Leg Curl | Romanian Deadlift | Front Squat |
| Leg Extension | Leg Press | Romanian Deadlift |
| Calf Raises | Walking Lunges | Bulgarian Split Squat |
| | Leg Curl | Leg Press |
| | | Hip Thrust |

### Task 3: Update ProgramsSeed.json Mappings

```json
// Example: PPL Beginner should reference beginner workouts
{
  "id": "ppl_beginner_muscle_gym",
  "workout_template_ids": [
    "lib_push_beginner_gym",
    "lib_pull_beginner_gym",
    "lib_legs_beginner_gym"
  ]
}

// PPL Intermediate references intermediate workouts
{
  "id": "ppl_intermediate_muscle_gym",
  "workout_template_ids": [
    "lib_push_intermediate_gym",
    "lib_pull_intermediate_gym",
    "lib_legs_intermediate_gym"
  ]
}
```

### Task 4: Enhance WorkoutRowCard UI

#### Current Display
```
┌─────────────────────────────────────────┐
│ 1  Push Day - Hipertrofia               │
│    ⏱ 55 min  🏃 6 exercícios            │
└─────────────────────────────────────────┘
```

#### Enhanced Display
```
┌─────────────────────────────────────────┐
│ 1  Push Day - Hipertrofia               │
│    ⏱ 55 min  🏃 6 exercícios            │
│    ─────────────────────────────────    │
│    • Barbell Bench Press                │
│    • Incline Dumbbell Press             │
│    • Seated Shoulder Press              │
│    + 3 mais exercícios                  │
└─────────────────────────────────────────┘
```

### Task 5: UI Component Changes

**File: `ProgramDetailView.swift`**

Modify `WorkoutRowCard` to accept exercises array and display preview:

```swift
private struct WorkoutRowCard: View {
    let workout: LibraryWorkout
    let index: Int
    let onTap: () -> Void
    @State private var isExpanded = false

    private var previewExercises: [String] {
        workout.exercises.prefix(3).map { $0.exercise.name }
    }

    private var remainingCount: Int {
        max(0, workout.exerciseCount - 3)
    }

    var body: some View {
        // ... existing code ...

        // Add exercise preview section
        if !workout.exercises.isEmpty {
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                ForEach(previewExercises, id: \.self) { name in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(FitTodayColor.brandPrimary)
                            .frame(width: 6, height: 6)
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(FitTodayColor.textSecondary)
                    }
                }
                if remainingCount > 0 {
                    Text("+ \(remainingCount) mais exercícios")
                        .font(.caption)
                        .foregroundStyle(FitTodayColor.brandPrimary)
                }
            }
        }
    }
}
```

## Required Workout Templates

### Push Workouts (9 total)
1. `lib_push_beginner_gym`
2. `lib_push_intermediate_gym`
3. `lib_push_advanced_gym`
4. `lib_push_beginner_home`
5. `lib_push_intermediate_home`
6. `lib_push_beginner_bodyweight`

### Pull Workouts (9 total)
1. `lib_pull_beginner_gym`
2. `lib_pull_intermediate_gym`
3. `lib_pull_advanced_gym`
4. `lib_pull_beginner_home`
5. `lib_pull_intermediate_home`
6. `lib_pull_beginner_bodyweight`

### Legs Workouts (9 total)
1. `lib_legs_beginner_gym`
2. `lib_legs_intermediate_gym`
3. `lib_legs_advanced_gym`
4. `lib_legs_beginner_home`
5. `lib_legs_intermediate_home`
6. `lib_legs_beginner_bodyweight`

### Full Body Workouts (6 total)
1. `lib_fullbody_beginner_gym`
2. `lib_fullbody_intermediate_gym`
3. `lib_fullbody_beginner_home`
4. `lib_fullbody_intermediate_home`
5. `lib_fullbody_beginner_bodyweight`
6. `lib_fullbody_intermediate_bodyweight`

### HIIT/Conditioning (4 total)
1. `lib_hiit_beginner_gym`
2. `lib_hiit_intermediate_gym`
3. `lib_hiit_beginner_bodyweight`
4. `lib_hiit_intermediate_bodyweight`

### Core Workouts (3 total)
1. `lib_core_beginner_home`
2. `lib_core_intermediate_home`
3. `lib_core_advanced_home`

### Upper/Lower Specific (6 total)
1. `lib_upper_beginner_gym`
2. `lib_upper_intermediate_gym`
3. `lib_upper_advanced_gym`
4. `lib_lower_beginner_gym`
5. `lib_lower_intermediate_gym`
6. `lib_lower_advanced_gym`

## Testing Strategy

1. **Data Validation**
   - All workout template IDs in programs must exist in LibraryWorkoutsSeed.json
   - All exercises must have valid muscle groups and equipment

2. **UI Verification**
   - Exercise preview displays correctly
   - Navigation to workout detail still works
   - Proper exercise count shown

3. **Build Verification**
   - No JSON parsing errors
   - App launches without crashes

## Rollout Plan

1. Update LibraryWorkoutsSeed.json with new templates
2. Update ProgramsSeed.json references
3. Enhance WorkoutRowCard UI
4. Test all 26 programs load correctly
5. Verify exercise preview display
