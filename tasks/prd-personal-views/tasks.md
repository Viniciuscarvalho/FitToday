# Tasks: Personal Trainer Views

## Task 1: TrainerRatingCard Component + TrainerListView
**Files:** `Components/TrainerRatingCard.swift`, `TrainerListView.swift`
**Description:** Create the trainer card component with circular avatar, name, star rating (score + count), expandable bio, and "Avaliar" button. Then create TrainerListView with search bar and list of TrainerRatingCards. Integrate with existing `PersonalTrainerViewModel.searchTrainers()`.
**Acceptance:** Trainer list displays with search functionality, cards match mockup design.

## Task 2: ChatBubble Component + TrainerChatView
**Files:** `Components/ChatBubble.swift`, `TrainerChatView.swift`, `TrainerChatViewModel.swift`
**Description:** Create chat bubble component (left-aligned gray for trainer, right-aligned purple for user, with timestamps). Create TrainerChatView with message list and input field. Create TrainerChatViewModel with mock messages for now (real chat backend is out of scope). Gate behind `trainerChatEnabled` flag.
**Acceptance:** Chat UI renders with styled bubbles, input field works, scroll-to-bottom behavior.

## Task 3: WorkoutHistoryCard Component + TrainerHistoryView
**Files:** `Components/WorkoutHistoryCard.swift`, `TrainerHistoryView.swift`
**Description:** Create history card showing workout name, date, exercise list (sets/reps/weight), and completion status badge. Create TrainerHistoryView that groups workouts by period ("Esta Semana" / "Semana Passada"). Use existing assigned workouts from ViewModel.
**Acceptance:** History view shows grouped workout cards with exercise details and status badges.

## Task 4: EvolutionMetricCard + TrainerEvolutionView with Chart
**Files:** `Components/EvolutionMetricCard.swift`, `TrainerEvolutionView.swift`
**Description:** Create metric summary cards (+X% Load, N Workouts, X% Frequency). Create evolution view with Swift Charts line chart showing weight progression. Include empty state with icon, message, and CTA. Compute metrics from workout history.
**Acceptance:** Evolution view shows metrics, chart renders, empty state displays when no data.

## Task 5: TrainerDashboardView + Integration
**Files:** `TrainerDashboardView.swift`, `PersonalTrainerView.swift`
**Description:** Create dashboard view with header (avatar, name, online status) and segmented control (Chat / Historico / Evolucao). Integrate into PersonalTrainerView — when trainer is connected, show TrainerDashboardView. Wire TrainerListView for the non-connected state.
**Acceptance:** Connected state shows dashboard with 3 tabs. Non-connected state shows trainer list with search.

## Task 6: Localization + Build Verification
**Files:** `Localizable.strings` (both en/pt-BR)
**Description:** Add all localization strings for the 4 new screens. Build the project and verify no compilation errors.
**Acceptance:** BUILD SUCCEEDED. All strings properly localized in both languages.
