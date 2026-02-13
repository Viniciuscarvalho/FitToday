# Technical Specification: Fix CRUD Operations, Localization & Workout Flow

## 1. Workout Generation Flow Fix

### Current Issue
After user completes the questionnaire and returns to Home, clicking "Generate" button doesn't work. The `generateWorkout()` method in `HomeView.swift` creates a `DailyCheckIn` with live inputs but the navigation/state flow may be broken.

### Root Cause Analysis
1. `HomeView.generateWorkout()` calls `viewModel.generateWorkoutWithCheckIn(checkIn)`
2. After generation, it shows `showWorkoutPreview = true`
3. The sheet binding may not be triggering properly
4. State transitions between `needsDailyCheckIn` → `workoutReady` may not be happening

### Solution
1. Verify `showWorkoutPreview` sheet binding is working
2. Check `journeyState` transitions after questionnaire completion
3. Ensure `GeneratedWorkout` model is properly populated
4. Add debug logging to trace the flow

### Files to Modify
- `FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/Presentation/Features/Home/HomeViewModel.swift`

---

## 2. Exercise Reorder/Add Button Fix

### Current Issue
In `CustomWorkoutBuilderView`, the "Add Exercise" button opens `ExercisePickerView` but exercises may not be added to the list.

### Root Cause Analysis
1. `showExercisePicker = true` opens the sheet
2. `ExercisePickerView` calls `viewModel.addExercise(from: exercise, imageURL: nil)` on selection
3. The callback may not be executing or `exerciseService` may be nil

### Solution
1. Verify `exerciseService` is properly injected in ViewModel init
2. Check `ExercisePickerView` selection callback
3. Add debug logging to confirm exercise addition
4. Verify `exercises` array is being updated

### Files to Modify
- `FitToday/Presentation/Features/CustomWorkout/Views/CustomWorkoutBuilderView.swift`
- `FitToday/Presentation/Features/CustomWorkout/ViewModels/CustomWorkoutBuilderViewModel.swift`
- `FitToday/Presentation/Features/CustomWorkout/Views/ExercisePickerView.swift`

---

## 3. Hardcoded Strings Localization

### Current Issue
Multiple Portuguese strings are hardcoded instead of using `Localizable.strings`.

### Files with Hardcoded Strings
1. `ErrorMapper.swift` - Error titles and messages
2. `ErrorStateViews.swift` - Error messages
3. `PersonalWorkoutsListView.swift` - "Carregando treinos..."
4. `PDFViewerView.swift` - "Fechar", "Tentar novamente"
5. `ProgramWorkout.swift` - "Treino completo"
6. `WorkoutTemplateType.swift` - Muscle group descriptions
7. `ProgramModels.swift` - "Treino em Casa"
8. `EntitlementPolicy.swift` - "Treinos do Personal"
9. `UserAPIKeyManager.swift` - Error message
10. `TabRootView.swift` - Messages

### Solution
1. Create localization keys for each hardcoded string
2. Add entries to both `pt-BR.lproj/Localizable.strings` and `en.lproj/Localizable.strings`
3. Replace hardcoded strings with `.localized` calls

### Localization Pattern
```swift
// Before
Text("Carregando treinos...")

// After
Text("personal.loading.workouts".localized)
```

---

## 4. Workout Save CRUD Fix

### Current Issue
In `CustomWorkoutBuilderView`, clicking "Save" button doesn't persist the workout.

### Current Flow
1. Save button calls `viewModel.save()`
2. `save()` creates `CustomWorkoutTemplate` and calls `saveUseCase.execute(template:)`
3. `SaveCustomWorkoutUseCase` should persist via `CustomWorkoutRepository`

### Root Cause Analysis
1. `saveUseCase` may not be properly injected
2. Repository implementation may have issues
3. SwiftData/persistence layer may not be configured

### Solution
1. Verify `SaveCustomWorkoutUseCase` is properly initialized with repository
2. Check `CustomWorkoutRepository` implementation
3. Add debug logging to trace save flow
4. Verify SwiftData model container is configured

### Files to Modify
- `FitToday/Presentation/Features/CustomWorkout/ViewModels/CustomWorkoutBuilderViewModel.swift`
- `FitToday/Domain/UseCases/SaveCustomWorkoutUseCase.swift`
- `FitToday/Data/Repositories/CustomWorkoutRepository.swift`
- `FitToday/Presentation/DI/AppContainer.swift` (verify registration)

---

## 5. PDF Display in Personal Tab

### Current Implementation
- `PersonalWorkoutsListView` fetches workouts via `PersonalWorkoutRepository`
- `PDFViewerView` displays PDF using `PDFKitView` wrapper
- `viewModel.getPDFURL(for: workout)` fetches PDF URL from cache/CMS

### Potential Issues
1. `PDFCaching` service may not be fetching from CMS correctly
2. Authentication may be missing for CMS endpoint
3. `getPDFURL` may be returning invalid URL

### Solution
1. Verify `PersonalWorkoutRepository.fetchWorkouts()` returns valid PDF URLs
2. Check `PDFCacheService.getPDF()` implementation
3. Add debug logging for PDF URL resolution
4. Verify CMS endpoint is accessible

### Files to Investigate
- `FitToday/Presentation/Features/PersonalWorkouts/ViewModels/PersonalWorkoutsViewModel.swift`
- `FitToday/Data/Services/PDFCacheService.swift`
- `FitToday/Domain/Entities/PersonalWorkout.swift`

---

## Testing Strategy

### Manual Testing
1. **Workout Generation**: Complete questionnaire → Return to Home → Tap Generate → Verify workout appears
2. **Exercise Add**: Create custom workout → Tap Add Exercise → Select exercise → Verify added
3. **Save Workout**: Create workout with exercises → Tap Save → Verify persisted
4. **Localization**: Switch device language → Verify all strings change
5. **PDF Display**: Open Personal tab → Tap workout → Verify PDF loads

### Debug Logging
Add `#if DEBUG` print statements at key points to trace execution flow.

---

## Dependencies

- PDFKit framework (already imported)
- SwiftData for persistence
- Swinject for DI
- OpenAI API for workout generation

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Breaking existing functionality | Add defensive checks, test extensively |
| Missing localizations | Use fallback to key if translation missing |
| PDF loading failures | Add proper error handling and retry |
