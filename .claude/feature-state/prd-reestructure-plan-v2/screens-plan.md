# Screens Plan - FitToday Pencil Design

## Design System Reference

Based on existing FitToday Design System:
- **Theme:** Dark Purple Futuristic
- **Primary Color:** #7C3AED (Purple)
- **Background:** #0D0D14 (Deep dark)
- **Surface:** #1E1E2E (Cards)
- **Neon Accent:** #00E5FF (Cyan)
- **Fonts:** Orbitron (Display), Rajdhani (UI), Bungee (Accent)
- **Effects:** Grid overlays, tech corners, scanlines, neon glow

---

## Screen 1: WorkoutTabView

### Description
Main workout tab with segmented control for "Meus Treinos" and "Programas"

### Components
- SegmentedControl (2 options)
- Header with title "Treinos"
- List of workout template cards (MyWorkoutsView)
- Floating "+" button to create workout
- Empty state when no workouts

### States
- **Default:** List of workout templates
- **Empty:** EmptyStateView with dumbbell icon
- **Loading:** Skeleton cards

---

## Screen 2: MyWorkoutsView (List)

### Description
Grid/List of user's workout templates

### Components
- WorkoutTemplateCard (multiple)
  - Icon (colored)
  - Name
  - Last performed date
  - Exercise count
  - Estimated duration
- Swipe actions (edit, delete)

---

## Screen 3: CreateWorkoutView

### Description
Workflow to create a new workout template

### Components
- Name TextField with label
- Icon picker (grid of SF Symbols)
- Color picker (palette)
- Exercise list (empty initially)
- "Add Exercise" button
- Save/Cancel buttons

### States
- **Empty:** No exercises added
- **With Exercises:** List of added exercises (draggable)
- **Saving:** Loading indicator

---

## Screen 4: ExerciseSearchSheet

### Description
Modal to search and add exercises from Wger API

### Components
- Search bar
- Filter chips (Muscle group, Equipment)
- Results list
  - Exercise image/placeholder
  - Exercise name
  - Target muscle
  - Equipment
  - Add button
- Loading state
- Empty search results

---

## Screen 5: ExerciseConfigSheet

### Description
Modal to configure sets for an exercise

### Components
- Exercise header (name, image)
- Sets table
  - Type picker (Warmup, Normal, etc.)
  - Reps stepper
  - Weight input
  - Delete button
- "Add Set" button
- Rest time picker
- Notes field
- Confirm button

---

## Screen 6: WorkoutExecutionView

### Description
Active workout session screen

### Components
- Header with timer, close button
- Progress bar (current/total exercises)
- Current exercise card
  - Large image
  - Exercise name
  - Muscle/Equipment info
- Sets tracking table
  - Set number
  - Target reps/weight
  - Completion checkbox
  - Actual reps/weight input
- "Complete Set" button
- Navigation arrows (prev/next exercise)

---

## Screen 7: RestTimerView

### Description
Rest timer modal between sets

### Components
- Large countdown timer (circular)
- Progress ring
- Skip button
- +30s button
- Next set preview

---

## Screen 8: WorkoutSummaryView

### Description
Post-workout summary and celebration

### Components
- Celebration animation/confetti
- Stats grid
  - Duration
  - Total volume
  - Sets completed
  - Exercises done
- Exercise summary list
- "Save to Templates" button (if AI-generated)
- Share button
- Done button

---

## Screen 9: ProgramsListView

### Description
Grid of pre-made workout programs

### Components
- Filter bar (Level, Goal, Equipment)
- Programs grid
  - Program card
    - Image/gradient background
    - Name
    - Level badge
    - Goal badge
    - Equipment badge
    - Days per week
- Filter applied indicator
- Clear filters button

---

## Screen 10: ProgramDetailView

### Description
Detailed view of a workout program

### Components
- Hero image/gradient header
- Program name
- Description
- Stats row (weeks, days/week, exercises)
- Badges (Level, Goal, Equipment)
- Workouts list
  - Day number
  - Workout name
  - Target muscles
  - Preview button
- "Start Program" button

---

## Screen 11: ActivityTabView

### Description
Unified activity tab with history, challenges, stats

### Components
- Segmented control (3 options)
  - Histórico
  - Desafios
  - Stats
- Content area switching based on selection

---

## Screen 12: WorkoutHistoryView

### Description
Calendar-based workout history

### Components
- Month calendar
  - Days with workouts highlighted (blue dots)
  - Month navigation
- Workout session list
  - Session card
    - Workout name
    - Date/time
    - Duration
    - Volume
    - Sets/exercises count

---

## Screen 13: ChallengesListView

### Description
Active and completed challenges

### Components
- "Active Challenges" section header
- Challenge cards
  - Icon/badge
  - Challenge name
  - Progress bar
  - Progress text (X/Y)
  - Days remaining
- "Completed" section (collapsed)

---

## Screen 14: StatsView

### Description
Workout statistics and charts

### Components
- Weekly stats bar chart
- Monthly volume line chart
- Personal records section
- Stat cards grid

---

## Screen 15: HomeTabView (New)

### Description
AI-powered home screen

### Components
- Greeting section ("Olá, [Name]!")
- AI Workout Input Card
  - Muscle selection grid
  - Fatigue slider
  - Time chips
  - "Generate" button
- Continue Workout card (if in progress)
- Streak progress bar
- Weekly summary card

---

## Screen 16: MuscleSelectionGrid

### Description
Grid to select target muscles

### Components
- 8 muscle group buttons
  - Icon
  - Label
  - Selected state (neon glow)
- Multi-select support

---

## Screen 17: AIGeneratingView

### Description
Loading state while AI generates workout

### Components
- Animated loading indicator
- Status text ("Analyzing...", "Generating...")
- Cancel button

---

## Screen 18: GeneratedWorkoutPreview

### Description
Preview of AI-generated workout

### Components
- Workout name
- Focus areas badges
- Estimated duration
- Exercise list preview
- "Start Workout" button
- "Save as Template" button
- "Regenerate" button

---

## Empty States

### EmptyWorkouts
- Dumbbell icon
- "No workouts yet"
- "Create your first workout"
- CTA button

### EmptyHistory
- Calendar icon
- "No workout history"
- "Complete a workout to see it here"

### EmptyChallenges
- Trophy icon
- "No active challenges"
- "Join a challenge to get started"

### EmptyPrograms (filtered)
- Filter icon
- "No programs match your filters"
- "Try adjusting filters"

### ErrorState
- Warning icon
- Error message
- Retry button

---

## Component Library

### Cards
- FitCard (base card)
- OptionCard (selectable)
- StatCard (metric display)
- WorkoutTemplateCard
- ProgramCard
- ChallengeCard
- SessionCard

### Buttons
- FitPrimaryButton
- FitSecondaryButton
- FitDestructiveButton
- FilterChip
- IconButton

### Inputs
- FitTextField
- FitStepper
- FitSlider
- FitPicker

### Feedback
- LoadingSpinner
- ProgressBar
- ProgressRing
- Badge
- Toast
