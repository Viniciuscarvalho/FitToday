# PRD -- App Screen and Flow Reorganization

**Version:** 1.0
**Date:** 2026-02-25
**Author:** Product Team
**Status:** Draft

---

## 1. Executive Summary

### Problem

FitToday users report that the app flow is confusing and disorganized. Key pain points include:

- **No welcome onboarding**: New users land on the Home screen with no introduction to the app value proposition or features.
- **Home screen overload**: The current Home mixes too much information (greeting, programs, daily workout state, quick stats) without a clear visual hierarchy.
- **Programs tab confusion**: 26 programs are listed in a flat list, overwhelming users who cannot easily find programs relevant to their goals.
- **No AI assistant**: The center "Create" tab (plus icon) does not fulfill a clear purpose -- there is no conversational fitness assistant to help users with questions, motivation, or workout customization.
- **Profile lacks visible stats**: The Profile/Settings screen does not surface key accomplishments (streak, total minutes, completed workouts) that drive retention.

### Solution

Reorganize the app into 6 well-defined areas across 5 tabs (`Home`, `Programs`, `FitPal`, `Activity`, `Profile`), each with a focused purpose:

1. **Welcome Onboarding** -- First-launch intro flow (3-4 pages) introducing the app before profile setup.
2. **Home Redesign** -- Clean daily workout surface with week streak circles and a focused workout suggestion card.
3. **Programs Tab** -- Grouped by `ProgramCategory` with recommended programs at the top.
4. **Workout Detail** -- Hero image header with equipment section and exercise list.
5. **AI Assistant (FitPal)** -- OpenAI-powered conversational fitness assistant behind the subscription paywall.
6. **Profile/Settings** -- User photo/name header with visible stats row and existing settings sections.

### Business Value

- Reduce first-session abandonment through a guided onboarding experience.
- Increase daily active usage by surfacing the daily workout front and center.
- Drive subscription conversion by introducing a gated AI assistant (FitPal) as the center tab.
- Improve retention through visible progress stats on the Profile screen.

### Success Metrics

| Metric | Baseline | Target |
|--------|----------|--------|
| First-session completion rate | Unknown | +30% improvement |
| Daily active usage (DAU/MAU ratio) | Current | +15% improvement |
| Subscription conversion rate | Current | +20% improvement via FitPal |
| User confusion reports (qualitative) | Frequent | Significant reduction |

---

## 2. Project Overview

### Background

FitToday is an iOS fitness app built with SwiftUI (iOS 17+, Swift 6.0) following MVVM architecture with `@Observable`. The app currently uses 5 tabs defined in `AppRouter.swift`:

```swift
enum AppTab: Hashable, CaseIterable {
    case home      // "house.fill"
    case workout   // "dumbbell.fill" (Programs)
    case create    // "plus.circle.fill" (Create)
    case activity  // "chart.bar.fill"
    case profile   // "person.fill"
}
```

The existing codebase has substantial infrastructure that will be reused:

- **`ProgramRecommender`** (`Domain/UseCases/ProgramRecommender.swift`) -- Scores programs by user goal, level, and recent history.
- **`NewOpenAIClient`** (`Data/Services/OpenAI/NewOpenAIClient.swift`) -- Actor-based OpenAI client using `gpt-4o-mini` with retry logic.
- **`NewOpenAIWorkoutComposer`** (`Data/Services/OpenAI/NewOpenAIWorkoutComposer.swift`) -- Full workout generation pipeline.
- **`UserStats`** (`Domain/Entities/UserStats.swift`) -- Domain entity with streak, weekly/monthly counts, minutes, and calories.
- **`EntitlementPolicy`** + **`ProFeature`** (`Domain/Entities/EntitlementPolicy.swift`) -- Feature gating with `canAccess()` checks, lifetime purchase model.
- **`ChatBubble`** (`Presentation/Features/PersonalTrainer/Components/ChatBubble.swift`) -- Existing chat bubble UI component.
- **`OnboardingFlowView`** (`Presentation/Features/Onboarding/OnboardingFlowView.swift`) -- Progressive profile configuration with intro pages and setup steps.
- **`HomeViewModel`** (`Presentation/Features/Home/HomeViewModel.swift`) -- Daily workout logic with `generateWorkoutWithCheckIn()`, streak calculation, and stats.
- **`DesignTokens`** (`Presentation/DesignSystem/DesignTokens.swift`) -- `FitTodayColor`, `FitTodayFont`, `FitTodaySpacing`, `FitTodayRadius`, gradient definitions.
- **`UserAPIKeyManager`** (`Data/Services/OpenAI/UserAPIKeyManager.swift`) -- OpenAI API key management.
- **`HealthKitService`** (`Data/Services/HealthKit/HealthKitService.swift`) -- Apple Health integration (authorization, fetch, export).
- **`ProgramModels`** (`Domain/Entities/ProgramModels.swift`) -- `ProgramCategory` (6 categories), `ProgramGoalTag`, `ProgramLevel`, `ProgramEquipment`.

### Current State

- 5 tabs: Home, Workout (Programs), Create, Activity, Profile
- Home screen: greeting, goal badge, quick stats (workouts/week, calories, streak), top programs cards, daily workout CTA
- Programs: flat list of 26 programs with horizontal filter pills by `ProgramFilter` (all/strength/conditioning/aerobic/endurance/wellness)
- Create tab: plus icon with no clear purpose
- Activity: workout history
- Profile: basic settings
- Onboarding: exists (`OnboardingFlowView`) but only for profile setup, no welcome intro with app value proposition

### Desired State

- 5 tabs: **Home**, **Programs**, **FitPal**, **Activity**, **Profile**
- Welcome onboarding for first-launch users introducing the app
- Home focused on daily workout with week streak visualization
- Programs grouped by category with recommendations at the top
- FitPal (center tab) as an AI conversational assistant (Pro feature)
- Profile with visible user stats header

---

## 3. Goals and Objectives

### Primary Goals

1. **G-001**: Simplify the first-time user experience with a guided welcome onboarding.
2. **G-002**: Redesign the Home screen to prioritize the daily workout and weekly progress.
3. **G-003**: Reorganize the Programs tab for better discoverability of 26 programs.
4. **G-004**: Introduce FitPal as an AI assistant to replace the unused "Create" tab.
5. **G-005**: Surface user accomplishments on the Profile screen to drive retention.

### Secondary Goals

6. **G-006**: Improve Workout Detail with a hero image header and equipment section.
7. **G-007**: Maintain all existing functionality (workout execution, history, settings) without regression.

---

## 4. User Personas

### Primary: Ana -- Beginner Fitness Enthusiast

- **Age:** 25-35
- **Profile:** Wants to start working out consistently but gets overwhelmed by too many options.
- **Goals:** Follow structured workout programs, receive daily guidance, build a streak.
- **Pain Points:** Does not know which program to choose among 26 options. Gets confused by the current Home screen layout. Wants a simple "just tell me what to do today" experience.
- **Technical Comfort:** Moderate. Uses iPhone daily, familiar with app subscriptions.
- **Key Need:** Guided onboarding, clear daily workout suggestion, organized program categories.

### Secondary: Rafael -- Experienced Gym-Goer

- **Age:** 25-45
- **Profile:** Has been training for 2+ years, wants AI-powered custom workouts and detailed tracking.
- **Goals:** Get personalized AI workouts, track progress with data, integrate with Apple Health.
- **Pain Points:** Wants to ask specific fitness questions to an AI assistant. Values seeing his stats (streak, total minutes, completed workouts). Willing to pay for premium features.
- **Technical Comfort:** High. Uses multiple fitness apps, understands API keys and integrations.
- **Key Need:** AI assistant (FitPal), visible stats on Profile, advanced workout customization.

---

## 5. Functional Requirements

### FR-001: Welcome Onboarding

**Priority:** High
**Description:** First-launch 3-4 page intro flow introducing the app before profile configuration.

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-001.1 | Display 3-4 onboarding pages on first launch | Pages show sequentially with swipe navigation and page dots |
| FR-001.2 | Each page has a background image or SF Symbol illustration, a title, and explanatory text | All pages render correctly using `DesignTokens` (dark theme, `FitTodayColor`, `FitTodayFont`) |
| FR-001.3 | Pages cover: (1) App intro/value prop, (2) Daily workout concept, (3) AI assistant preview, (4) Get started CTA | Content matches specified topics |
| FR-001.4 | "Get Started" button on last page transitions to `OnboardingFlowView` setup stage | Tapping transitions to existing profile setup flow |
| FR-001.5 | No login required for basic use | App must be fully functional without authentication |
| FR-001.6 | First-launch flag persists via `UserDefaults` | Onboarding does not re-appear after completion |
| FR-001.7 | Skip button available on all pages except the last | Skip jumps directly to profile setup |

**Existing Infrastructure:**
- `OnboardingFlowView` already has `.intro` and `.setup` stages. The welcome pages extend the `.intro` stage with richer content.
- `OnboardingPage.pages` already provides intro page data -- this needs expansion with background images and more descriptive text.

---

### FR-002: Home Screen Redesign

**Priority:** High
**Description:** Clean daily workout surface with week streak circles at the top and a focused workout suggestion card.

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-002.1 | Week streak circles at top showing 7 day indicators (S-M-T-W-T-F-S) | Circles filled for completed workout days, empty for pending, highlighted for today |
| FR-002.2 | Daily workout suggestion card with image, title, estimated duration, and level badge | Card renders using data from `HomeViewModel.dailyWorkoutState` |
| FR-002.3 | Exercise list below the suggestion card showing exercise images, names, sets, and reps | List populates from the generated `WorkoutPlan` exercises |
| FR-002.4 | Cardio exercises display warmup description and time instead of sets/reps | Conditional rendering based on exercise type |
| FR-002.5 | Tapping the suggestion card navigates to workout execution | Navigation via `AppRouter.push(.workoutExecution)` |
| FR-002.6 | Pull-to-refresh reloads daily workout data | Calls `HomeViewModel.refresh()` |
| FR-002.7 | Greeting text with user name and current date preserved | Uses existing `HomeViewModel.greeting` and `currentDateFormatted` |
| FR-002.8 | Streak circles source data from `historyEntries` in `HomeViewModel` | Calculated from workout history dates for the current week |

**Existing Infrastructure:**
- `HomeViewModel` already has `streakDays`, `workoutsThisWeek`, `dailyWorkoutState`, `generateWorkoutWithCheckIn()`.
- `UserStatsSection` component exists at `Presentation/Features/Home/Components/UserStatsSection.swift`.

---

### FR-003: Programs Tab Reorganization

**Priority:** High
**Description:** Better grouping of 26 programs by `ProgramCategory` with recommended programs section at the top.

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-003.1 | "Recommended for You" section at the top displaying 3-4 programs | Uses `ProgramRecommender.recommend()` with user profile and history |
| FR-003.2 | Programs grouped by `ProgramCategory` below recommendations | Groups: Push Pull Legs, Full Body, Upper Lower, Specialized, Fat Loss, Home Workout |
| FR-003.3 | Category groups are collapsible (expand/collapse) | Tapping category header toggles visibility of its programs |
| FR-003.4 | Category headers show count of programs in group | Header displays category name + program count |
| FR-003.5 | Existing filter pills remain functional as secondary filter | `ProgramFilter` horizontal scroll still works for cross-category filtering |
| FR-003.6 | Empty state when no programs match active filter | Shows `EmptyStateView` with appropriate message |
| FR-003.7 | Programs sorted by `ProgramCategory.sortOrder` within groups | Order: PPL (0), Full Body (1), Upper Lower (2), Specialized (3), Fat Loss (4), Home Workout (5) |

**Existing Infrastructure:**
- `ProgramCategory` already defined in `ProgramModels.swift` with 6 categories and `sortOrder`.
- `Program.category` computed property already maps programs to categories.
- `ProgramRecommender` already implements `recommend(programs:profile:history:limit:)`.
- `ProgramsView` + `ProgramsViewModel` exist with filter pills and card layout.

---

### FR-004: Workout Detail Enhancement

**Priority:** Medium
**Description:** Hero image header with equipment section and exercise list preserving existing reorder/delete/add functionality.

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-004.1 | Hero image header at approximately 250pt height | Uses `Program.heroImageName` or workout image, with gradient overlay for text readability |
| FR-004.2 | Equipment needed section listing required equipment with icons | Displays `ProgramEquipment.iconName` and `displayName` for relevant equipment |
| FR-004.3 | Exercise list with images, names, sets, reps | Each row shows exercise thumbnail, name, and prescription |
| FR-004.4 | Reorder, delete, and add exercise functionality preserved | Existing `EditMode` and list manipulation logic remains functional |
| FR-004.5 | Scrollable content below the hero image | Content scrolls under the hero with parallax or sticky header behavior |

**Existing Infrastructure:**
- `ProgramWorkoutDetailView` and `WorkoutPlanHeader` already exist.
- `ExercisePrescription` model provides sets/reps/rest data.
- `ProgramEquipment` enum has `iconName` and `displayName`.

---

### FR-005: AI Assistant (FitPal)

**Priority:** High
**Description:** OpenAI-powered conversational fitness assistant replacing the center "Create" tab. Behind subscription paywall.

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-005.1 | FitPal tab replaces the "Create" tab as center (3rd) tab | Tab bar shows `FitPal` with appropriate icon instead of `plus.circle.fill` |
| FR-005.2 | Initial state shows FitPalOrb animation with quick action chips | Orb visual element with pulsing animation and 3-4 quick action buttons below |
| FR-005.3 | Quick action chips: "Suggest a workout", "Explain an exercise", "Nutrition tips", "Motivation" | Tapping a chip sends predefined prompt to the AI |
| FR-005.4 | Conversational chat UI with message bubbles | Reuse `ChatBubble.swift` component for user and AI messages |
| FR-005.5 | Messages sent to OpenAI via `NewOpenAIClient` with fitness-focused system prompt | Uses `gpt-4o-mini` model with context about user profile and fitness goals |
| FR-005.6 | Feature gated behind Pro subscription using `EntitlementPolicy` | `ProFeature.personalTrainer` check via `EntitlementPolicy.canAccess()` |
| FR-005.7 | Non-Pro users see paywall prompt when tapping FitPal tab | Shows paywall via existing `OptimizedPaywallView` |
| FR-005.8 | Chat history persisted locally per session (not across app restarts) | Messages stored in `@State` or ViewModel during session |
| FR-005.9 | Loading indicator while waiting for AI response | Shows typing indicator bubble while request is in flight |
| FR-005.10 | Error handling for API failures with retry option | Displays error message with "Retry" button on failure |
| FR-005.11 | API key sourced from `UserAPIKeyManager` | Uses `NewOpenAIClient.fromUserKey()` factory method |

**Existing Infrastructure:**
- `NewOpenAIClient` actor with `generateWorkout(prompt:)` -- can be extended for general chat.
- `ChatBubble.swift` already renders user/AI message bubbles with timestamps.
- `EntitlementPolicy.canAccess(.personalTrainer, entitlement:)` already gates this feature.
- `ProFeature.personalTrainer` already defined with `displayName`.
- `UserAPIKeyManager.shared.getAPIKey(for: .openAI)` already manages API keys.

---

### FR-006: Profile/Settings Redesign

**Priority:** Medium
**Description:** User photo/name header with stats row and existing settings sections.

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR-006.1 | User photo and display name header at top of Profile | Shows user photo from `HomeViewModel.userPhotoURL` and name from `userName` |
| FR-006.2 | Stats row showing streak, total minutes, and completed workouts | Three stat items in a horizontal row sourced from `UserStats` entity |
| FR-006.3 | Streak sourced from `UserStats.currentStreak` | Displays current streak with fire/flame icon |
| FR-006.4 | Total minutes sourced from `UserStats.weekTotalMinutes` or `monthTotalMinutes` | Displays total with clock icon |
| FR-006.5 | Completed workouts sourced from Apple Health via `HealthKitService` when available | Falls back to `UserStats.monthWorkoutsCount` if HealthKit not connected |
| FR-006.6 | Existing sections preserved: Apple Health toggle, settings, premium | All current settings sections remain functional |
| FR-006.7 | Edit profile button navigates to `OnboardingFlowView(isEditing: true)` | Uses existing edit profile route |

**Existing Infrastructure:**
- `UserStats` entity has `currentStreak`, `longestStreak`, `weekTotalMinutes`, `monthWorkoutsCount`.
- `UserStatsCalculator` + `UserStatsCalculating` protocol compute stats from history.
- `HealthKitService` provides workout data from Apple Health.
- `HomeViewModel` already loads `userName` and `userPhotoURL` from Firebase/UserDefaults.

---

## 6. Non-Functional Requirements

### NFR-001: Performance

| ID | Requirement |
|----|-------------|
| NFR-001.1 | Home screen must render within 500ms of tab selection |
| NFR-001.2 | Program list must render within 1s including category grouping |
| NFR-001.3 | FitPal AI responses must display within 10s (p95) |
| NFR-001.4 | Week streak circles must calculate without blocking the main thread |
| NFR-001.5 | Stats on Profile must load asynchronously and not block view appearance |

### NFR-002: Usability

| ID | Requirement |
|----|-------------|
| NFR-002.1 | All new screens must support VoiceOver accessibility |
| NFR-002.2 | All text must use localized strings (pt-BR primary, en secondary) |
| NFR-002.3 | Dark theme only -- all new UI must use `DesignTokens` (`FitTodayColor`, `FitTodayFont`, `FitTodaySpacing`) |
| NFR-002.4 | Minimum touch target size of 44x44pt for all interactive elements |
| NFR-002.5 | Welcome onboarding must be completable in under 30 seconds |

### NFR-003: Maintainability

| ID | Requirement |
|----|-------------|
| NFR-003.1 | All new ViewModels must have unit tests with minimum 70% coverage |
| NFR-003.2 | Follow existing MVVM + `@Observable` architecture |
| NFR-003.3 | Use Swinject for dependency injection consistent with existing patterns |
| NFR-003.4 | Swift 6 strict concurrency compliance -- no concurrency warnings |
| NFR-003.5 | New views must not exceed 100 lines -- extract sub-views as needed |

---

## 7. Epics and User Stories

### Epic 1: Welcome Onboarding (FR-001)

| Story ID | User Story | Priority | Estimate |
|----------|-----------|----------|----------|
| US-001 | As a new user, I want to see a welcome intro when I first open the app, so I understand what FitToday offers | High | S |
| US-002 | As a new user, I want to swipe through 3-4 intro pages with visuals and descriptions, so I understand the app flow | High | S |
| US-003 | As a new user, I want to skip the intro and go straight to profile setup, so I can start quickly if I prefer | Medium | XS |
| US-004 | As a returning user, I want to never see the welcome intro again after completing it | High | XS |

### Epic 2: Home Redesign (FR-002)

| Story ID | User Story | Priority | Estimate |
|----------|-----------|----------|----------|
| US-005 | As a user, I want to see my weekly workout streak as 7 circles (S-M-T-W-T-F-S) at the top of Home, so I can visualize my consistency | High | M |
| US-006 | As a user, I want to see a daily workout suggestion card with an image, title, duration, and level, so I know what to train today | High | M |
| US-007 | As a user, I want to see the exercise list for today's workout directly on Home, so I can preview it before starting | High | M |
| US-008 | As a user doing cardio, I want to see warmup description and time instead of sets/reps, so the information matches my workout type | Medium | S |

### Epic 3: Programs Tab Reorganization (FR-003)

| Story ID | User Story | Priority | Estimate |
|----------|-----------|----------|----------|
| US-009 | As a user, I want to see recommended programs at the top of the Programs tab, so I quickly find programs suited to my goals | High | M |
| US-010 | As a user, I want programs grouped by category (PPL, Full Body, etc.), so I can browse them in an organized way | High | M |
| US-011 | As a user, I want to collapse/expand category groups, so I can focus on categories I care about | Medium | S |
| US-012 | As a user, I want to see how many programs are in each category, so I know the breadth of options | Low | XS |

### Epic 4: Workout Detail Enhancement (FR-004)

| Story ID | User Story | Priority | Estimate |
|----------|-----------|----------|----------|
| US-013 | As a user, I want to see a large hero image at the top of the workout detail, so the experience feels polished and immersive | Medium | S |
| US-014 | As a user, I want to see what equipment I need for a workout, so I can prepare before starting | Medium | S |
| US-015 | As a user, I want to reorder, add, and remove exercises from a workout, so I can customize it to my preferences | High | Already exists |

### Epic 5: AI Assistant -- FitPal (FR-005)

| Story ID | User Story | Priority | Estimate |
|----------|-----------|----------|----------|
| US-016 | As a Pro user, I want an AI fitness assistant (FitPal) as a dedicated tab, so I can ask fitness questions anytime | High | L |
| US-017 | As a user, I want to see an animated orb and quick action chips when I open FitPal, so I know how to start interacting | High | M |
| US-018 | As a Pro user, I want to chat with FitPal using text messages, so I can get personalized fitness advice | High | L |
| US-019 | As a free user, I want to see a paywall when I tap FitPal, so I understand this is a premium feature | High | S |
| US-020 | As a Pro user, I want FitPal to know my profile (goals, level, conditions), so responses are personalized | Medium | M |
| US-021 | As a user, I want to see quick action chips ("Suggest a workout", "Explain an exercise"), so I can start conversations easily | Medium | S |

### Epic 6: Profile/Settings Redesign (FR-006)

| Story ID | User Story | Priority | Estimate |
|----------|-----------|----------|----------|
| US-022 | As a user, I want to see my photo and name at the top of Profile, so it feels personalized | Medium | S |
| US-023 | As a user, I want to see my streak, total minutes, and completed workouts on Profile, so I can track my progress at a glance | High | M |
| US-024 | As a user, I want all existing settings (Apple Health, premium, etc.) to remain accessible on Profile | High | Already exists |

---

## 8. User Experience Requirements

### UF-001: First Launch Flow

```
App Launch (first time)
  |
  v
Welcome Onboarding (3-4 pages)
  |-- Page 1: App value proposition (background image + title + description)
  |-- Page 2: Daily workout concept
  |-- Page 3: AI assistant preview (FitPal)
  |-- Page 4: Get Started CTA
  |     |
  |     v
  | [Skip] available on pages 1-3
  |
  v
Profile Setup (OnboardingFlowView.setup)
  |-- Step 1: Select Goal
  |-- Step 2: Select Structure
  |-- (Optional) More customization steps
  |
  v
Home Screen (daily workout ready)
```

### UF-002: Daily Home Flow

```
Home Tab
  |
  +-- Greeting ("Good morning, [Name]")
  +-- Date ("Tuesday, 25 de Fevereiro")
  +-- Week Streak Circles [S] [M] [T] [W] [T] [F] [S]
  |     (filled = completed, ring = today, empty = pending)
  |
  +-- Daily Workout Card
  |     |-- Hero Image
  |     |-- Workout Title
  |     |-- Duration badge | Level badge
  |     |-- [Start Workout] button
  |
  +-- Exercise Preview List
        |-- Exercise 1: Image | Name | 3x12
        |-- Exercise 2: Image | Name | 4x10
        |-- Cardio: Image | Name | "10 min warmup"
```

### UF-003: Programs Discovery Flow

```
Programs Tab
  |
  +-- Header ("Programs" + subtitle)
  +-- Filter Pills [All] [Strength] [Conditioning] [Aerobic] [Endurance] [Wellness]
  |
  +-- "Recommended for You" Section
  |     |-- Program Card 1
  |     |-- Program Card 2
  |     |-- Program Card 3
  |
  +-- Category Groups (collapsible)
        |-- [v] Push Pull Legs (4 programs)
        |     |-- Program Card...
        |-- [v] Full Body (5 programs)
        |     |-- Program Card...
        |-- [>] Upper Lower (collapsed)
        |-- [>] Specialized (collapsed)
        |-- [v] Fat Loss (3 programs)
        |-- [v] Home Workout (2 programs)
```

### UF-004: FitPal Flow

```
FitPal Tab (center tab)
  |
  +-- [Free User] --> Paywall Screen
  |
  +-- [Pro User]
        |
        +-- Initial State:
        |     |-- FitPalOrb (animated orb)
        |     |-- "Hi [Name], how can I help?"
        |     |-- Quick Action Chips:
        |     |     [Suggest a workout]
        |     |     [Explain an exercise]
        |     |     [Nutrition tips]
        |     |     [Motivation]
        |
        +-- Chat State:
              |-- Message List (ScrollView)
              |     |-- [AI] "Hello! I'm FitPal..."
              |     |-- [User] "What should I train today?"
              |     |-- [AI] "Based on your profile..."
              |
              +-- Input Bar
                    |-- Text Field
                    |-- Send Button
```

### UF-005: Profile Flow

```
Profile Tab
  |
  +-- User Header
  |     |-- Photo (circle)
  |     |-- Display Name
  |     |-- [Edit Profile] button
  |
  +-- Stats Row
  |     |-- [flame] Streak: 7 days
  |     |-- [clock] Minutes: 245 min
  |     |-- [checkmark] Workouts: 12
  |
  +-- Settings Sections (existing)
        |-- Apple Health
        |-- Settings
        |-- Premium
        |-- About
```

---

## 9. Success Metrics (KPIs)

| KPI | Measurement Method | Target |
|-----|-------------------|--------|
| Onboarding completion rate | % of first-launch users who complete welcome + profile setup | > 70% |
| Home daily engagement | % of users who view Home screen daily | > 60% DAU |
| Programs discovery | Avg programs viewed per session | Increase by 40% |
| FitPal adoption (Pro users) | % of Pro users who use FitPal at least 1x/week | > 50% |
| FitPal conversion | % of free users who see FitPal paywall and subscribe | > 5% |
| Profile stats views | % of users who view Profile stats per week | > 30% |
| User satisfaction | Qualitative feedback on app flow clarity | "Confusing" reports reduced by 80% |

---

## 10. Assumptions and Dependencies

### Assumptions

1. Users prefer a daily-focused Home screen over a multi-purpose dashboard.
2. The 26 existing programs are sufficient; no new programs are needed for this iteration.
3. Users will find value in an AI fitness assistant behind a paywall.
4. The existing `NewOpenAIClient` can be adapted for general conversational use (not just workout generation).
5. Existing `ChatBubble` component is flexible enough for FitPal chat UI.
6. Users have already set up their profile via `OnboardingFlowView` before accessing FitPal.

### Dependencies

| Dependency | Description | Risk |
|------------|-------------|------|
| OpenAI API | FitPal requires a valid OpenAI API key via `UserAPIKeyManager` | Medium -- API outages or key issues can degrade FitPal |
| `ProgramRecommender` | Programs "Recommended for You" depends on this use case | Low -- already implemented and tested |
| `EntitlementPolicy` | FitPal gating requires accurate entitlement state | Low -- already implemented with Pro/Free checks |
| `UserStats` / `UserStatsCalculator` | Profile stats row depends on accurate stats computation | Low -- already implemented and tested |
| `HealthKitService` | Profile completed workouts can optionally pull from HealthKit | Low -- graceful fallback exists |
| `DesignTokens` | All UI must use the existing design system | Low -- well-established and documented |
| Firebase Auth | User photo and name depend on Firebase auth state | Low -- fallback to UserDefaults cache exists |

---

## 11. Constraints

| Constraint | Description |
|------------|-------------|
| Platform | iOS 17.0+ only (no macOS/watchOS target for this feature) |
| Theme | Dark theme only -- all UI uses `FitTodayColor.background` (#0D0D14) and dark surface colors |
| Design System | Must use existing `DesignTokens` -- `FitTodayColor`, `FitTodayFont` (Orbitron/Rajdhani), `FitTodaySpacing`, `FitTodayRadius` |
| Architecture | MVVM with `@Observable`, `@MainActor`, Swinject DI -- no architectural changes |
| Localization | pt-BR (primary) + en (secondary) -- all user-facing strings must be localized |
| Concurrency | Swift 6 strict concurrency -- no warnings allowed |
| Tab Count | Exactly 5 tabs (iOS HIG recommendation for bottom tab bars) |

---

## 12. Out of Scope

The following are explicitly excluded from this initiative:

| Item | Reason |
|------|--------|
| Login/auth system changes | Authentication flow is stable; no changes needed |
| Challenge feature changes | Social challenges are a separate feature area |
| New exercise database | Existing ExerciseDB data is sufficient |
| New workout generation algorithm | `NewOpenAIWorkoutComposer` and hybrid pipeline remain unchanged |
| Watch app | No Apple Watch companion for this release |
| Chat history persistence across sessions | FitPal chat is session-only in v1 |
| FitPal voice input | Text-only chat in v1 |
| Onboarding A/B testing | Single variant for initial release |
| New program creation | Programs are bundled; no user-created programs in this scope |
| Exercise library redesign | `LibraryExplore` route exists but is not part of this reorganization |

---

## 13. Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **OpenAI API rate limits or outages** degrade FitPal experience | Medium | High | Implement graceful error states with retry button; show cached quick tips when API is unavailable |
| **Home redesign regression** breaks daily workout generation flow | Medium | High | Preserve all `HomeViewModel` logic; add unit tests for new streak circle calculations; run full regression test suite |
| **Programs grouping performance** with 26 programs + recommendations | Low | Medium | `ProgramCategory` grouping is a simple O(n) filter; recommend caching grouped results in ViewModel |
| **Onboarding skip rate too high** undermines adoption | Medium | Medium | Make skip button less prominent; track skip rate via analytics to iterate on content |
| **FitPal system prompt quality** leads to unhelpful AI responses | Medium | High | Iterate on system prompt with user context (profile, goals, conditions); test with diverse user profiles |
| **Tab bar change confuses existing users** | Medium | Medium | Consider a "What's New" modal on app update highlighting the new tab structure |
| **Localization delays** for welcome onboarding content | Low | Medium | Write pt-BR first (primary audience); en can follow in a fast-follow release |
| **Design token inconsistency** in new views | Low | Low | Enforce design review using `DesignTokens` only; no raw color/font values in new code |

---

## Appendix A: Tab Bar Mapping (Current vs. New)

| Position | Current | New |
|----------|---------|-----|
| 1 (left) | Home (`house.fill`) | Home (`house.fill`) |
| 2 | Workout/Programs (`dumbbell.fill`) | Programs (`dumbbell.fill`) |
| 3 (center) | Create (`plus.circle.fill`) | FitPal (`sparkles` or custom icon) |
| 4 | Activity (`chart.bar.fill`) | Activity (`chart.bar.fill`) |
| 5 (right) | Profile (`person.fill`) | Profile (`person.fill`) |

**`AppTab` enum change required in `AppRouter.swift`:**
```swift
enum AppTab: Hashable, CaseIterable {
    case home      // unchanged
    case programs  // renamed from .workout
    case fitpal    // replaces .create
    case activity  // unchanged
    case profile   // unchanged
}
```

## Appendix B: Existing Code References

| Component | File Path | Purpose |
|-----------|-----------|---------|
| `AppRouter` / `AppTab` | `Presentation/Router/AppRouter.swift` | Tab navigation and routing |
| `HomeViewModel` | `Presentation/Features/Home/HomeViewModel.swift` | Home screen state, daily workout, streak |
| `OnboardingFlowView` | `Presentation/Features/Onboarding/OnboardingFlowView.swift` | Profile setup flow with intro pages |
| `ProgramsView` | `Presentation/Features/Programs/ProgramsView.swift` | Programs list with filter pills |
| `ProgramModels` | `Domain/Entities/ProgramModels.swift` | `Program`, `ProgramCategory`, `ProgramGoalTag`, `ProgramLevel` |
| `ProgramRecommender` | `Domain/UseCases/ProgramRecommender.swift` | Program/workout recommendation engine |
| `EntitlementPolicy` | `Domain/Entities/EntitlementPolicy.swift` | Pro feature gating |
| `UserStats` | `Domain/Entities/UserStats.swift` | Aggregated user statistics |
| `ChatBubble` | `Presentation/Features/PersonalTrainer/Components/ChatBubble.swift` | Chat message bubble component |
| `NewOpenAIClient` | `Data/Services/OpenAI/NewOpenAIClient.swift` | OpenAI API actor with retry logic |
| `DesignTokens` | `Presentation/DesignSystem/DesignTokens.swift` | Colors, fonts, spacing, gradients |
| `UserAPIKeyManager` | `Data/Services/OpenAI/UserAPIKeyManager.swift` | OpenAI API key management |
| `HealthKitService` | `Data/Services/HealthKit/HealthKitService.swift` | Apple Health integration |
