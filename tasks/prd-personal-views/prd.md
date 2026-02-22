# PRD: Personal Trainer Views Redesign

## Overview
Redesign the Personal Trainer feature with 4 new screens based on Pencil mockups, replacing the current single-view approach with a richer experience: Trainer List, Chat, Workout History, and Progress Evolution.

## Reference Design
Screenshot: `/Users/viniciuscarvalho/Desktop/Captura de Tela 2026-02-21 às 17.48.32.png`

### Screen 1: Personal Trainers - List
- Header with back button and "Personal Trainers" title
- Search bar to filter trainers
- Trainer cards: circular photo (avatar), full name, star rating (score + count), bio with "Ver mais" expand, "Avaliar" (rate) button in brand purple
- Tab bar at bottom

### Screen 2: Personal - Chat
- Header: avatar, trainer name, online status (green dot)
- Segmented control: Chat / Historico / Evolucao (3 tabs)
- Chat bubbles: trainer messages (gray, left-aligned), user messages (purple, right-aligned) with timestamps
- Message input field with send button

### Screen 3: Personal - Historico (Workout History)
- Cards grouped by period ("Esta Semana" / "Semana Passada")
- Each card: workout name, date, exercise list (sets/reps/weight), completion status badge (green "Concluido" or yellow "Nao concluido")

### Screen 4: Personal - Evolucao (Evolution/Progress)
- 3 summary metric cards (+12% Load, 24 Workouts, 87% Frequency)
- Line chart showing load progression over 3 months (e.g. Supino Reto)
- Empty state: icon, message, CTA button

## Integration Points
- Entry point: Profile tab > Personal Trainer settings card (existing `.personalTrainer` route)
- The current `PersonalTrainerView` handles trainer discovery/connection. Once connected, the new screens should be the primary interface.
- Chat screen requires `trainerChatEnabled` feature flag
- Workout history and evolution use existing CMS/Firebase workout data

## Constraints
- Follow FitToday design system (dark theme, FitTodayColor/Font/Spacing/Radius)
- Use existing domain entities (PersonalTrainer, TrainerWorkout, etc.)
- Use existing repositories and use cases where possible
- Feature-flagged behind `personalTrainerEnabled`
- Swift 6 strict concurrency, @Observable pattern
