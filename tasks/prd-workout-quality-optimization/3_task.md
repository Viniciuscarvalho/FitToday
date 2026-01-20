# [3.0] Implement FeedbackAnalyzer service (M)

## status: completed

<task_context>
<domain>domain/services</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_1</dependencies>
</task_context>

# Task 3.0: Implement FeedbackAnalyzer service

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create the `FeedbackAnalyzer` service that analyzes the user's last 5 workout ratings and determines intensity adjustments for future workouts. This service is crucial for the adaptive training system.

<requirements>
- Analyze last 5 workout ratings to detect trends
- Return intensity adjustments (volume multiplier, RPE adjustment, rest adjustment)
- Generate recommendation text for OpenAI prompt
- Handle edge cases (no ratings, mixed ratings)
- Follow PRD rules: 3+ "too easy" = increase intensity, 3+ "too hard" = decrease
</requirements>

## Subtasks

- [ ] 3.1 Create `FeedbackAnalyzing` protocol
- [ ] 3.2 Create `IntensityAdjustment` struct
- [ ] 3.3 Implement `FeedbackAnalyzer` concrete class
- [ ] 3.4 Implement `analyzeRecentFeedback` method with trend detection
- [ ] 3.5 Create `FetchRecentRatingsUseCase` to get last 5 ratings
- [ ] 3.6 Register service in DI container
- [ ] 3.7 Write comprehensive unit tests for all scenarios

## Implementation Details

Reference **techspec.md** section "Core Interfaces" for the protocol definition:

```swift
protocol FeedbackAnalyzing: Sendable {
    func analyzeRecentFeedback(
        ratings: [WorkoutRating],
        currentIntensity: WorkoutIntensity
    ) -> IntensityAdjustment
}

struct IntensityAdjustment: Sendable {
    let volumeMultiplier: Double      // 0.8 - 1.2
    let rpeAdjustment: Int            // -1, 0, +1
    let restAdjustment: TimeInterval  // -15s to +30s
    let recommendation: String        // For OpenAI prompt
}
```

### Intensity Adjustment Rules

| Condition | Volume | RPE | Rest | Recommendation |
|-----------|--------|-----|------|----------------|
| 3+ "too_easy" | 1.15 | +1 | -15s | Increase intensity |
| 3+ "too_hard" | 0.85 | -1 | +30s | Decrease intensity |
| Mixed/None | 1.0 | 0 | 0 | No change |

## Success Criteria

- [ ] `FeedbackAnalyzing` protocol defined
- [ ] `FeedbackAnalyzer` correctly identifies majority trends
- [ ] Returns appropriate adjustments for each scenario
- [ ] Generates clear recommendation text in Portuguese
- [ ] Handles empty rating arrays gracefully
- [ ] Unit tests cover all edge cases (100% branch coverage)
- [ ] Service registered in AppContainer

## Dependencies

- Task 1.0: SDWorkoutHistoryEntry with userRating field

## Notes

- Consider ratings within last 14 days only (stale ratings less relevant)
- The recommendation text will be injected into the OpenAI prompt
- Use Portuguese for recommendation text (matches app language)

## Relevant Files

### Files to Create
- `/FitToday/Domain/Protocols/FeedbackAnalyzing.swift`
- `/FitToday/Domain/Entities/IntensityAdjustment.swift`
- `/FitToday/Domain/Services/FeedbackAnalyzer.swift`
- `/FitToday/Domain/UseCases/FetchRecentRatingsUseCase.swift`
- `/FitTodayTests/Domain/Services/FeedbackAnalyzerTests.swift`

### Files to Modify
- `/FitToday/Presentation/DI/AppContainer.swift`
