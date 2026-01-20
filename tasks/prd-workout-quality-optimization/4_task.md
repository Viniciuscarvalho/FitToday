# [4.0] Create workout rating UI component (M)

## status: completed

<task_context>
<domain>presentation/features</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_1</dependencies>
</task_context>

# Task 4.0: Create workout rating UI component

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create the UI component for collecting user feedback after completing a workout. The rating appears on the workout completion screen with three options: "Muito Fácil", "Adequado", "Muito Difícil". Rating is optional but encouraged.

<requirements>
- Display rating prompt on WorkoutCompletionView
- Three rating options with distinct visual styling
- Rating is optional (user can skip)
- Save rating to workout history entry
- Subtle gamification to encourage rating
</requirements>

## Subtasks

- [ ] 4.1 Create `WorkoutRatingView` SwiftUI component
- [ ] 4.2 Design rating buttons with appropriate icons/colors
- [ ] 4.3 Integrate rating view into `WorkoutCompletionView`
- [ ] 4.4 Create `SaveWorkoutRatingUseCase`
- [ ] 4.5 Update `CompleteWorkoutSessionUseCase` to accept optional rating
- [ ] 4.6 Add skip option with subtle encouragement text
- [ ] 4.7 Add haptic feedback on selection
- [ ] 4.8 Write UI tests for rating flow

## Implementation Details

### Rating UI Design

```
┌─────────────────────────────────────┐
│     Como foi o treino de hoje?      │
│                                     │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐│
│  │   😅    │ │   💪    │ │   🔥    ││
│  │  Muito  │ │Adequado │ │  Muito  ││
│  │  Fácil  │ │         │ │ Difícil ││
│  └─────────┘ └─────────┘ └─────────┘│
│                                     │
│        [Pular esta vez]             │
└─────────────────────────────────────┘
```

### Color Scheme
- Muito Fácil: Green tint
- Adequado: Blue tint (primary)
- Muito Difícil: Orange tint

### Interaction Flow
1. User completes workout → Completion screen appears
2. Metrics shown (duration, estimated calories)
3. Rating prompt appears below metrics
4. User taps rating OR skips
5. Save to history → Navigate to home

## Success Criteria

- [ ] `WorkoutRatingView` renders correctly on all device sizes
- [ ] Three rating options are clearly distinguishable
- [ ] Selected rating shows visual feedback (highlight, haptic)
- [ ] Skip option works and saves entry without rating
- [ ] Rating is persisted to `SDWorkoutHistoryEntry.userRating`
- [ ] Smooth animation on selection
- [ ] Accessibility labels for VoiceOver

## Dependencies

- Task 1.0: SDWorkoutHistoryEntry with userRating field

## Notes

- Use SF Symbols or custom icons for rating buttons
- Consider adding streak bonus message after rating ("3 treinos seguidos!")
- Rating should not block navigation (timeout after 10s?)
- Test on iPad layout as well

## Relevant Files

### Files to Create
- `/FitToday/Presentation/Features/Workout/Components/WorkoutRatingView.swift`
- `/FitToday/Domain/UseCases/SaveWorkoutRatingUseCase.swift`
- `/FitTodayTests/Presentation/Features/Workout/WorkoutRatingViewTests.swift`

### Files to Modify
- `/FitToday/Presentation/Features/Workout/WorkoutCompletionView.swift`
- `/FitToday/Presentation/Features/Workout/WorkoutCompletionViewModel.swift`
- `/FitToday/Domain/UseCases/CompleteWorkoutSessionUseCase.swift`
