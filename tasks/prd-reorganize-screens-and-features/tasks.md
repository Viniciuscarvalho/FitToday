# Tasks — Reorganize Screens and Features

## Overview
Complete reorganization of FitToday app screens and flows across 6 areas: Welcome Onboarding, Home Redesign, Programs Tab, Workout Detail, AI Assistant (FitPal), and Profile Redesign.

**Total tasks:** 28
**Estimated effort:** 12 S + 12 M + 4 L

---

## Task List

| # | Title | Size | Priority | Status |
|---|-------|------|----------|--------|
| **Phase 0 — Foundation** | | | | |
| 1.0 | Add AppStorageKeys for onboarding | S | CRITICAL | pending |
| 2.0 | Add routes to AppRouter | S | CRITICAL | pending |
| 3.0 | Create AIChatMessage model | S | HIGH | pending |
| **Phase 1 — Welcome Onboarding** | | | | |
| 4.0 | Create WelcomeOnboardingView | M | HIGH | pending |
| 5.0 | Integrate onboarding gate in FitTodayApp | S | HIGH | pending |
| 6.0 | Simplify OnboardingFlowView | S | MEDIUM | pending |
| **Phase 2 — Home Redesign** | | | | |
| 7.0 | Create WeekStreakRow component | M | HIGH | pending |
| 8.0 | Create DailyWorkoutSuggestionCard | M | HIGH | pending |
| 9.0 | Create ExercisePreviewRow | S | HIGH | pending |
| 10.0 | Update HomeView and HomeViewModel | L | HIGH | pending |
| **Phase 3 — Programs Tab** | | | | |
| 11.0 | Create RecommendedProgramsSection | M | HIGH | pending |
| 12.0 | Update ProgramsListView | M | HIGH | pending |
| 13.0 | Adjust default tab to Programs | S | MEDIUM | pending |
| **Phase 4 — Workout Detail** | | | | |
| 14.0 | Create WorkoutHeroHeader | M | HIGH | pending |
| 15.0 | Update WorkoutPlanView | M | HIGH | pending |
| **Phase 5 — AI Assistant FitPal** | | | | |
| 16.0 | Create AIChatService | M | HIGH | pending |
| 17.0 | Create AIChatViewModel | M | HIGH | pending |
| 18.0 | Create FitTodayOrbView | S | MEDIUM | pending |
| 19.0 | Create AIChatView | L | HIGH | pending |
| 20.0 | Register AIChatService in AppContainer | S | HIGH | pending |
| 21.0 | Update TabRootView for FitPal tab | M | HIGH | pending |
| **Phase 6 — Profile Redesign** | | | | |
| 22.0 | Create ProfileHeaderSection | S | MEDIUM | pending |
| 23.0 | Create ProfileStatsRow | S | MEDIUM | pending |
| 24.0 | Update ProfileProView | M | MEDIUM | pending |
| **Phase 7 — Localization** | | | | |
| 25.0 | Add localization strings | M | MEDIUM | pending |
| **Phase 8 — Tests** | | | | |
| 26.0 | Unit tests for AIChatViewModel | M | MEDIUM | pending |
| 27.0 | Unit tests for HomeViewModel new properties | M | MEDIUM | pending |
| 28.0 | Build and visual verification | S | HIGH | pending |

---

## Task Details

---

### Phase 0 — Foundation

---

### Task 1.0 — Add AppStorageKeys for onboarding (S)

**Objective:** Add the `hasSeenWelcome` key to AppStorageKeys so it can gate the Welcome Onboarding flow.

**Files:**
- `FitToday/FitToday/Presentation/Support/AppStorageKeys.swift`

**Subtasks:**
- [ ] 1.1 Add `static let hasSeenWelcome = "hasSeenWelcome"` to the `AppStorageKeys` enum

**Success Criteria:**
- Key is available and compiles without errors
- No duplicate key names in the enum

**Dependencies:** None

---

### Task 2.0 — Add routes to AppRouter (S)

**Objective:** Add an `aiChat` route to the `AppRoute` enum so the FitTodayOrb AI chat screen is navigable.

**Files:**
- `FitToday/FitToday/Presentation/Router/AppRouter.swift`

**Subtasks:**
- [ ] 2.1 Add `case aiChat` to the `AppRoute` enum (line ~66 area)
- [ ] 2.2 Add `case .aiChat:` destination in `routeDestination(for:)` inside `TabRootView.swift` once `AIChatView` exists (deferred to Task 21.0)

**Success Criteria:**
- `AppRoute.aiChat` compiles and is usable in navigation
- No breaking changes to existing routes

**Dependencies:** None

---

### Task 3.0 — Create AIChatMessage model (S)

**Objective:** Create a domain model for AI chat messages with role-based conversation support.

**Files:**
- `FitToday/FitToday/Domain/Models/AIChatMessage.swift` (new file)

**Subtasks:**
- [ ] 3.1 Create `AIChatMessage` struct with properties: `id: UUID`, `role: Role`, `content: String`, `timestamp: Date`
- [ ] 3.2 Create nested `Role` enum: `case user, assistant, system`
- [ ] 3.3 Add `Identifiable` conformance (via `id` property)
- [ ] 3.4 Add `Codable` conformance

**Success Criteria:**
- Model compiles with `Identifiable` and `Codable` conformance
- Role enum covers user, assistant, and system roles
- Struct follows project convention of value types in Domain layer

**Dependencies:** None

---

### Phase 1 — Welcome Onboarding

---

### Task 4.0 — Create WelcomeOnboardingView (M)

**Objective:** Build a 3-4 page paged onboarding experience shown on first launch, introducing the app before the profile setup flow.

**Files:**
- `FitToday/FitToday/Presentation/Features/Onboarding/WelcomeOnboardingView.swift` (new file)

**Subtasks:**
- [ ] 4.1 Create view with `TabView` + `.tabViewStyle(.page)` for 3-4 welcome pages
- [ ] 4.2 Each page: SF Symbol icon, title text, description text
- [ ] 4.3 Use `FitTodayColor`, `FitTodayFont`, and `FitTodayGradient` design tokens from `Presentation/DesignSystem/DesignTokens.swift`
- [ ] 4.4 Add page indicators (`.indexViewStyle(.page(backgroundDisplayMode: .always))`)
- [ ] 4.5 "Continue" button on last page sets `@AppStorage(AppStorageKeys.hasSeenWelcome)` to `true`
- [ ] 4.6 Dark theme background using `FitTodayColor.background`

**Success Criteria:**
- Swipeable pages with smooth transitions
- "Continue" button only appears on the last page
- Tapping "Continue" persists `hasSeenWelcome = true` and transitions to main app
- Consistent with FitToday dark-purple design system

**Dependencies:** Task 1.0

---

### Task 5.0 — Integrate onboarding gate in FitTodayApp (S)

**Objective:** Gate the app entry point so first-time users see `WelcomeOnboardingView` before `TabRootView`.

**Files:**
- `FitToday/FitToday/FitTodayApp.swift`

**Subtasks:**
- [ ] 5.1 Add `@AppStorage(AppStorageKeys.hasSeenWelcome) private var hasSeenWelcome = false`
- [ ] 5.2 In `body`, conditionally show `WelcomeOnboardingView` when `hasSeenWelcome == false`, otherwise `TabRootView`

**Success Criteria:**
- First launch shows Welcome Onboarding
- After completing onboarding, app always shows TabRootView
- No regression in existing app startup flow

**Dependencies:** Task 1.0, Task 4.0

---

### Task 6.0 — Simplify OnboardingFlowView (S)

**Objective:** Remove the `.progressive` and `.intro` modes from `OnboardingFlowView`, keeping only the `.full` mode (6-step profile configuration). The Welcome Onboarding is now handled by the new `WelcomeOnboardingView`.

**Files:**
- `FitToday/FitToday/Presentation/Features/Onboarding/OnboardingFlowView.swift`

**Subtasks:**
- [ ] 6.1 Remove `.progressive` and `.intro` from the mode/stage enum
- [ ] 6.2 Simplify to only support the full 6-step profile setup flow
- [ ] 6.3 Remove any conditional logic branching on removed modes
- [ ] 6.4 Verify `isEditing` mode (edit profile) still works correctly

**Success Criteria:**
- OnboardingFlowView only supports full profile setup (6 steps)
- Edit profile flow (accessed from Profile tab) still works
- No dead code remaining from removed modes

**Dependencies:** Task 4.0

---

### Phase 2 — Home Redesign

---

### Task 7.0 — Create WeekStreakRow component (M)

**Objective:** Create a horizontal row showing 7 day circles (S M T W T F S) indicating workout completion for the current week.

**Files:**
- `FitToday/FitToday/Presentation/Features/Home/Components/WeekStreakRow.swift` (new file)

**Subtasks:**
- [ ] 7.1 Create `WeekStreakRow` view with an `HStack` of 7 circles
- [ ] 7.2 Each circle shows the day initial (S, M, T, W, T, F, S)
- [ ] 7.3 Filled circle with `FitTodayColor.brandPrimary` for days with completed workouts
- [ ] 7.4 Unfilled/outline circle with `FitTodayColor.outline` for pending days
- [ ] 7.5 Accept data from `UserStats.currentStreak` + weekly workout history
- [ ] 7.6 Highlight today's circle with a subtle ring or different border

**Success Criteria:**
- Correctly reflects which days of the current week had workouts
- Visually consistent with dark-purple design system
- Compact enough to fit at the top of HomeView

**Dependencies:** None

---

### Task 8.0 — Create DailyWorkoutSuggestionCard (M)

**Objective:** Create a card component showing the AI-recommended daily workout with image, title, duration, level, and a "Start Workout" CTA.

**Files:**
- `FitToday/FitToday/Presentation/Features/Home/Components/DailyWorkoutSuggestionCard.swift` (new file)

**Subtasks:**
- [ ] 8.1 Create card layout: workout image area, title, duration label, level badge
- [ ] 8.2 "Start Workout" button that navigates to workout detail (via `AppRouter`)
- [ ] 8.3 Use `ProgramRecommender` (from `Domain/UseCases/ProgramRecommender.swift`) for the daily suggestion
- [ ] 8.4 Apply design system gradients (`FitTodayColor.gradientPrimary`), corner radius (`FitTodayRadius.md`), and card shadow (`fitCardShadow()`)
- [ ] 8.5 Handle empty/loading state gracefully

**Success Criteria:**
- Card displays suggested workout with all required info
- Tapping "Start Workout" navigates to the workout detail screen
- Gracefully handles case when no suggestion is available

**Dependencies:** None

---

### Task 9.0 — Create ExercisePreviewRow (S)

**Objective:** Create a compact row showing exercise preview info (image, name, sets x reps or cardio details).

**Files:**
- `FitToday/FitToday/Presentation/Features/Home/Components/ExercisePreviewRow.swift` (new file)

**Subtasks:**
- [ ] 9.1 Create row with: exercise image (using existing `ExerciseMediaImage` from `Presentation/DesignSystem/ExerciseMediaImage.swift` or `ExercisePlaceholderView`), name, and prescription summary
- [ ] 9.2 For strength exercises: display "3x12" style sets x reps
- [ ] 9.3 For cardio exercises: display warmup description + time
- [ ] 9.4 Consistent sizing and spacing with existing list rows

**Success Criteria:**
- Correctly renders both strength and cardio exercise formats
- Reuses existing image components (no duplication)
- Compact enough for a list inside the Home tab

**Dependencies:** None

---

### Task 10.0 — Update HomeView and HomeViewModel (L)

**Objective:** Redesign the Home tab layout to feature WeekStreakRow, DailyWorkoutSuggestionCard, and an exercise preview list as the primary content.

**Files:**
- `FitToday/FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/FitToday/Presentation/Features/Home/HomeViewModel.swift`

**Subtasks:**
- [ ] 10.1 Add `dailySuggestedWorkout` property to `HomeViewModel` using `ProgramRecommender`
- [ ] 10.2 Add `weekStreakData` property (array of 7 booleans for current week)
- [ ] 10.3 Load daily suggestion and streak data in the existing `loadData()` method
- [ ] 10.4 Update `HomeView` layout: `WeekStreakRow` at top, then `DailyWorkoutSuggestionCard`, then exercise preview list using `ExercisePreviewRow`
- [ ] 10.5 Maintain existing loading, error, and empty states
- [ ] 10.6 Keep existing components that are still relevant (e.g., `ContinueWorkoutCard`, `HomeHeader`)

**Success Criteria:**
- Home tab displays new layout with streak, suggestion card, and exercises
- Existing functionality (loading, error states, continue workout) is preserved
- ViewModel fetches daily suggestion without blocking UI

**Dependencies:** Task 7.0, Task 8.0, Task 9.0

---

### Phase 3 — Programs Tab

---

### Task 11.0 — Create RecommendedProgramsSection (M)

**Objective:** Create a horizontal scrolling section showing the top 3-5 AI-recommended programs.

**Files:**
- `FitToday/FitToday/Presentation/Features/Programs/Views/RecommendedProgramsSection.swift` (new file)

**Subtasks:**
- [ ] 11.1 Create section with title "Recommended for You" and horizontal `ScrollView`
- [ ] 11.2 Use `ProgramRecommender` (from `Domain/UseCases/ProgramRecommender.swift`) to get top 3-5 programs
- [ ] 11.3 Each card: program image, name, duration, fitness level badge
- [ ] 11.4 Tapping a card navigates to `AppRoute.programDetail(programId)`
- [ ] 11.5 Apply category-specific gradients from `FitTodayColor` (e.g., `gradientStrength`, `gradientConditioning`)

**Success Criteria:**
- Horizontal scroll with 3-5 recommended program cards
- Cards use appropriate category gradients
- Navigation to program detail works

**Dependencies:** None

---

### Task 12.0 — Update ProgramsListView (M)

**Objective:** Add the recommended section at the top and organize the 26 programs by `ProgramCategory` with collapsible groups.

**Files:**
- `FitToday/FitToday/Presentation/Features/Programs/Views/ProgramsListView.swift`

**Subtasks:**
- [ ] 12.1 Add `RecommendedProgramsSection` at the top of the list
- [ ] 12.2 Group remaining programs by `ProgramCategory` (enum defined in `Domain/Entities/ProgramModels.swift`)
- [ ] 12.3 Implement collapsible `DisclosureGroup` or expandable sections per category
- [ ] 12.4 Improve card visuals with design system tokens
- [ ] 12.5 Maintain existing search and filtering if present

**Success Criteria:**
- Recommended section appears prominently at top
- All 26 programs are grouped by category
- Categories are collapsible/expandable
- No regression in existing navigation to program details

**Dependencies:** Task 11.0

---

### Task 13.0 — Adjust default tab to Programs (S)

**Objective:** Change the default selected segment in `WorkoutTabView` from "My Workouts" to "Programs".

**Files:**
- `FitToday/FitToday/Presentation/Features/Workout/Views/WorkoutTabView.swift`

**Subtasks:**
- [ ] 13.1 Change `@State private var selectedSegment: WorkoutSegment = .myWorkouts` to `.programs`
- [ ] 13.2 Verify the 3 segments remain: My Workouts, Programs, Personal

**Success Criteria:**
- WorkoutTabView opens with Programs segment selected by default
- All three segments still function correctly

**Dependencies:** None

---

### Phase 4 — Workout Detail

---

### Task 14.0 — Create WorkoutHeroHeader (M)

**Objective:** Create a full-width hero image header with gradient overlay for workout detail screens.

**Files:**
- `FitToday/FitToday/Presentation/Features/Workout/Components/WorkoutHeroHeader.swift` (new file)

**Subtasks:**
- [ ] 14.1 Create view with full-width image area (~250pt height)
- [ ] 14.2 Add bottom gradient overlay (dark to transparent) with title, duration, level text
- [ ] 14.3 Add equipment badge row below the image
- [ ] 14.4 Use `FitTodayColor.gradientBackground` or category-specific gradient as overlay
- [ ] 14.5 Handle missing image gracefully with placeholder

**Success Criteria:**
- Hero header renders with image, overlay text, and equipment badges
- Gradient overlay ensures text readability over any image
- Placeholder displayed when no image is available

**Dependencies:** None

---

### Task 15.0 — Update WorkoutPlanView (M)

**Objective:** Replace the existing header with `WorkoutHeroHeader` and improve the exercise rows with images and better layout.

**Files:**
- `FitToday/FitToday/Presentation/Features/Workout/WorkoutPlanView.swift`

**Subtasks:**
- [ ] 15.1 Replace current header (likely `WorkoutPlanHeader` from `Components/WorkoutPlanHeader.swift`) with `WorkoutHeroHeader`
- [ ] 15.2 Add "Equipment Needed" section with SF Symbol icons for each equipment type
- [ ] 15.3 Improve exercise rows with images (reuse `ExerciseMediaImage`), name, and sets/reps display
- [ ] 15.4 Maintain existing reorder, delete, and add exercise functionality
- [ ] 15.5 Ensure "Start Workout" button is still prominently accessible

**Success Criteria:**
- Workout detail screen has the new hero header
- Equipment section displays relevant icons
- All existing CRUD operations on exercises still work
- No regression in workout execution flow

**Dependencies:** Task 14.0

---

### Phase 5 — AI Assistant FitTodayOrb

---

### Task 16.0 — Create AIChatService (M)

**Objective:** Create a data-layer service that wraps `NewOpenAIClient` for conversational AI chat mode.

**Files:**
- `FitToday/FitToday/Data/Services/AIChatService.swift` (new file)

**Subtasks:**
- [ ] 16.1 Create `AIChatService` actor (or class with `@unchecked Sendable`) for thread safety
- [ ] 16.2 Implement `sendMessage(_ message: String, history: [AIChatMessage]) async throws -> String`
- [ ] 16.3 Build system prompt defining the fitness assistant persona
- [ ] 16.4 Reuse `NewOpenAIClient` actor (from `Data/Services/OpenAI/NewOpenAIClient.swift`) for API calls
- [ ] 16.5 Reuse `UserAPIKeyManager` (from `Data/Services/OpenAI/UserAPIKeyManager.swift`) for API key resolution
- [ ] 16.6 Map `AIChatMessage` history to OpenAI message format

**Success Criteria:**
- Service sends conversation history and returns assistant response
- System prompt establishes FitTodayOrb as a knowledgeable fitness assistant
- Proper error handling for missing API key, network errors
- Thread-safe implementation compatible with Swift 6 concurrency

**Dependencies:** Task 3.0

---

### Task 17.0 — Create AIChatViewModel (M)

**Objective:** Create the presentation-layer ViewModel for the AI chat screen with message management and send functionality.

**Files:**
- `FitToday/FitToday/Presentation/Features/AIChat/AIChatViewModel.swift` (new file)

**Subtasks:**
- [ ] 17.1 Create `@Observable` class `AIChatViewModel`
- [ ] 17.2 Properties: `messages: [AIChatMessage]`, `inputText: String`, `isLoading: Bool`, `errorMessage: String?`
- [ ] 17.3 Implement `sendMessage()` that appends user message, calls `AIChatService`, appends assistant response
- [ ] 17.4 Add quick action suggestions: "Plan my workout", "Suggest exercises for back", "How to improve my deadlift", etc.
- [ ] 17.5 Handle loading state (disable send while waiting)
- [ ] 17.6 Handle error state with user-friendly message

**Success Criteria:**
- Messages append correctly in conversation order
- Loading state prevents duplicate sends
- Errors are displayed and recoverable (user can retry)
- Quick actions populate the input field or send directly

**Dependencies:** Task 16.0

---

### Task 18.0 — Create FitTodayOrbView (S)

**Objective:** Create an animated orb graphic displayed as the empty state of the AI chat screen.

**Files:**
- `FitToday/FitToday/Presentation/Features/AIChat/Components/FitTodayOrbView.swift` (new file)

**Subtasks:**
- [ ] 18.1 Create an animated `Circle` with `FitTodayColor.gradientPrimary` gradient fill
- [ ] 18.2 Add pulse animation (scale + opacity cycle)
- [ ] 18.3 "FitTodayOrb" title text below the orb
- [ ] 18.4 "Your AI Fitness Assistant" subtitle text
- [ ] 18.5 Use `FitTodayFont.display` for title and `FitTodayFont.ui` for subtitle

**Success Criteria:**
- Orb animates smoothly with a pulsing effect
- Text is readable and centered below the orb
- Consistent with the app's purple/dark design aesthetic

**Dependencies:** None

---

### Task 19.0 — Create AIChatView (L)

**Objective:** Build the full AI chat screen with entitlement gating, empty state, message list, quick actions, and input field.

**Files:**
- `FitToday/FitToday/Presentation/Features/AIChat/AIChatView.swift` (new file)

**Subtasks:**
- [ ] 19.1 Gate screen with `EntitlementPolicy` (from `Domain/Entities/EntitlementPolicy.swift`) for Pro feature check
- [ ] 19.2 Free users: show upsell screen with feature benefits list and "Subscribe" button navigating to paywall
- [ ] 19.3 Pro users: show chat UI
- [ ] 19.4 Empty state: `FitTodayOrbView` centered with quick action chips below
- [ ] 19.5 Messages state: `ScrollView` with messages using `ChatBubble` (from `Presentation/Features/PersonalTrainer/Components/ChatBubble.swift`)
- [ ] 19.6 Quick action chips as horizontal scroll at the top
- [ ] 19.7 Input field + send button pinned at bottom with `safeAreaInset` or similar
- [ ] 19.8 Auto-scroll to latest message on new content
- [ ] 19.9 Keyboard handling (scroll to bottom when keyboard appears)

**Success Criteria:**
- Free users see upsell, Pro users see chat
- Empty state shows animated orb with quick actions
- Messages render correctly with role-appropriate styling
- Input field is always accessible with send button
- Smooth auto-scrolling on new messages

**Dependencies:** Task 17.0, Task 18.0

---

### Task 20.0 — Register AIChatService in AppContainer (S)

**Objective:** Register `AIChatService` in the Swinject dependency injection container so it can be resolved by ViewModels.

**Files:**
- `FitToday/FitToday/Presentation/DI/AppContainer.swift`

**Subtasks:**
- [ ] 20.1 Add `container.register(AIChatService.self) { ... }` in the `build()` method
- [ ] 20.2 Resolve `NewOpenAIClient` and `UserAPIKeyManager` dependencies as constructor arguments
- [ ] 20.3 Use `.inObjectScope(.container)` for singleton lifetime (conversation persists across tab switches)

**Success Criteria:**
- `AIChatService` resolves correctly from the container
- Dependencies are properly injected
- No circular dependency issues

**Dependencies:** Task 16.0

---

### Task 21.0 — Update TabRootView for FitTodayOrb tab (M)

**Objective:** Replace the center "Create" tab (plus.circle.fill) with a "FitTodayOrb" tab (sparkles) that navigates to the AI chat screen.

**Files:**
- `FitToday/FitToday/Presentation/Root/TabRootView.swift`
- `FitToday/FitToday/Presentation/Router/AppRouter.swift` (update `AppTab` enum)

**Subtasks:**
- [ ] 21.1 In `AppTab` enum: replace `.create` with `.fitpal` (or rename)
- [ ] 21.2 Update `AppTab.title` to return "FitPal" and `systemImage` to return "sparkles"
- [ ] 21.3 In `TabRootView`: replace the `.create` tab content with `AIChatView`
- [ ] 21.4 Remove the `showCreateWorkout` sheet logic and `Color.clear` workaround for the center tab
- [ ] 21.5 New tab order: Home, Workout (Programs), FitPal, Activity, Profile
- [ ] 21.6 Ensure the "Create Workout" sheet is accessible from another location (e.g., Workout tab FAB or Programs section)

**Success Criteria:**
- Tab bar shows: Home, Programs, FitTodayOrb (sparkles), Activity, Profile
- FitTodayOrb tab opens AIChatView
- "Create Workout" functionality is still accessible from the Workout tab
- No navigation regressions

**Dependencies:** Task 2.0, Task 19.0

---

### Phase 6 — Profile Redesign

---

### Task 22.0 — Create ProfileHeaderSection (S)

**Objective:** Create a profile header component with a circular photo placeholder and user name.

**Files:**
- `FitToday/FitToday/Presentation/Features/Pro/Components/ProfileHeaderSection.swift` (new file)

**Subtasks:**
- [ ] 22.1 Create circular image placeholder with user initials (from `UserProfile` entity at `Domain/Entities/UserProfile.swift`)
- [ ] 22.2 Display user name below the avatar
- [ ] 22.3 Use `FitTodayColor.brandPrimary` as avatar background gradient
- [ ] 22.4 Handle case where no name is set (show default)

**Success Criteria:**
- Avatar circle shows user initials
- Name displays below avatar
- Handles missing profile data gracefully

**Dependencies:** None

---

### Task 23.0 — Create ProfileStatsRow (S)

**Objective:** Create a horizontal stats row showing streak days, total minutes, and completed workouts.

**Files:**
- `FitToday/FitToday/Presentation/Features/Pro/Components/ProfileStatsRow.swift` (new file)

**Subtasks:**
- [ ] 23.1 Create `HStack` with 3 stat items: streak (flame icon), total minutes (clock icon), completed workouts (checkmark icon)
- [ ] 23.2 Each stat: SF Symbol icon + number + label
- [ ] 23.3 Data sourced from `UserStats` entity (at `Domain/Entities/UserStats.swift`) and `UserStatsCalculator` (at `Domain/Services/UserStatsCalculator.swift`)
- [ ] 23.4 Use `FitTodayColor.textPrimary` for numbers, `FitTodayColor.textSecondary` for labels

**Success Criteria:**
- Three stats displayed in a balanced horizontal layout
- Numbers update based on actual user data
- Icons match the stat they represent

**Dependencies:** None

---

### Task 24.0 — Update ProfileProView (M)

**Objective:** Add the new header and stats sections to the top of the Profile screen while maintaining all existing functionality.

**Files:**
- `FitToday/FitToday/Presentation/Features/Pro/ProfileProView.swift`

**Subtasks:**
- [ ] 24.1 Add `ProfileHeaderSection` at the top of the view
- [ ] 24.2 Add `ProfileStatsRow` below the header
- [ ] 24.3 Maintain all existing sections (settings, subscription, API key, HealthKit, privacy, etc.)
- [ ] 24.4 Reorganize layout for visual hierarchy: header > stats > existing sections
- [ ] 24.5 Ensure scrollable if content exceeds screen height

**Success Criteria:**
- Profile screen shows avatar, name, and stats at the top
- All existing profile functionality preserved
- Smooth scrolling with new content

**Dependencies:** Task 22.0, Task 23.0

---

### Phase 7 — Localization

---

### Task 25.0 — Add localization strings (M)

**Objective:** Add all new user-facing strings to both pt-BR and en localization files.

**Files:**
- `FitToday/FitToday/Resources/pt-BR.lproj/Localizable.strings`
- `FitToday/FitToday/Resources/en.lproj/Localizable.strings`

**Subtasks:**
- [ ] 25.1 Add Welcome Onboarding strings (page titles, descriptions, button labels)
- [ ] 25.2 Add Home redesign strings (streak labels, suggestion card text, section titles)
- [ ] 25.3 Add AI Chat strings ("FitTodayOrb", "Your AI Fitness Assistant", quick actions, input placeholder, error messages, upsell text)
- [ ] 25.4 Add Profile strings (stats labels, header fallback text)
- [ ] 25.5 Add Programs strings ("Recommended for You", category names if not already localized)
- [ ] 25.6 Add FitPal tab name to tab localization keys
- [ ] 25.7 pt-BR as primary language, en as secondary

**Success Criteria:**
- All new strings have both pt-BR and en translations
- No hardcoded strings in any new views
- Existing localization keys are not broken

**Dependencies:** All previous tasks (Phase 0-6)

---

### Phase 8 — Tests

---

### Task 26.0 — Unit tests for AIChatViewModel (M)

**Objective:** Write unit tests covering the AIChatViewModel's message sending, loading states, and error handling.

**Files:**
- `FitToday/FitTodayTests/Presentation/Features/AIChatViewModelTests.swift` (new file)

**Subtasks:**
- [ ] 26.1 Create `MockAIChatService` spy/stub
- [ ] 26.2 Test `sendMessage()` appends user message and then assistant response
- [ ] 26.3 Test `isLoading` is `true` during API call and `false` after
- [ ] 26.4 Test error state when `AIChatService` throws
- [ ] 26.5 Test quick action triggers message send
- [ ] 26.6 Test empty input does not send

**Success Criteria:**
- All tests pass
- Coverage of happy path, loading state, and error scenarios
- Mock service properly isolates ViewModel logic

**Dependencies:** Task 17.0

---

### Task 27.0 — Unit tests for HomeViewModel new properties (M)

**Objective:** Write unit tests for the new `dailySuggestedWorkout` and `weekStreakData` properties added to `HomeViewModel`.

**Files:**
- `FitToday/FitTodayTests/Presentation/Features/HomeViewModelTests.swift` (update existing file)

**Subtasks:**
- [ ] 27.1 Create or update `MockProgramRecommender` stub
- [ ] 27.2 Test `dailySuggestedWorkout` returns a valid program workout
- [ ] 27.3 Test `dailySuggestedWorkout` handles nil/empty recommendation
- [ ] 27.4 Test `weekStreakData` returns correct 7-element array
- [ ] 27.5 Test loading state integration with new properties

**Success Criteria:**
- All tests pass
- New properties are tested for both populated and empty states
- Existing HomeViewModel tests still pass

**Dependencies:** Task 10.0

---

### Task 28.0 — Build and visual verification (S)

**Objective:** Build the full project with XcodeBuildMCP and visually verify all new/modified screens in the simulator.

**Files:**
- All modified and new files from tasks 1.0-27.0

**Subtasks:**
- [ ] 28.1 Run full build via `xcodebuildmcp` to verify zero compilation errors
- [ ] 28.2 Run unit tests via `xcodebuildmcp` to verify all tests pass
- [ ] 28.3 Visual check: Welcome Onboarding flow (3-4 pages, button on last page)
- [ ] 28.4 Visual check: Home tab (streak row, suggestion card, exercise list)
- [ ] 28.5 Visual check: Programs tab (recommended section, category groups, default segment)
- [ ] 28.6 Visual check: Workout Detail (hero header, equipment section)
- [ ] 28.7 Visual check: FitTodayOrb tab (upsell for free users, chat UI for pro)
- [ ] 28.8 Visual check: Profile (header, stats row, existing sections)
- [ ] 28.9 Verify tab bar: Home, Programs, FitTodayOrb, Activity, Profile

**Success Criteria:**
- Zero compilation errors and warnings
- All unit tests pass
- All screens render correctly in simulator
- No visual glitches, overlapping elements, or broken navigation
- Tab bar order and icons are correct

**Dependencies:** All previous tasks (1.0-27.0)

---

## Dependency Graph

```
Phase 0 (Foundation)
  Task 1.0 ──> Task 4.0, Task 5.0
  Task 2.0 ──> Task 21.0
  Task 3.0 ──> Task 16.0

Phase 1 (Onboarding)
  Task 4.0 ──> Task 5.0, Task 6.0
  Task 5.0 ──> (standalone)
  Task 6.0 ──> (standalone)

Phase 2 (Home)
  Task 7.0, 8.0, 9.0 ──> Task 10.0

Phase 3 (Programs)
  Task 11.0 ──> Task 12.0
  Task 13.0 ──> (standalone)

Phase 4 (Workout Detail)
  Task 14.0 ──> Task 15.0

Phase 5 (AI FitTodayOrb)
  Task 16.0 ──> Task 17.0, Task 20.0
  Task 17.0 ──> Task 19.0
  Task 18.0 ──> Task 19.0
  Task 19.0, Task 2.0 ──> Task 21.0

Phase 6 (Profile)
  Task 22.0, 23.0 ──> Task 24.0

Phase 7 (Localization)
  All Phase 0-6 ──> Task 25.0

Phase 8 (Tests)
  Task 17.0 ──> Task 26.0
  Task 10.0 ──> Task 27.0
  All tasks ──> Task 28.0
```

---

## Notes

- **Design System:** All new views must use tokens from `Presentation/DesignSystem/DesignTokens.swift` (FitTodayColor, FitTodayFont, FitTodaySpacing, FitTodayRadius).
- **Architecture:** Follow MVVM with `@Observable` ViewModels. Use Swinject for DI. Domain layer stays pure (no SwiftUI imports).
- **Concurrency:** Swift 6 strict concurrency. Use `async/await`. Services should be `actor` or `@unchecked Sendable`.
- **Localization:** All user-facing strings must use `.localized` extension. pt-BR primary, en secondary.
- **Existing Components to Reuse:** `ExerciseMediaImage`, `ExercisePlaceholderView`, `ChatBubble`, `ProgramRecommender`, `NewOpenAIClient`, `UserAPIKeyManager`, `EntitlementPolicy`, `UserStats`, `UserProfile`.
