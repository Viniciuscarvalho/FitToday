# Task 14.0: Contextual Quick Actions (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Replace hardcoded quick actions with context-aware suggestions based on user state.

<requirements>
- Quick actions vary based on user profile and stats
- Time-of-day awareness
- Localized in EN + PT-BR
</requirements>

## Subtasks

- [ ] 14.1 In `Presentation/Features/AIChat/AIChatViewModel.swift`:
  - Change `static var quickActions: [String]` to computed instance property
  - Add `UserProfileRepository` and `UserStatsRepository` dependencies (may already exist from Task 9)
  - Add `private(set) var quickActions: [String] = []`
  - Add `func loadQuickActions() async`:
    - Load profile and stats
    - Build context-based suggestions:
      - If no workout today (lastWorkoutDate != today): "Sugerir treino de hoje"
      - If workout completed today: "Dicas de recuperacao"
      - Based on goal (hypertrophy vs weight loss): goal-specific suggestions
      - Time: morning -> "Aquecimento matinal", evening -> "Alongamento noturno"
    - Fallback to generic actions if no data
- [ ] 14.2 Add localization keys to Localizable.strings (done in Task 15)
- [ ] 14.3 Call `loadQuickActions()` from `loadHistory()` or `.task` in View
- [ ] 14.4 Test: correct quick actions for different user states

## Implementation Details

- **Time check**: `Calendar.current.component(.hour, from: Date())`
- **Last workout check**: Compare `stats.lastWorkoutDate` with today
- **Goal mapping**: `profile.mainGoal` -> specific suggestions

## Success Criteria

- Quick actions change based on user context
- Fallback to defaults if no profile
- Tests pass

## Relevant Files
- `Presentation/Features/AIChat/AIChatViewModel.swift` — main modification
- `Domain/Entities/UserProfile.swift` — goal types
- `Domain/Entities/UserStats.swift` — lastWorkoutDate

## Dependencies
- Task 9 (ViewModel with persistence and repo access)

## status: pending

<task_context>
<domain>presentation</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies>task_9</dependencies>
</task_context>
