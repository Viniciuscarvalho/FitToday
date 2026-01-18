# Implementation Tasks Summary for Workout Quality Optimization

## Tasks

### Phase 1: Data Models (Foundation)
- [ ] 1.0 Expand SDWorkoutHistoryEntry with userRating field (S)
- [ ] 2.0 Create SDUserStats model for aggregated metrics (S)

### Phase 2: Feedback System
- [ ] 3.0 Implement FeedbackAnalyzer service (M)
- [ ] 4.0 Create workout rating UI component (M)

### Phase 3: Prompt Optimization
- [ ] 5.0 Refactor WorkoutPromptAssembler with limits and feedback (L)
- [ ] 6.0 Implement exercise diversity validation (80% rule) (M)

### Phase 4: HealthKit Integration
- [ ] 7.0 Complete bidirectional HealthKit sync (M)
- [ ] 8.0 Add HealthKit sync toggle in settings (S)

### Phase 5: Stats Dashboard
- [ ] 9.0 Implement UserStatsCalculator service (M)
- [ ] 10.0 Create stats dashboard UI in History tab (L)

## Dependencies Graph

```
       ┌─────┐     ┌─────┐
       │ 1.0 │     │ 2.0 │  ← Phase 1 (parallel)
       └──┬──┘     └──┬──┘
          │           │
    ┌─────┼───────────┤
    │     │           │
┌───▼───┐ │       ┌───▼───┐
│  3.0  │ │       │  7.0  │  ← Phase 2 & 4 (parallel)
└───┬───┘ │       └───┬───┘
    │     │           │
┌───▼───┐ │       ┌───▼───┐
│  4.0  │ │       │  8.0  │
└───────┘ │       └───┬───┘
          │           │
      ┌───▼───┐   ┌───▼───┐
      │  5.0  │   │  9.0  │  ← Phase 3 & 5
      └───┬───┘   └───┬───┘
          │           │
      ┌───▼───┐   ┌───▼───┐
      │  6.0  │   │ 10.0  │
      └───────┘   └───────┘
```

## Parallel Execution Opportunities

| Stage | Tasks | Notes |
|-------|-------|-------|
| 1 | 1.0, 2.0 | Both are independent data model tasks |
| 2 | 3.0, 4.0, 7.0 | After 1.0 completes, these can run in parallel |
| 3 | 5.0, 8.0, 9.0 | After respective dependencies |
| 4 | 6.0, 10.0 | Final tasks in their chains |

## Size Notes
- S - Small (~0.5-1 day)
- M - Medium (~1-2 days)
- L - Large (~2-3 days)

## Total Estimated Effort
- Small tasks: 3 × 0.5 = 1.5 days
- Medium tasks: 5 × 1.5 = 7.5 days
- Large tasks: 2 × 2.5 = 5 days
- **Total: ~14 days** (can be reduced to ~10 days with parallel execution)
