# Technical Specification: FitToday App Screen and Flow Reorganization

**Version:** 1.0
**Date:** 2026-02-25
**Status:** Draft
**Author:** Engineering

---

## 1. Overview

### 1.1 Problem

The current FitToday app has several UX friction points that reduce engagement and discoverability:

1. **No first-run welcome experience.** New users are dropped directly into the full onboarding profile setup (`OnboardingFlowView` with intro + 6-step setup), creating a high-friction entry point. There is no lightweight welcome walkthrough that introduces the app's value before asking for commitment.

2. **Home screen lacks daily guidance.** `HomeView` centers around an AI Workout Generator card that requires user interaction (selecting focus, soreness, energy) before any suggestion appears. There is no passive daily recommendation or visual weekly streak overview.

3. **Programs tab is buried.** `WorkoutTabView` defaults to the `myWorkouts` segment. Programs -- the app's core content -- require an extra tap to discover. There are no personalized "Recommended for You" suggestions at the top of the programs list.

4. **Workout detail lacks visual hierarchy.** `WorkoutPlanView` uses a plain header. There is no hero image, gradient overlay, or equipment summary to set the workout's context before scrolling into exercises.

5. **The center "Create" tab is a placeholder redirect.** The `create` tab in `TabRootView` renders `Color.clear`, immediately opens a sheet, and redirects back to the workout tab -- a confusing pattern that wastes prime tab-bar real estate.

6. **No dedicated AI assistant experience.** The app's AI capability is limited to workout generation inside `HomeView`. There is no conversational AI interface for general fitness Q&A, despite having `NewOpenAIClient` and `ChatBubble` components already built.

7. **Profile screen lacks a personal identity section.** `ProfileProView` jumps straight into settings without showing the user's photo, name, or aggregated stats.

### 1.2 Solution

A phased reorganization of the app's screens and navigation flows to improve discoverability, reduce friction, and introduce a conversational AI assistant ("FitPal") in the center tab position.

### 1.3 Goals

| Goal | Metric | Target |
|------|--------|--------|
| Reduce first-session drop-off | Completion rate of first workout | +15% |
| Increase Programs discovery | Programs tab views per user/week | +30% |
| Drive AI engagement | AI chat messages sent per Pro user/week | 5+ |
| Improve Home retention | Daily Home screen visits | +20% |

---

## 2. Scope

### 2.1 In Scope

- **Phase 0:** Foundation changes (new `AppStorageKeys`, new `AppRoute.aiChat`, new `AIChatMessage` domain model)
- **Phase 1:** Welcome onboarding gate before `TabRootView`
- **Phase 2:** Home screen redesign (week streak row, daily workout suggestion card, exercise preview rows)
- **Phase 3:** Programs tab improvements (recommended section, collapsible categories, default segment change)
- **Phase 4:** Workout detail hero header and equipment section
- **Phase 5:** FitPal AI assistant (service, view model, views, tab replacement)
- **Phase 6:** Profile header and stats section
- **Phase 7:** Localization for all new strings (pt-BR and en)

### 2.2 Out of Scope

- Backend API changes or new server endpoints
- SwiftData schema migrations (no new persistent models required)
- Changes to workout execution flow (`WorkoutExecutionView`, `WorkoutSessionStore`)
- Changes to social features (Groups, Challenges, Leaderboard)
- Changes to StoreKit / paywall flows
- Changes to Personal Trainer CMS integration
- UI tests (per project CLAUDE.md: "DO NOT write UITests during scaffolding phase")
- Dark mode / light mode toggle (app is dark-mode-only via `preferredColorScheme(.dark)`)

---

## 3. Requirements

### 3.1 Functional Requirements

#### FR-01: Welcome Onboarding Gate

| ID | Requirement |
|----|-------------|
| FR-01.1 | On first launch (`hasSeenWelcome == false`), show `WelcomeOnboardingView` instead of `TabRootView`. |
| FR-01.2 | The welcome flow is a `TabView` with `PageTabViewStyle` containing 3-4 pages. Each page has an SF Symbol icon, title, and description using `FitTodayFont` and `FitTodayColor` tokens. |
| FR-01.3 | The final page has a "Get Started" button that sets `hasSeenWelcome = true` in `@AppStorage` and transitions to `TabRootView`. |
| FR-01.4 | `OnboardingFlowView` is simplified: the `.intro` stage is removed. The view always starts in `.setup` stage with the existing 2-step progressive mode (goal + structure) as default. |

#### FR-02: Home Redesign

| ID | Requirement |
|----|-------------|
| FR-02.1 | A `WeekStreakRow` component shows 7 circle indicators (S-M-T-W-T-F-S) representing the current week. Circles are filled with `FitTodayColor.brandPrimary` for days with completed workouts. |
| FR-02.2 | A `DailyWorkoutSuggestionCard` shows a pre-computed daily workout suggestion with image, title, estimated duration, level badge, and "Start Workout" button. |
| FR-02.3 | `ExercisePreviewRow` shows each exercise in the suggested workout with Wger image, name, and prescription (sets x reps or cardio duration). |
| FR-02.4 | `HomeViewModel` exposes a `dailySuggestedWorkout` computed property that uses `ProgramRecommender` to pick a workout from the user's matched programs based on profile and history. |
| FR-02.5 | The existing AI Workout Generator card, streak banner, and user stats section remain available and are positioned below the new daily suggestion section. |

#### FR-03: Programs Tab Improvements

| ID | Requirement |
|----|-------------|
| FR-03.1 | `ProgramsListView` adds a `RecommendedProgramsSection` at the top -- a horizontal `ScrollView` with small program cards from `ProgramRecommender`. |
| FR-03.2 | Programs are grouped by `ProgramCategory` in collapsible `DisclosureGroup` sections. |
| FR-03.3 | `WorkoutTabView` changes its default `selectedSegment` from `.myWorkouts` to `.programs`. |

#### FR-04: Workout Detail Enhancement

| ID | Requirement |
|----|-------------|
| FR-04.1 | A `WorkoutHeroHeader` component renders a full-width image (~250pt height) with a gradient overlay and the workout's title, estimated duration, and level badge. |
| FR-04.2 | `WorkoutPlanView` replaces its current header with `WorkoutHeroHeader`, adds an equipment summary section below the hero, and improves exercise row layout. |

#### FR-05: FitPal AI Assistant

| ID | Requirement |
|----|-------------|
| FR-05.1 | `AIChatService` wraps `NewOpenAIClient` to support multi-turn conversation. It accepts a `[AIChatMessage]` history and returns an assistant response. |
| FR-05.2 | `AIChatViewModel` is `@Observable`, holds `messages: [AIChatMessage]`, `inputText: String`, `isLoading: Bool`. It exposes `sendMessage()` and pre-built quick action prompts. |
| FR-05.3 | `FitPalOrbView` is a decorative animated component: a purple `Circle` with `FitTodayGradient` + pulse animation, "FitPal" label, and "Your AI Fitness Assistant" subtitle. Shown when the chat is empty. |
| FR-05.4 | `AIChatView` gates access via `EntitlementPolicy`: free users see an upsell view; pro users see the chat UI. The chat UI includes: `FitPalOrbView` (when empty), `ScrollView` of messages (reusing `ChatBubble` styling), quick action chips, and a text input field with send button. |
| FR-05.5 | `TabRootView` replaces the `.create` tab with `.fitPal` (using SF Symbol `sparkles`). The sheet/redirect logic for `showCreateWorkout` is removed from the tab; the "Create Workout" action moves to a floating button in `WorkoutTabView` (already exists). |
| FR-05.6 | `AppRouter.AppRoute` gains a new `case aiChat`. `AppRouter.AppTab` gains `case fitPal` replacing `case create`. |
| FR-05.7 | `AppContainer` registers `AIChatService` in the Swinject container. |

#### FR-06: Profile Redesign

| ID | Requirement |
|----|-------------|
| FR-06.1 | `ProfileHeaderSection` shows a circular photo placeholder with user initials and display name. |
| FR-06.2 | `ProfileStatsRow` shows 3 stat items in an `HStack`: current streak, weekly minutes, weekly workouts -- sourced from `UserStats`. |
| FR-06.3 | `ProfileProView` integrates the header and stats at the top, above existing sections. |

#### FR-07: Localization

| ID | Requirement |
|----|-------------|
| FR-07.1 | All new user-facing strings are added to `Localizable.xcstrings` for both `en` and `pt-BR` locales. |

### 3.2 Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | All new views must use existing `FitTodayColor`, `FitTodayFont`, `FitTodaySpacing`, and `FitTodayRadius` design tokens. No hardcoded colors or font sizes. |
| NFR-02 | All new `@Observable` classes must be annotated with `@MainActor` to satisfy Swift 6 strict concurrency. |
| NFR-03 | New async operations must use `async/await` (no Combine, no callbacks). |
| NFR-04 | No new SwiftData `@Model` entities. `AIChatMessage` is a plain `Codable` struct (persisted via `UserDefaults` or in-memory only for v1). |
| NFR-05 | New views must not exceed 100 lines (per project coding standards). Extract subviews as needed. |
| NFR-06 | All AI features (FitPal) must respect `EntitlementPolicy` gating. Free users must not access the chat. |
| NFR-07 | The welcome onboarding gate must not add perceptible launch-time latency. The `@AppStorage` read is synchronous and fast. |
| NFR-08 | Build must compile without warnings on Xcode with Swift 6.0 strict concurrency enabled. |

---

## 4. Technical Approach

### 4.1 Architecture

The reorganization follows the existing three-layer MVVM architecture:

```
Presentation (SwiftUI Views + @Observable ViewModels)
    |
Domain (Pure structs, protocols, UseCases)
    |
Data (Repository implementations, DTOs, Services)
```

No architectural changes are required. All new code fits into existing layers:

- **Data layer:** `AIChatService` (wraps `NewOpenAIClient`)
- **Domain layer:** `AIChatMessage` model
- **Presentation layer:** All new views, view models, and components

### 4.2 Key Technologies

| Technology | Usage |
|------------|-------|
| SwiftUI | All UI components |
| `@Observable` / `@State` / `@Bindable` | State management (not `ObservableObject`) |
| Swinject | Dependency injection via `AppContainer` |
| `NewOpenAIClient` (actor) | OpenAI API calls for FitPal chat |
| `@AppStorage` | Welcome onboarding gate flag |
| `EntitlementPolicy` | Pro feature gating for FitPal |
| `ProgramRecommender` | Daily workout suggestion and program recommendations |

### 4.3 Component Inventory

#### 4.3.1 New Files

| File | Layer | Type | Description |
|------|-------|------|-------------|
| `Domain/Models/AIChatMessage.swift` | Domain | Model | Chat message struct (Identifiable, Codable) |
| `Data/Services/AIChatService.swift` | Data | Service | Conversational wrapper over `NewOpenAIClient` |
| `Presentation/Features/Onboarding/WelcomeOnboardingView.swift` | Presentation | View | First-launch welcome walkthrough |
| `Presentation/Features/Home/Components/WeekStreakRow.swift` | Presentation | Component | 7-day streak indicator |
| `Presentation/Features/Home/Components/DailyWorkoutSuggestionCard.swift` | Presentation | Component | Suggested workout card |
| `Presentation/Features/Home/Components/ExercisePreviewRow.swift` | Presentation | Component | Exercise summary row |
| `Presentation/Features/Programs/Components/RecommendedProgramsSection.swift` | Presentation | Component | Horizontal recommended programs scroll |
| `Presentation/Features/Workout/Components/WorkoutHeroHeader.swift` | Presentation | Component | Hero image header for workout detail |
| `Presentation/Features/FitPal/AIChatView.swift` | Presentation | View | Main FitPal chat screen |
| `Presentation/Features/FitPal/AIChatViewModel.swift` | Presentation | ViewModel | Chat state management |
| `Presentation/Features/FitPal/Components/FitPalOrbView.swift` | Presentation | Component | Animated orb for empty state |
| `Presentation/Features/Profile/Components/ProfileHeaderSection.swift` | Presentation | Component | User photo + name header |
| `Presentation/Features/Profile/Components/ProfileStatsRow.swift` | Presentation | Component | Stats bar (streak, minutes, workouts) |

#### 4.3.2 Modified Files

| File | Change Summary |
|------|---------------|
| `Presentation/Support/AppStorageKeys.swift` | Add `static let hasSeenWelcome = "hasSeenWelcome"` |
| `Presentation/Router/AppRouter.swift` | Add `case fitPal` to `AppTab` (replacing `case create`), add `case aiChat` to `AppRoute`, update `systemImage` and `title` for fitPal tab |
| `Presentation/Root/TabRootView.swift` | Replace `.create` tab content with `AIChatView`, remove `showCreateWorkout` sheet trigger from tab, add `case .aiChat` to `routeDestination` |
| `FitTodayApp.swift` | Add `@AppStorage(AppStorageKeys.hasSeenWelcome) private var hasSeenWelcome = false` gate; show `WelcomeOnboardingView` when `!hasSeenWelcome` |
| `Presentation/Features/Onboarding/OnboardingFlowView.swift` | Remove `.intro` stage enum case; always start in `.setup` stage |
| `Presentation/Features/Home/HomeView.swift` | Insert `WeekStreakRow` and `DailyWorkoutSuggestionCard` into body |
| `Presentation/Features/Home/HomeViewModel.swift` | Add `dailySuggestedWorkout` computed property |
| `Presentation/Features/Programs/Views/ProgramsListView.swift` | Add `RecommendedProgramsSection` at top, add collapsible `DisclosureGroup` per category |
| `Presentation/Features/Workout/Views/WorkoutTabView.swift` | Change `selectedSegment` default to `.programs` |
| `Presentation/Features/Workout/WorkoutPlanView.swift` | Replace header with `WorkoutHeroHeader`, add equipment section |
| `Presentation/Features/Pro/ProfileProView.swift` | Add `ProfileHeaderSection` and `ProfileStatsRow` at top |
| `Presentation/DI/AppContainer.swift` | Register `AIChatService` |

### 4.4 Navigation Flow Changes

**Current tab bar:**
```
[Home] [Workout] [Create*] [Activity] [Profile]
                     |
                  (sheet -> redirect to Workout)
```

**New tab bar:**
```
[Home] [Workout] [FitPal] [Activity] [Profile]
                     |
                  AIChatView (inline, no sheet)
```

**App launch flow change:**
```
Current:  App Launch -> TabRootView (always)
New:      App Launch -> hasSeenWelcome?
            No  -> WelcomeOnboardingView -> (tap Get Started) -> TabRootView
            Yes -> TabRootView (unchanged)
```

---

## 5. Data Model

### 5.1 New Model: AIChatMessage

```swift
// Domain/Models/AIChatMessage.swift

struct AIChatMessage: Identifiable, Codable, Sendable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
    }

    init(
        id: UUID = .init(),
        role: Role,
        content: String,
        timestamp: Date = .init()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
```

**Persistence strategy (v1):** In-memory only. Messages are held in `AIChatViewModel.messages` and lost on app restart. A future iteration may persist to `UserDefaults` or SwiftData if conversation history becomes a product requirement.

### 5.2 Existing Models Referenced

| Model | File | Usage in This Feature |
|-------|------|-----------------------|
| `UserProfile` | `Domain/Entities/UserProfile.swift` | Profile data for recommendations and FitPal context |
| `UserStats` | `Domain/Entities/UserStats.swift` | `currentStreak`, `weekWorkoutsCount`, `weekTotalMinutes` for profile stats row and streak visualization |
| `ProEntitlement` | `Domain/Entities/ProEntitlement.swift` | Pro/Free gating for FitPal |
| `Program` | `Domain/Entities/LibraryModels.swift` | Program recommendations |
| `WorkoutHistoryEntry` | (existing) | Streak calculation and recommendation input |

### 5.3 No SwiftData Changes

No new `@Model` classes are introduced. The existing `ModelContainer` schema remains:
```swift
Schema([
    SDUserProfile.self,
    SDWorkoutHistoryEntry.self,
    SDProEntitlementSnapshot.self,
    SDCachedWorkout.self,
    SDUserStats.self,
    SDCustomWorkoutTemplate.self,
    SDCustomWorkoutCompletion.self,
    SDSavedRoutine.self
])
```

---

## 6. Implementation Considerations

### 6.1 Design Patterns

| Pattern | Where Applied |
|---------|--------------|
| **MVVM with @Observable** | `AIChatViewModel` is `@MainActor @Observable final class`. Views use `@State` for local state and `@Bindable` for bindings to Observable objects. |
| **Dependency Injection (Swinject)** | `AIChatService` is registered in `AppContainer.build()`. Views resolve dependencies via `@Environment(\.dependencyResolver)`. |
| **Router Navigation** | New `AppRoute.aiChat` case added. `TabRootView.routeDestination(for:)` maps it to `AIChatView`. |
| **Feature Gating** | `AIChatView` checks `EntitlementPolicy.canAccess(.aiWorkoutGeneration, entitlement:)` before showing chat UI. Free users see an upsell view with a paywall button. |
| **Component Extraction** | Each new UI component is a standalone `struct View` in its own file under `Components/`. No view exceeds 100 lines. |

### 6.2 AIChatService Design

```swift
// Data/Services/AIChatService.swift

actor AIChatService: Sendable {
    private let client: NewOpenAIClient

    init(client: NewOpenAIClient) {
        self.client = client
    }

    /// Factory: creates service from user's stored API key.
    /// Returns nil if no key is configured.
    static func fromUserKey() -> AIChatService? {
        guard let client = NewOpenAIClient.fromUserKey() else { return nil }
        return AIChatService(client: client)
    }

    /// Sends a message in the context of a conversation history.
    /// - Parameters:
    ///   - userMessage: The new user message text
    ///   - history: Previous messages for context
    /// - Returns: The assistant's response text
    func sendMessage(_ userMessage: String, history: [AIChatMessage]) async throws -> String {
        // Build prompt from history + new message
        // Call client.generateWorkout(prompt:) with conversational prompt
        // Parse and return assistant content
    }
}
```

The service reuses the existing `NewOpenAIClient` actor (which already handles retries, timeouts, and error mapping). The system prompt is changed from workout-specific to a general fitness assistant persona.

### 6.3 AppTab Transition (create -> fitPal)

The `AppTab` enum change from `.create` to `.fitPal` affects:

1. **`AppRouter.swift`:** Rename enum case, update `title` (localized "FitPal"), update `systemImage` ("sparkles").
2. **`TabRootView.swift`:** Replace the `.create` tab's `Color.clear` + `onAppear` sheet trigger with a direct `AIChatView(resolver:)`. Remove `@State private var showCreateWorkout` and its `.sheet` modifier from `TabRootView` (the "Create Workout" sheet is already available via the floating action button in `WorkoutTabView`).
3. **`AppRouter.tabPaths`:** The `NavigationPath` for `.create` is replaced by `.fitPal`. Since paths are initialized in `AppRouter.init()` via `AppTab.allCases.forEach`, this happens automatically.

### 6.4 Welcome Gate in FitTodayApp

```swift
// FitTodayApp.swift (modified body)
@AppStorage(AppStorageKeys.hasSeenWelcome) private var hasSeenWelcome = false

var body: some Scene {
    WindowGroup {
        if hasSeenWelcome {
            TabRootView()
                // ... existing modifiers
        } else {
            WelcomeOnboardingView {
                hasSeenWelcome = true
            }
            .preferredColorScheme(.dark)
        }
    }
    // ... existing modelContainer and onChange
}
```

This is a simple conditional at the `WindowGroup` level. The `@AppStorage` read is synchronous and adds no launch-time latency.

### 6.5 OnboardingFlowView Simplification

The current `OnboardingFlowView` has two stages: `.intro` (TabView walkthrough pages) and `.setup` (profile questionnaire). Since the new `WelcomeOnboardingView` replaces the intro function, `OnboardingFlowView` is simplified:

- Remove the `Stage` enum entirely.
- Remove the `introView` computed property.
- The view always renders the `setupView` directly.
- The `isEditing` parameter is preserved for the edit-profile use case.

### 6.6 Error Handling

| Scenario | Handling |
|----------|---------|
| `AIChatService` fails (network error, API error) | `AIChatViewModel` sets `isLoading = false`, appends an error `AIChatMessage` with role `.system` displaying a localized error message. User can retry. |
| `NewOpenAIClient.fromUserKey()` returns `nil` (no API key) | `AIChatView` shows a setup prompt directing the user to `AppRoute.apiKeySettings`. |
| `ProgramRecommender` returns empty recommendations | `HomeView` hides the `DailyWorkoutSuggestionCard` and shows only the existing AI Generator card. |
| Welcome onboarding `@AppStorage` read fails | Impossible -- `@AppStorage` with a default value is infallible. |

### 6.7 Accessibility

- All new interactive elements include `.accessibilityLabel` and `.accessibilityHint`.
- `WeekStreakRow` circles use `.accessibilityElement(children: .combine)` with a summary label (e.g., "3 of 7 days completed this week").
- `FitPalOrbView` animation uses `@Environment(\.accessibilityReduceMotion)` to disable pulse when motion is reduced.
- Chat messages in `AIChatView` are marked with `.accessibilityLabel` combining role and content.

---

## 7. Testing Strategy

### 7.1 Unit Tests

| Test Suite | File | Coverage Target |
|------------|------|-----------------|
| `AIChatViewModelTests` | `FitTodayTests/Presentation/Features/AIChatViewModelTests.swift` | `sendMessage()` appends user + assistant messages, `isLoading` state transitions, error handling, quick action generation |
| `HomeViewModelTests` (extended) | `FitTodayTests/Presentation/Features/HomeViewModelTests.swift` | New `dailySuggestedWorkout` property, streak calculation for `WeekStreakRow` data |
| `AIChatServiceTests` | `FitTodayTests/Data/Services/AIChatServiceTests.swift` | Message prompt construction, error propagation from `NewOpenAIClient` |
| `AIChatMessageTests` | `FitTodayTests/Domain/Models/AIChatMessageTests.swift` | Codable round-trip, Role enum encoding |

### 7.2 Test Doubles

| Protocol / Type | Test Double | Purpose |
|-----------------|-------------|---------|
| `AIChatService` | `MockAIChatService` (stub) | Returns predefined responses for ViewModel tests |
| `ProgramRecommender` | Existing -- pure function, no mock needed | Direct invocation with fixture data |
| `EntitlementRepository` | `MockEntitlementRepository` (existing in test targets) | Simulate free/pro states for gating tests |
| `UserProfileRepository` | `MockUserProfileRepository` (existing in HomeView preview) | Provide fixture profiles |
| `WorkoutHistoryRepository` | `InMemoryHistoryRepository` (existing in TabRootView preview) | Provide fixture history for streak tests |

### 7.3 Build Verification

After each phase, run:
```
xcodebuildmcp build (iPhone 16 Pro simulator)
xcodebuildmcp test  (unit test suite)
```

### 7.4 Manual QA Checklist

- [ ] First launch shows `WelcomeOnboardingView`; subsequent launches skip it
- [ ] Home screen shows `WeekStreakRow` with correct day highlights
- [ ] Home screen shows `DailyWorkoutSuggestionCard` when profile exists
- [ ] Programs tab is the default segment in Workout tab
- [ ] `RecommendedProgramsSection` appears at top of Programs list
- [ ] Workout detail shows hero header with gradient
- [ ] FitPal tab opens `AIChatView`
- [ ] Free users see upsell view in FitPal tab
- [ ] Pro users can send messages and receive responses
- [ ] Profile shows header with name/photo and stats row
- [ ] All strings appear correctly in pt-BR and en

---

## 8. Dependencies

### 8.1 Internal Dependencies

| Dependency | Status | Required By |
|------------|--------|-------------|
| `NewOpenAIClient` (actor) | Exists at `Data/Services/OpenAI/NewOpenAIClient.swift` | Phase 5 (AIChatService) |
| `ChatBubble` component | Exists at `Presentation/Features/PersonalTrainer/Components/ChatBubble.swift` | Phase 5 (AIChatView message rendering) |
| `ProgramRecommender` | Exists at `Domain/UseCases/ProgramRecommender.swift` | Phase 2 (daily suggestion), Phase 3 (recommended section) |
| `EntitlementPolicy` + `ProFeature` | Exists at `Domain/Entities/EntitlementPolicy.swift` | Phase 5 (FitPal gating) |
| `UserStats` entity | Exists at `Domain/Entities/UserStats.swift` | Phase 2 (streak), Phase 6 (profile stats) |
| `UserStatsRepository` | Exists, registered in `AppContainer` | Phase 6 (load stats for profile) |
| Design System tokens | Exists at `Presentation/DesignSystem/DesignTokens.swift` | All phases |
| `AppContainer` (Swinject) | Exists at `Presentation/DI/AppContainer.swift` | Phase 5 (register AIChatService) |
| `AppRouter` + `TabRootView` | Exists at `Presentation/Router/` and `Presentation/Root/` | Phase 0, Phase 5 |

### 8.2 External Dependencies

| Dependency | Version | Required By |
|------------|---------|-------------|
| Swinject | Existing in project | DI registration |
| OpenAI API (gpt-4o-mini) | Via `NewOpenAIClient` | FitPal chat responses |
| Wger API | Via `WgerAPIService` | Exercise images in preview rows |

### 8.3 ChatBubble Reuse Consideration

The existing `ChatBubble` in `PersonalTrainer/Components/` expects a `ChatMessage` type (from trainer chat). For FitPal, we use `AIChatMessage`. Two options:

- **Option A (Recommended):** Create a lightweight `FitPalChatBubble` in `FitPal/Components/` that mirrors the styling but accepts `AIChatMessage`. This avoids coupling to the Personal Trainer feature's `ChatMessage` type.
- **Option B:** Extract a generic `ChatBubbleView<Message>` protocol. Higher effort, lower immediate value.

We choose **Option A** for simplicity.

---

## 9. Assumptions and Constraints

### 9.1 Assumptions

1. **User API key is required for FitPal.** The existing `NewOpenAIClient.fromUserKey()` pattern (reading from `UserAPIKeyManager`) is the only way to authenticate with OpenAI. There is no server-side proxy. If no key is set, the FitPal tab shows a configuration prompt instead of a chat.

2. **`ProgramRecommender` already handles the recommendation logic.** The `recommend(programs:profile:history:limit:)` method exists and is used in `HomeViewModel.loadProgramsAndWorkouts`. We reuse it for daily suggestions and the Programs tab recommendation section without modification.

3. **The app remains dark-mode-only.** All new views use `FitTodayColor` tokens, which are defined for a dark purple theme. No light-mode variants are needed.

4. **Localization follows the existing `.localized` string extension pattern.** The project uses `"key".localized` for string lookup. New keys are added to the existing `Localizable.xcstrings` file.

5. **Firebase Remote Config feature flags are not needed for this feature.** The reorganization ships as a full release, not behind a feature flag. The welcome gate uses a local `@AppStorage` flag.

### 9.2 Constraints

1. **Swift 6 strict concurrency.** All new `@Observable` classes must be `@MainActor`. The `AIChatService` actor is already `Sendable`. Cross-actor calls from ViewModels to services use `await`.

2. **No new SwiftData models.** Per NFR-04, `AIChatMessage` is not persisted to SwiftData. This avoids schema migration complexity and keeps the change set minimal.

3. **`ChatBubble` type mismatch.** The existing `ChatBubble` expects `ChatMessage` (from Personal Trainer). We create a new `FitPalChatBubble` rather than refactoring the shared type, to avoid regression risk in the Personal Trainer feature.

4. **Tab bar has exactly 5 tabs.** iOS HIG recommends 3-5 tabs. The replacement of `.create` with `.fitPal` maintains the 5-tab count. No tab is added or removed.

5. **Minimum iOS 17.** All APIs used (`@Observable`, `NavigationStack`, `TabView` with `PageTabViewStyle`) are available on iOS 17+.

6. **Phase ordering matters.** Phase 0 (foundation) must be completed before any other phase. Phases 1-6 can be parallelized across branches but must be integration-tested together. Phase 7 (localization) is the final pass.

### 9.3 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `NewOpenAIClient` rate limits under conversational load | Medium | Medium | Implement client-side rate limiting in `AIChatViewModel` (e.g., 1 message per 3 seconds). Show "typing..." indicator during API call. |
| Welcome onboarding interferes with deep links | Low | High | Deep link handler (`AppRouter.handle(url:)`) should set `hasSeenWelcome = true` before processing the link, bypassing the welcome gate. |
| Tab bar icon change confuses existing users | Low | Low | Use a recognizable SF Symbol (`sparkles`) and include the "FitPal" label. The "Create" tab was already a non-functional redirect. |
| `ProgramRecommender` returns no results for new users | Medium | Low | `DailyWorkoutSuggestionCard` is hidden when no suggestion is available. The AI Generator card remains as the primary CTA for new users. |

---

## Appendix A: File Paths (Absolute)

All paths are relative to the project source root at:
```
/Users/viniciuscarvalho/Documents/FitToday/FitToday/FitToday/
```

**New files:**
- `Domain/Models/AIChatMessage.swift`
- `Data/Services/AIChatService.swift`
- `Presentation/Features/Onboarding/WelcomeOnboardingView.swift`
- `Presentation/Features/Home/Components/WeekStreakRow.swift`
- `Presentation/Features/Home/Components/DailyWorkoutSuggestionCard.swift`
- `Presentation/Features/Home/Components/ExercisePreviewRow.swift`
- `Presentation/Features/Programs/Components/RecommendedProgramsSection.swift`
- `Presentation/Features/Workout/Components/WorkoutHeroHeader.swift`
- `Presentation/Features/FitPal/AIChatView.swift`
- `Presentation/Features/FitPal/AIChatViewModel.swift`
- `Presentation/Features/FitPal/Components/FitPalOrbView.swift`
- `Presentation/Features/FitPal/Components/FitPalChatBubble.swift`
- `Presentation/Features/Profile/Components/ProfileHeaderSection.swift`
- `Presentation/Features/Profile/Components/ProfileStatsRow.swift`

**Modified files:**
- `Presentation/Support/AppStorageKeys.swift`
- `Presentation/Router/AppRouter.swift`
- `Presentation/Root/TabRootView.swift`
- `FitTodayApp.swift`
- `Presentation/Features/Onboarding/OnboardingFlowView.swift`
- `Presentation/Features/Home/HomeView.swift`
- `Presentation/Features/Home/HomeViewModel.swift`
- `Presentation/Features/Programs/Views/ProgramsListView.swift`
- `Presentation/Features/Workout/Views/WorkoutTabView.swift`
- `Presentation/Features/Workout/WorkoutPlanView.swift`
- `Presentation/Features/Pro/ProfileProView.swift`
- `Presentation/DI/AppContainer.swift`

**Test files (new):**
- `FitTodayTests/Presentation/Features/AIChatViewModelTests.swift`
- `FitTodayTests/Data/Services/AIChatServiceTests.swift`
- `FitTodayTests/Domain/Models/AIChatMessageTests.swift`

## Appendix B: ProFeature Extension for FitPal

A new `ProFeature` case may be added for dedicated FitPal gating:

```swift
// In EntitlementPolicy.swift
enum ProFeature: String, CaseIterable {
    // ... existing cases ...
    case aiChat = "ai_chat"  // FitPal conversational AI
}
```

Alternatively, the existing `.aiWorkoutGeneration` case can be reused since FitPal is conceptually an extension of the AI capability. The decision should be made during implementation based on whether FitPal needs independent usage limits.
