# TechSpec: Personal Trainer Views Redesign

## Architecture

```
PersonalTrainerView (existing, handles discovery/connection)
    └─ When connected → navigates to TrainerDashboardView (NEW)
        ├─ Segmented Control: Chat / Historico / Evolucao
        ├─ TrainerChatView (NEW)
        ├─ TrainerHistoryView (NEW)
        └─ TrainerEvolutionView (NEW)

TrainerListView (NEW) — replaces search, shows rated trainers
```

## New Files

### Views
1. `Presentation/Features/PersonalTrainer/TrainerListView.swift` — Trainer list with search, rating cards
2. `Presentation/Features/PersonalTrainer/TrainerDashboardView.swift` — Connected trainer dashboard with segmented tabs
3. `Presentation/Features/PersonalTrainer/TrainerChatView.swift` — Chat interface with message bubbles
4. `Presentation/Features/PersonalTrainer/TrainerHistoryView.swift` — Workout history grouped by period
5. `Presentation/Features/PersonalTrainer/TrainerEvolutionView.swift` — Progress metrics and chart

### Components
6. `Presentation/Features/PersonalTrainer/Components/TrainerRatingCard.swift` — Card with avatar, name, stars, bio, rate button
7. `Presentation/Features/PersonalTrainer/Components/ChatBubble.swift` — Message bubble (left/right aligned)
8. `Presentation/Features/PersonalTrainer/Components/WorkoutHistoryCard.swift` — History card with exercises and status
9. `Presentation/Features/PersonalTrainer/Components/EvolutionMetricCard.swift` — Summary metric card (+12% Load, etc.)

### ViewModel Extensions
10. `Presentation/Features/PersonalTrainer/TrainerChatViewModel.swift` — Chat state management

## Files to Modify
- `PersonalTrainerView.swift` — When connected, show TrainerDashboardView instead of current inline layout
- `PersonalTrainerViewModel.swift` — Add chat message properties and methods (if chat enabled)
- `AppRouter.swift` — Add new routes if needed
- `Localizable.strings` (both) — Add strings for new screens

## Files NOT to Modify
- Domain entities (PersonalTrainerModels.swift) — use as-is
- Use cases — use existing ones
- Repositories — use existing ones
- AppContainer.swift — no new DI registrations needed (ViewModels resolve from Resolver)

## Design System Usage
- Colors: `FitTodayColor.background`, `.surface`, `.brandPrimary`, `.textPrimary`, `.textSecondary`, `.success`, `.warning`
- Fonts: `FitTodayFont.ui(size:weight:)` for all UI text, `.display(size:weight:)` for titles
- Spacing: `FitTodaySpacing.xs/sm/md/lg/xl`
- Radius: `FitTodayRadius.sm/md/lg`
- Weights available: `.medium`, `.semiBold`, `.bold` (NO .regular)

## Data Strategy
- **Chat**: Placeholder/mock UI — actual chat backend (Firebase or CMS) is out of scope for this PR. Structure the view to accept a data source later.
- **History**: Use existing `assignedWorkouts` from `PersonalTrainerViewModel` + CMS workout data
- **Evolution**: Compute from workout history entries (sets, reps, weight progression). Use Swift Charts for the line chart.
- **Trainer List**: Use existing `searchTrainers()` and `findByInviteCode()` from ViewModel

## Feature Flags
- All screens gated by `personalTrainerEnabled`
- Chat tab additionally gated by `trainerChatEnabled`
