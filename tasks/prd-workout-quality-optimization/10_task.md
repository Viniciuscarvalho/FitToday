# [10.0] Create stats dashboard UI in History tab (L)

## status: pending

<task_context>
<domain>presentation/features</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>task_9</dependencies>
</task_context>

# Task 10.0: Create stats dashboard UI in History tab

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create the stats dashboard UI in the History tab showing workout streaks, weekly/monthly comparisons, and progress metrics. The dashboard provides visual motivation and tracks user progress over time.

<requirements>
- Display current streak prominently with visual flair
- Show weekly stats (workouts, duration, calories)
- Show monthly comparison (this month vs last month)
- Filter history by period (week, month, 3 months)
- Each workout entry shows: date, duration, calories, rating
- Smooth animations and responsive layout
</requirements>

## Subtasks

- [ ] 10.1 Create `StatsHeaderView` with streak display
- [ ] 10.2 Create `WeeklyStatsCard` component
- [ ] 10.3 Create `MonthlyComparisonCard` component
- [ ] 10.4 Create `WorkoutHistoryListItem` with rating display
- [ ] 10.5 Implement period filter (week/month/3 months)
- [ ] 10.6 Create `HistoryViewModel` with stats loading
- [ ] 10.7 Add pull-to-refresh for stats update
- [ ] 10.8 Implement empty state for no workouts
- [ ] 10.9 Add animations for streak celebration
- [ ] 10.10 Write UI tests for dashboard

## Implementation Details

### Dashboard Layout

```
┌─────────────────────────────────────────┐
│         🔥 5 dias seguidos!             │  ← StatsHeaderView
│      Seu recorde: 12 dias               │
├─────────────────────────────────────────┤
│  Esta Semana          │  Este Mês       │  ← Stats Cards
│  ┌─────────────────┐  │  ┌───────────┐  │
│  │ 4 treinos       │  │  │ 12 treinos│  │
│  │ 2h 30min        │  │  │ vs 10 mês │  │
│  │ 850 kcal        │  │  │ anterior  │  │
│  └─────────────────┘  │  └───────────┘  │
├─────────────────────────────────────────┤
│ Histórico    [Semana ▼] [Mês] [3 Meses] │  ← Filter
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ Hoje                                │ │
│ │ Treino Superior · 45min · 320 kcal  │ │
│ │ ⭐ Adequado                          │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ Ontem                               │ │
│ │ Treino Inferior · 38min · 280 kcal  │ │
│ │ ⭐ Muito Fácil                       │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Component Specifications

#### StatsHeaderView
- Large streak number with fire emoji
- "X dias seguidos!" text
- Personal best indicator
- Celebration animation at milestones (7, 14, 30 days)

#### WeeklyStatsCard
- Workouts completed count
- Total duration (formatted as "Xh Ymin")
- Total calories burned
- Progress bar (% of weekly goal if set)

#### MonthlyComparisonCard
- This month's workout count
- Comparison to previous month (↑ or ↓)
- Percentage change indicator
- Green for increase, red for decrease

#### WorkoutHistoryListItem
- Date (relative: "Hoje", "Ontem", or formatted)
- Workout title and focus
- Duration and calories
- Rating indicator (emoji or stars)

### Filter Behavior

| Filter | Date Range | Data Source |
|--------|------------|-------------|
| Semana | Last 7 days | Live query |
| Mês | Current month | Live query |
| 3 Meses | Last 90 days | Paginated |

## Success Criteria

- [ ] Streak displays correctly with visual emphasis
- [ ] Weekly stats card shows accurate data
- [ ] Monthly comparison shows trend correctly
- [ ] History list grouped by date
- [ ] Rating displayed on each workout entry
- [ ] Filter changes data immediately
- [ ] Empty state shown when no workouts
- [ ] Pull-to-refresh updates stats
- [ ] Layout works on all iPhone sizes
- [ ] Accessibility labels for VoiceOver

## Dependencies

- Task 9.0: UserStatsCalculator service

## Notes

- Use `ScrollView` with `LazyVStack` for performance
- Consider skeleton loading state
- Celebrate milestones with haptic feedback
- Cache stats to avoid re-fetching on tab switch
- Test with large history (100+ workouts)

## Relevant Files

### Files to Create
- `/FitToday/Presentation/Features/History/StatsHeaderView.swift`
- `/FitToday/Presentation/Features/History/WeeklyStatsCard.swift`
- `/FitToday/Presentation/Features/History/MonthlyComparisonCard.swift`
- `/FitToday/Presentation/Features/History/WorkoutHistoryListItem.swift`
- `/FitToday/Presentation/Features/History/HistoryDashboardView.swift`
- `/FitToday/Presentation/Features/History/HistoryDashboardViewModel.swift`
- `/FitTodayTests/Presentation/Features/History/HistoryDashboardViewModelTests.swift`

### Files to Modify
- `/FitToday/Presentation/Features/History/HistoryView.swift` (integrate dashboard)
- `/FitToday/Presentation/Features/History/HistoryViewModel.swift`
