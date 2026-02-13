# Tasks: Fix CRUD Operations, Localization & Workout Flow

## Overview
Total estimated tasks: 10
Priority: HIGH - User blocking issues

---

## Task 1: Fix Workout Generation Flow - Debug and Trace
**Priority**: P0
**Estimate**: 30min

### Description
Add debug logging to trace the workout generation flow and identify where it breaks.

### Steps
1. Add debug prints in `HomeView.generateWorkout()`
2. Add debug prints in `HomeViewModel.generateWorkoutWithCheckIn()`
3. Verify `showWorkoutPreview` state changes
4. Test and analyze logs

### Files
- `FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/Presentation/Features/Home/HomeViewModel.swift`

### Acceptance Criteria
- [ ] Debug logs show complete flow trace
- [ ] Root cause identified

---

## Task 2: Fix Workout Generation Flow - Implement Fix
**Priority**: P0
**Estimate**: 45min

### Description
Fix the identified issue preventing workout generation from completing.

### Steps
1. Fix state transition after questionnaire
2. Ensure `GeneratedWorkout` is properly created
3. Verify sheet presentation works
4. Test end-to-end flow

### Files
- `FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/Presentation/Features/Home/HomeViewModel.swift`
- `FitToday/Presentation/Features/Home/Components/GeneratedWorkoutPreview.swift`

### Acceptance Criteria
- [ ] Workout generates successfully after questionnaire
- [ ] Preview sheet displays correctly
- [ ] User can start generated workout

---

## Task 3: Fix Exercise Add Button in Custom Workout Builder
**Priority**: P0
**Estimate**: 30min

### Description
Fix the "Add Exercise" button in CustomWorkoutBuilderView.

### Steps
1. Verify `exerciseService` injection in ViewModel
2. Check `ExercisePickerView` callback execution
3. Add debug logging to trace exercise addition
4. Fix identified issues

### Files
- `FitToday/Presentation/Features/CustomWorkout/Views/CustomWorkoutBuilderView.swift`
- `FitToday/Presentation/Features/CustomWorkout/ViewModels/CustomWorkoutBuilderViewModel.swift`
- `FitToday/Presentation/Features/CustomWorkout/Views/ExercisePickerView.swift`
- `FitToday/Presentation/DI/AppContainer.swift`

### Acceptance Criteria
- [ ] Add Exercise button opens picker
- [ ] Selected exercise appears in list
- [ ] Exercise details are correct

---

## Task 4: Fix Custom Workout Save CRUD
**Priority**: P0
**Estimate**: 45min

### Description
Fix the save functionality for custom workouts.

### Steps
1. Verify `SaveCustomWorkoutUseCase` injection
2. Check `CustomWorkoutRepository` implementation
3. Verify SwiftData persistence configuration
4. Test save and verify data persisted

### Files
- `FitToday/Presentation/Features/CustomWorkout/ViewModels/CustomWorkoutBuilderViewModel.swift`
- `FitToday/Domain/UseCases/SaveCustomWorkoutUseCase.swift`
- `FitToday/Data/Repositories/SwiftDataCustomWorkoutRepository.swift`
- `FitToday/Presentation/DI/AppContainer.swift`

### Acceptance Criteria
- [ ] Save button triggers save action
- [ ] Workout persists to storage
- [ ] Success feedback shown
- [ ] Workout appears in templates list

---

## Task 5: Localize ErrorMapper Strings
**Priority**: P1
**Estimate**: 30min

### Description
Move all hardcoded Portuguese strings in ErrorMapper to Localizable.strings.

### Steps
1. Create localization keys for each error message
2. Add entries to pt-BR.lproj/Localizable.strings
3. Add entries to en.lproj/Localizable.strings
4. Replace hardcoded strings with .localized

### Files
- `FitToday/Presentation/Infrastructure/ErrorMapper.swift`
- `FitToday/Resources/pt-BR.lproj/Localizable.strings`
- `FitToday/Resources/en.lproj/Localizable.strings`

### Acceptance Criteria
- [ ] No hardcoded Portuguese in ErrorMapper
- [ ] All strings in both language files
- [ ] App shows correct language based on device

---

## Task 6: Localize ErrorStateViews and UI Strings
**Priority**: P1
**Estimate**: 30min

### Description
Localize remaining hardcoded strings in UI components.

### Steps
1. Find all hardcoded strings in ErrorStateViews.swift
2. Find hardcoded strings in PersonalWorkoutsListView.swift
3. Find hardcoded strings in PDFViewerView.swift
4. Create localization keys and add to both language files

### Files
- `FitToday/Presentation/Helpers/ErrorStateViews.swift`
- `FitToday/Presentation/Features/PersonalWorkouts/Views/PersonalWorkoutsListView.swift`
- `FitToday/Presentation/Features/PersonalWorkouts/Views/PDFViewerView.swift`
- `FitToday/Resources/pt-BR.lproj/Localizable.strings`
- `FitToday/Resources/en.lproj/Localizable.strings`

### Acceptance Criteria
- [ ] No hardcoded Portuguese in listed files
- [ ] All strings in both language files

---

## Task 7: Localize Domain Entity Strings
**Priority**: P1
**Estimate**: 30min

### Description
Localize hardcoded strings in domain entities.

### Steps
1. Localize strings in WorkoutTemplateType.swift
2. Localize strings in ProgramModels.swift
3. Localize strings in EntitlementPolicy.swift
4. Localize strings in ProgramWorkout.swift

### Files
- `FitToday/Domain/Entities/WorkoutTemplateType.swift`
- `FitToday/Domain/Entities/ProgramModels.swift`
- `FitToday/Domain/Entities/EntitlementPolicy.swift`
- `FitToday/Domain/Entities/ProgramWorkout.swift`
- `FitToday/Resources/pt-BR.lproj/Localizable.strings`
- `FitToday/Resources/en.lproj/Localizable.strings`

### Acceptance Criteria
- [ ] No hardcoded Portuguese in domain entities
- [ ] All strings in both language files

---

## Task 8: Localize Remaining Hardcoded Strings
**Priority**: P1
**Estimate**: 30min

### Description
Localize any remaining hardcoded strings found in the codebase.

### Steps
1. Grep for remaining Portuguese patterns
2. Localize TabRootView.swift strings
3. Localize UserAPIKeyManager.swift strings
4. Localize any other found strings

### Files
- `FitToday/Presentation/Root/TabRootView.swift`
- `FitToday/Data/Services/OpenAI/UserAPIKeyManager.swift`
- Other files as found
- `FitToday/Resources/pt-BR.lproj/Localizable.strings`
- `FitToday/Resources/en.lproj/Localizable.strings`

### Acceptance Criteria
- [ ] No hardcoded Portuguese strings in codebase
- [ ] Grep search returns no results

---

## Task 9: Verify PDF Display in Personal Tab
**Priority**: P1
**Estimate**: 30min

### Description
Verify and fix PDF display functionality in Personal tab.

### Steps
1. Add debug logging to PDF loading flow
2. Verify CMS endpoint returns valid PDF URLs
3. Check PDFCacheService implementation
4. Test PDF viewing end-to-end

### Files
- `FitToday/Presentation/Features/PersonalWorkouts/ViewModels/PersonalWorkoutsViewModel.swift`
- `FitToday/Data/Services/PDFCacheService.swift`

### Acceptance Criteria
- [ ] PDF loads from CMS
- [ ] PDF displays correctly in viewer
- [ ] Loading/error states work

---

## Task 10: Build and Test All Fixes
**Priority**: P0
**Estimate**: 30min

### Description
Build the project and test all implemented fixes.

### Steps
1. Build project and fix any compilation errors
2. Test workout generation flow
3. Test exercise add/save in custom workouts
4. Test localization in both languages
5. Test PDF display

### Acceptance Criteria
- [ ] Project builds without errors
- [ ] All 5 user stories pass acceptance criteria
- [ ] No regressions in existing functionality

---

## Summary

| Task | Priority | Estimate | Status |
|------|----------|----------|--------|
| Task 1: Debug Generation Flow | P0 | 30min | Pending |
| Task 2: Fix Generation Flow | P0 | 45min | Pending |
| Task 3: Fix Exercise Add Button | P0 | 30min | Pending |
| Task 4: Fix Save CRUD | P0 | 45min | Pending |
| Task 5: Localize ErrorMapper | P1 | 30min | Pending |
| Task 6: Localize UI Strings | P1 | 30min | Pending |
| Task 7: Localize Domain Strings | P1 | 30min | Pending |
| Task 8: Localize Remaining | P1 | 30min | Pending |
| Task 9: Verify PDF Display | P1 | 30min | Pending |
| Task 10: Build and Test | P0 | 30min | Pending |

**Total Estimated Time**: ~5.5 hours
