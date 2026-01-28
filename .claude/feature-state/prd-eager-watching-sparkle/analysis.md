# Analysis: FitToday Pivot - Fase 1

## Scope Summary

This phase addresses two main areas:

### 1. Technical Fixes (P0)
- **OpenAI Prompt Enhancement**: Include exercise catalog in prompt to ensure name matching
- **Cache Key Diversity**: Add workout history hash to prevent repetitive workouts
- **Media Timeout**: Add 5s timeout to prevent hangs
- **Translation Expansion**: Add 100+ PT→EN translations

### 2. Group Streaks Feature
New social accountability feature where group streak only survives if ALL members complete 3+ workouts per week.

## Architecture Impact

### New Files to Create
- `Domain/Entities/GroupStreakModels.swift`
- `Domain/Protocols/GroupStreakRepository.swift`
- `Domain/UseCases/UpdateGroupStreakUseCase.swift`
- `Domain/UseCases/PauseGroupStreakUseCase.swift`
- `Data/Repositories/FirebaseGroupStreakRepository.swift`
- `Presentation/Features/Groups/GroupStreakViewModel.swift`
- `Presentation/Features/Groups/GroupStreakCardView.swift`
- `Presentation/Features/Groups/GroupStreakDetailView.swift`
- `Presentation/Features/Groups/MilestoneOverlayView.swift`
- `functions/src/groupStreak.ts`

### Files to Modify
- `Data/Services/OpenAI/WorkoutPromptAssembler.swift`
- `Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`
- `Data/Services/ExerciseDB/ExerciseMediaResolver.swift`
- `Data/Services/ExerciseDB/ExerciseTranslationDictionary.swift`
- `Data/Models/FirebaseModels.swift`
- `Domain/UseCases/SyncWorkoutCompletionUseCase.swift`
- `Presentation/Features/Groups/GroupDashboardView.swift`
- `Presentation/DI/AppContainer.swift`

## Dependencies

### External
- Firebase Cloud Functions (scheduled functions)
- Push Notifications (already configured)

### Internal
- Existing SocialModels infrastructure
- Existing GroupRepository
- Existing NotificationService

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Cloud Functions deployment complexity | Medium | Test with Firebase emulator first |
| Firestore security rules | High | Define rules before implementation |
| Time zone handling for week boundaries | Medium | Use UTC consistently |
| Notification spam | Low | Respect user preferences |

## Success Metrics

1. Exercise-image matching rate: 60% → 90%+
2. Workout diversity (7 days): 40% → 80%+
3. D7 retention in groups: baseline +15%
4. Daily engagement (group users): baseline +25%
