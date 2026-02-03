# Tasks: Program Workout Templates Expansion

## Overview

Breaking down the technical specification into implementable tasks for expanding workout templates and showing exercise composition.

---

## Task 1: Create Level-Specific Push Workout Templates

**Priority**: High
**Estimated Complexity**: Medium

### Description
Create push workout templates for beginner, intermediate, and advanced levels for gym equipment.

### Acceptance Criteria
- [ ] Create `lib_push_beginner_gym` with 4-5 machine-focused exercises
- [ ] Create `lib_push_intermediate_gym` with 5-6 mixed exercises
- [ ] Create `lib_push_advanced_gym` with 6-8 compound-focused exercises
- [ ] All templates follow naming convention
- [ ] Sets/reps/rest match level guidelines

### Files to Modify
- `FitToday/Data/Resources/LibraryWorkoutsSeed.json`

---

## Task 2: Create Level-Specific Pull Workout Templates

**Priority**: High
**Estimated Complexity**: Medium

### Description
Create pull workout templates for beginner, intermediate, and advanced levels for gym equipment.

### Acceptance Criteria
- [ ] Create `lib_pull_beginner_gym` with 4-5 machine-focused exercises
- [ ] Create `lib_pull_intermediate_gym` with 5-6 mixed exercises
- [ ] Create `lib_pull_advanced_gym` with 6-8 compound-focused exercises
- [ ] All templates follow naming convention
- [ ] Sets/reps/rest match level guidelines

### Files to Modify
- `FitToday/Data/Resources/LibraryWorkoutsSeed.json`

---

## Task 3: Create Level-Specific Legs Workout Templates

**Priority**: High
**Estimated Complexity**: Medium

### Description
Create legs workout templates for beginner, intermediate, and advanced levels for gym equipment.

### Acceptance Criteria
- [ ] Create `lib_legs_beginner_gym` with 4-5 machine-focused exercises
- [ ] Create `lib_legs_intermediate_gym` with 5-6 mixed exercises
- [ ] Create `lib_legs_advanced_gym` with 6-8 compound-focused exercises
- [ ] All templates follow naming convention
- [ ] Sets/reps/rest match level guidelines

### Files to Modify
- `FitToday/Data/Resources/LibraryWorkoutsSeed.json`

---

## Task 4: Create Full Body and Upper/Lower Workout Templates

**Priority**: Medium
**Estimated Complexity**: Medium

### Description
Create full body and upper/lower split workout templates for various levels and equipment types.

### Acceptance Criteria
- [ ] Create `lib_fullbody_beginner_gym`
- [ ] Create `lib_fullbody_intermediate_gym`
- [ ] Create `lib_upper_beginner_gym`, `lib_upper_intermediate_gym`, `lib_upper_advanced_gym`
- [ ] Create `lib_lower_beginner_gym`, `lib_lower_intermediate_gym`, `lib_lower_advanced_gym`
- [ ] All templates follow naming convention

### Files to Modify
- `FitToday/Data/Resources/LibraryWorkoutsSeed.json`

---

## Task 5: Update ProgramsSeed.json Mappings

**Priority**: High
**Estimated Complexity**: Low

### Description
Update program references to use level-appropriate workout templates instead of shared templates.

### Acceptance Criteria
- [ ] PPL Beginner uses beginner workout templates
- [ ] PPL Intermediate uses intermediate workout templates
- [ ] PPL Advanced uses advanced workout templates
- [ ] All 26 programs reference appropriate level templates
- [ ] No broken template references

### Files to Modify
- `FitToday/Data/Resources/ProgramsSeed.json`

---

## Task 6: Enhance WorkoutRowCard to Show Exercise Preview

**Priority**: High
**Estimated Complexity**: Medium

### Description
Modify WorkoutRowCard in ProgramDetailView to display exercise preview (first 3 exercises + remaining count).

### Acceptance Criteria
- [ ] Show first 3 exercise names with bullet points
- [ ] Show "+ X mais exercícios" for remaining exercises
- [ ] Add divider between workout info and exercise preview
- [ ] Use consistent styling with FitTodayColor and FitTodayFont
- [ ] Handle empty exercises gracefully

### Files to Modify
- `FitToday/Presentation/Features/Programs/ProgramDetailView.swift`

---

## Task 7: Add Localization for Exercise Preview

**Priority**: Low
**Estimated Complexity**: Low

### Description
Add localization strings for the exercise preview feature.

### Acceptance Criteria
- [ ] Add "program.workout.more_exercises" key for "+ X mais exercícios"
- [ ] Add Portuguese translation
- [ ] Add English translation

### Files to Modify
- `FitToday/Resources/pt-BR.lproj/Localizable.strings`
- `FitToday/Resources/en.lproj/Localizable.strings`

---

## Task 8: Validate and Test Implementation

**Priority**: High
**Estimated Complexity**: Low

### Description
Validate all JSON data, test navigation, and verify build.

### Acceptance Criteria
- [ ] All workout template IDs in programs exist in LibraryWorkoutsSeed.json
- [ ] All exercises have valid data
- [ ] App builds without errors
- [ ] Navigation to workout detail works
- [ ] Exercise preview displays correctly
- [ ] All 26 programs load correctly

### Testing Steps
1. Build the app
2. Navigate to Programs tab
3. Select each program type and verify workout templates
4. Verify exercise preview shows correctly
5. Tap on workout to verify navigation to detail

---

## Implementation Order

1. Task 1-4: Create workout templates (can be done in parallel)
2. Task 5: Update program mappings (depends on 1-4)
3. Task 6-7: UI enhancements (can be done in parallel with 1-5)
4. Task 8: Validation (depends on all above)

## Notes

- Use existing exercise data from the app's exercise database
- Follow the naming convention: `lib_{split}_{level}_{equipment}`
- Beginner: 4-5 exercises, machine focus, 3×10-15 reps, 90-120s rest
- Intermediate: 5-6 exercises, mixed, 3-4×8-12 reps, 60-90s rest
- Advanced: 6-8 exercises, compound focus, 4-5×6-10 reps, 60-120s rest
