# [5.0] Refactor WorkoutPromptAssembler with limits and feedback (L)

## status: completed

<task_context>
<domain>data/services</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>task_3</dependencies>
</task_context>

# Task 5.0: Refactor WorkoutPromptAssembler with limits and feedback

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Refactor the `WorkoutPromptAssembler` to include explicit exercise limits per phase, user feedback history, and movement pattern diversity rules. This is the core task for improving workout quality and reducing repetition.

<requirements>
- Add explicit exercise limits per phase in the prompt
- Include last 7 days of exercises as "prohibited" list
- Include user feedback summary from FeedbackAnalyzer
- Add movement pattern diversity rules (push/pull/hinge/squat)
- Maintain backward compatibility with existing prompt structure
</requirements>

## Subtasks

- [ ] 5.1 Add `recentRatings` parameter to `assemblePrompt` method
- [ ] 5.2 Create `formatFeedbackHistory` method
- [ ] 5.3 Add exercise limits section to prompt template
- [ ] 5.4 Expand `formatPreviousWorkouts` to include 7 days (not just 3)
- [ ] 5.5 Add movement pattern diversity section
- [ ] 5.6 Integrate `FeedbackAnalyzer` output into prompt
- [ ] 5.7 Update `HybridWorkoutPlanComposer` to fetch ratings
- [ ] 5.8 Update prompt cache key to include feedback hash
- [ ] 5.9 Write integration tests for new prompt format

## Implementation Details

Reference **techspec.md** section "Prompt Structure v2" for the complete implementation.

### New Prompt Sections

```
## LIMITES POR FASE (RESPEITAR)
- Warmup: 2-3 exercícios
- Strength: 4-6 exercícios
- Accessory: 2-4 exercícios
- Cooldown: 2-3 exercícios

## HISTÓRICO DE FEEDBACK DO USUÁRIO
Últimas 5 avaliações: adequate, too_easy, adequate, too_easy, too_easy
⚡ AUMENTAR INTENSIDADE: Usuário achou últimos treinos muito fáceis.

## REGRA DE DIVERSIDADE
- Variar padrões de movimento: incluir PUSH, PULL, HINGE, SQUAT
- ≥80% dos exercícios devem ser DIFERENTES dos últimos 3 treinos
```

### Movement Patterns Mapping

| Pattern | Example Muscles | Example Exercises |
|---------|-----------------|-------------------|
| PUSH | Chest, Shoulders, Triceps | Bench Press, Overhead Press |
| PULL | Back, Biceps | Rows, Pull-ups |
| HINGE | Hamstrings, Glutes, Lower Back | Deadlift, Hip Thrust |
| SQUAT | Quads, Glutes | Squat, Leg Press |

## Success Criteria

- [ ] Prompt includes explicit exercise limits per phase
- [ ] Prompt includes 7-day exercise history (expanded from 3)
- [ ] Prompt includes feedback summary when ratings exist
- [ ] Prompt includes movement pattern diversity rules
- [ ] Cache key accounts for feedback changes
- [ ] Generated workouts have correct exercise counts per phase
- [ ] Integration tests validate prompt structure
- [ ] Backward compatible (no breaking changes to existing flow)

## Dependencies

- Task 3.0: FeedbackAnalyzer service

## Notes

- Keep prompt under 4000 tokens to avoid truncation
- Use Portuguese for all prompt text
- Test with various feedback combinations
- Log prompt length in DEBUG mode for monitoring

## Relevant Files

### Files to Modify
- `/FitToday/Data/Services/OpenAI/WorkoutPromptAssembler.swift`
- `/FitToday/Data/Services/OpenAI/HybridWorkoutPlanComposer.swift`
- `/FitToday/Data/Services/OpenAI/OpenAIWorkoutPlanComposer.swift`

### Files to Create
- `/FitTodayTests/Data/Services/OpenAI/WorkoutPromptAssemblerV2Tests.swift`
