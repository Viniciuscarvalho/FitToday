# [6.0] Implement exercise diversity validation (80% rule) (M)

## status: pending

<task_context>
<domain>domain/services</domain>
<type>implementation</type>
<scope>quality_assurance</scope>
<complexity>medium</complexity>
<dependencies>task_5</dependencies>
</task_context>

# Task 6.0: Implement exercise diversity validation (80% rule)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement a validation layer that ensures generated workouts have at least 80% unique exercises compared to the last 3 workouts. This validation happens after OpenAI response and triggers a retry if the diversity threshold is not met.

<requirements>
- Calculate exercise diversity percentage vs last 3 workouts
- Reject workouts with <80% unique exercises
- Trigger single retry with explicit feedback to OpenAI
- Fall back to local composer if retry also fails
- Log diversity metrics for monitoring
</requirements>

## Subtasks

- [ ] 6.1 Create `ExerciseDiversityValidator` protocol and implementation
- [ ] 6.2 Implement `calculateDiversityScore` method
- [ ] 6.3 Add diversity check to quality gate in OpenAIWorkoutPlanComposer
- [ ] 6.4 Create retry feedback message for low diversity
- [ ] 6.5 Add diversity score to workout plan metadata
- [ ] 6.6 Log diversity metrics in DEBUG mode
- [ ] 6.7 Write unit tests for diversity calculation
- [ ] 6.8 Write integration tests for retry flow

## Implementation Details

### Diversity Calculation

```swift
protocol ExerciseDiversityValidating: Sendable {
    func calculateDiversityScore(
        newExercises: [String],
        previousExercises: [[String]]  // Last 3 workouts
    ) -> DiversityResult
}

struct DiversityResult: Sendable {
    let score: Double           // 0.0 - 1.0
    let uniqueCount: Int
    let totalCount: Int
    let repeatedExercises: [String]

    var isValid: Bool { score >= 0.80 }
}
```

### Retry Feedback Template

When diversity < 80%, append to retry prompt:

```
⚠️ ATENÇÃO: O treino anterior teve diversidade de apenas X%.
Exercícios repetidos: [list]
Por favor, substitua os exercícios repetidos por alternativas do catálogo.
```

### Quality Gate Integration

```swift
// In OpenAIWorkoutPlanComposer
func generateWithQualityGate(...) async throws -> WorkoutPlan {
    let plan = try await generate(...)

    let diversityResult = diversityValidator.calculateDiversityScore(
        newExercises: plan.exercises.map(\.name),
        previousExercises: previousWorkouts.map { $0.exercises.map(\.name) }
    )

    if !diversityResult.isValid {
        // Single retry with feedback
        let retryPlan = try await generateWithFeedback(diversityResult)
        return retryPlan
    }

    return plan
}
```

## Success Criteria

- [ ] Diversity score calculated correctly (test with known data)
- [ ] Workouts with <80% diversity trigger retry
- [ ] Retry includes specific feedback about repeated exercises
- [ ] Falls back to local composer after failed retry
- [ ] Diversity score logged for monitoring
- [ ] Unit tests cover edge cases (empty history, 100% diversity, 0% diversity)
- [ ] Integration tests validate full retry flow

## Dependencies

- Task 5.0: WorkoutPromptAssembler refactored

## Notes

- Exercise name comparison should be case-insensitive
- Consider fuzzy matching for similar exercise names (e.g., "Bench Press" vs "Barbell Bench Press")
- Log repeated exercises for debugging
- Diversity check happens AFTER OpenAI response parsing

## Relevant Files

### Files to Create
- `/FitToday/Domain/Protocols/ExerciseDiversityValidating.swift`
- `/FitToday/Domain/Services/ExerciseDiversityValidator.swift`
- `/FitToday/Domain/Entities/DiversityResult.swift`
- `/FitTodayTests/Domain/Services/ExerciseDiversityValidatorTests.swift`

### Files to Modify
- `/FitToday/Data/Services/OpenAI/OpenAIWorkoutPlanComposer.swift`
- `/FitToday/Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`
- `/FitToday/Presentation/DI/AppContainer.swift`
