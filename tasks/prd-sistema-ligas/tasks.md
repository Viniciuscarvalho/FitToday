# Tasks: Sistema de Ligas (PRO-91)

> League System for FitToday. Weekly XP-based ranking with tier promotion/demotion.
> Cloud Function handles weekly reset — iOS reads results only.
> Gated by `leagues_enabled` Remote Config flag.

---

## Task 1: Domain Entities and Protocols
**Status:** pending
**Estimated effort:** small
**Dependencies:** none

### Description
Create the core domain layer for the league system: tier enum, entity structs, and repository protocol. These are pure value types with no external dependencies.

### Files to create/modify
- `FitToday/FitToday/Domain/Entities/LeagueTier.swift`
- `FitToday/FitToday/Domain/Entities/League.swift`
- `FitToday/FitToday/Domain/Protocols/LeagueRepository.swift`

### Acceptance Criteria
- [ ] `LeagueTier` enum with cases: `bronze`, `silver`, `gold`, `diamond`, `legend`
- [ ] `LeagueTier` has computed properties: `displayName`, `icon` (SF Symbol), `color` (hex or SwiftUI Color name), `sortOrder`, `localizationKey`
- [ ] `LeagueTier` conforms to `String, Sendable, Codable, CaseIterable, Comparable`
- [ ] `League` struct with: `id`, `tier`, `seasonWeek` (Int), `members` ([LeagueMember]), `startDate`, `endDate`
- [ ] `LeagueMember` struct with: `userId`, `displayName`, `avatarURL`, `weeklyXP`, `rank`, `isCurrentUser`
- [ ] `LeagueResult` struct with: `seasonWeek`, `tier`, `finalRank`, `promoted` (Bool), `demoted` (Bool), `xpEarned`
- [ ] `LeagueRepository` protocol with methods: `getCurrentLeague() async throws -> League?`, `observeLeague(leagueId:) -> AsyncThrowingStream<League, Error>`, `getHistory() async throws -> [LeagueResult]`
- [ ] All types conform to `Sendable`
- [ ] Max 30 members per league (constant defined in League)

---

## Task 2: Feature Flag and Entitlement
**Status:** pending
**Estimated effort:** small
**Dependencies:** none

### Description
Add the `leaguesEnabled` feature flag to `FeatureFlagKey` and add league-related cases to `ProFeature` in `EntitlementPolicy`. Bronze is free; Silver/Gold/Diamond require Pro; Legend requires Elite.

### Files to create/modify
- `FitToday/FitToday/Domain/Entities/FeatureFlag.swift`
- `FitToday/FitToday/Domain/Entities/EntitlementPolicy.swift`
- `remoteconfig.template.json`

### Acceptance Criteria
- [ ] `FeatureFlagKey.leaguesEnabled` added with raw value `"leagues_enabled"`
- [ ] Default value is `false` (unreleased feature)
- [ ] `displayName` returns `"Leagues"`
- [ ] `remoteconfig.template.json` updated with `leagues_enabled: false`
- [ ] `ProFeature.leagueSilver`, `.leagueGold`, `.leagueDiamond` cases added (Pro-gated)
- [ ] `ProFeature.leagueLegend` case added (Elite-gated)
- [ ] `EntitlementPolicy.canAccess` updated: Bronze allowed for Free, Silver/Gold/Diamond require Pro, Legend requires Elite
- [ ] `isProOnly` and `isEliteOnly` updated for league cases

---

## Task 3: Data Layer — DTOs and Mappers
**Status:** pending
**Estimated effort:** small
**Dependencies:** Task 1

### Description
Create Firestore DTOs (`FBLeague`, `FBLeagueMember`) and a `LeagueMapper` to convert between DTOs and domain entities. Follow existing patterns (e.g., `FBUserXP`, `UserProfileMapper`).

### Files to create/modify
- `FitToday/FitToday/Data/DTOs/FBLeague.swift`
- `FitToday/FitToday/Data/Mappers/LeagueMapper.swift`

### Acceptance Criteria
- [ ] `FBLeague` struct with Firestore-compatible fields: `id`, `tier` (String), `seasonWeek`, `members` ([FBLeagueMember]), `startDate` (Timestamp), `endDate` (Timestamp)
- [ ] `FBLeagueMember` struct with: `userId`, `displayName`, `avatarURL`, `weeklyXP`
- [ ] Both DTOs conform to `Codable, Sendable`
- [ ] `LeagueMapper` with static methods: `toDomain(from: FBLeague, currentUserId:) -> League`, `toLeagueResult(from: FBLeague, currentUserId:) -> LeagueResult?`
- [ ] Mapper correctly computes `rank` by sorting members by `weeklyXP` descending
- [ ] Mapper correctly sets `isCurrentUser` flag on the matching member

---

## Task 4: Data Layer — Firebase Service
**Status:** pending
**Estimated effort:** medium
**Dependencies:** Task 3

### Description
Create `FirebaseLeagueService` actor that handles Firestore queries and real-time snapshot listeners for league data. Follow existing pattern from `FirebaseLeaderboardService`.

### Files to create/modify
- `FitToday/FitToday/Data/Services/Firebase/FirebaseLeagueService.swift`

### Acceptance Criteria
- [ ] `FirebaseLeagueService` is an `actor` conforming to `Sendable`
- [ ] Method `fetchCurrentLeague(userId:) async throws -> FBLeague?` — queries `leagues` collection where user is a member and season is current
- [ ] Method `observeLeague(leagueId:) -> AsyncThrowingStream<FBLeague, Error>` — real-time Firestore snapshot listener wrapped in AsyncThrowingStream
- [ ] Method `fetchLeagueHistory(userId:) async throws -> [FBLeague]` — queries past seasons ordered by `seasonWeek` descending
- [ ] Firestore collection path: `leagues/{leagueId}`
- [ ] Proper error handling with typed errors
- [ ] Listener cleanup on stream termination

---

## Task 5: Data Layer — Repository Implementation
**Status:** pending
**Estimated effort:** small
**Dependencies:** Task 1, Task 4

### Description
Create `FirebaseLeagueRepository` implementing the `LeagueRepository` protocol. Delegates to `FirebaseLeagueService` and uses `LeagueMapper` for conversion.

### Files to create/modify
- `FitToday/FitToday/Data/Repositories/FirebaseLeagueRepository.swift`

### Acceptance Criteria
- [ ] `FirebaseLeagueRepository` conforms to `LeagueRepository` and `Sendable`
- [ ] Injects `FirebaseLeagueService` and `FirebaseAuthService` (for current userId)
- [ ] `getCurrentLeague()` fetches via service, maps with `LeagueMapper`
- [ ] `observeLeague(leagueId:)` returns mapped AsyncThrowingStream
- [ ] `getHistory()` fetches and maps to `[LeagueResult]`
- [ ] All methods use `async throws`

---

## Task 6: Domain Layer — Use Cases
**Status:** pending
**Estimated effort:** small
**Dependencies:** Task 1, Task 2

### Description
Create use cases for league operations. Each use case is a single-responsibility struct injecting the repository protocol.

### Files to create/modify
- `FitToday/FitToday/Domain/UseCases/LeagueUseCases.swift`

### Acceptance Criteria
- [ ] `GetCurrentLeagueUseCase` — calls `leagueRepository.getCurrentLeague()`, returns `League?`
- [ ] `ObserveLeagueUseCase` — calls `leagueRepository.observeLeague(leagueId:)`, returns `AsyncThrowingStream<League, Error>`
- [ ] `GetLeagueHistoryUseCase` — calls `leagueRepository.getHistory()`, returns `[LeagueResult]`
- [ ] All use cases are `struct`, conform to `Sendable`
- [ ] All use cases inject `LeagueRepository` (protocol, not concrete)
- [ ] Feature flag check: use cases should verify `leaguesEnabled` via `FeatureFlagUseCase` and return nil/empty if disabled

---

## Task 7: DI Container Registration
**Status:** pending
**Estimated effort:** small
**Dependencies:** Task 4, Task 5, Task 6

### Description
Register all league-related services, repositories, and use cases in `AppContainer`. Follow existing registration patterns.

### Files to create/modify
- `FitToday/FitToday/Presentation/DI/AppContainer.swift`

### Acceptance Criteria
- [ ] `FirebaseLeagueService` registered with `.container` scope
- [ ] `LeagueRepository` registered (resolving to `FirebaseLeagueRepository`) with `.container` scope
- [ ] `GetCurrentLeagueUseCase` registered, resolving `LeagueRepository`
- [ ] `ObserveLeagueUseCase` registered, resolving `LeagueRepository`
- [ ] `GetLeagueHistoryUseCase` registered, resolving `LeagueRepository`
- [ ] `LeagueViewModel` registered, resolving all required use cases
- [ ] Registrations grouped under a `// MARK: - Leagues` comment

---

## Task 8: Presentation — LeagueViewModel
**Status:** pending
**Estimated effort:** medium
**Dependencies:** Task 6, Task 7

### Description
Create `@Observable` LeagueViewModel that manages league state, real-time observation, countdown timer to season end, and animation triggers for promotion/demotion.

### Files to create/modify
- `FitToday/FitToday/Presentation/Features/League/LeagueViewModel.swift`

### Acceptance Criteria
- [ ] `@Observable` class, `@MainActor`
- [ ] Published state: `league: League?`, `history: [LeagueResult]`, `isLoading: Bool`, `error: String?`
- [ ] `countdownText: String` computed from `league.endDate` (e.g., "3d 12h")
- [ ] `showPromotionAnimation: Bool`, `showDemotionAnimation: Bool` triggers
- [ ] `loadLeague()` async — fetches current league, starts observation
- [ ] `loadHistory()` async — fetches league history
- [ ] Real-time observation via `ObserveLeagueUseCase` updating `league`
- [ ] `currentUserRank: Int?` computed from league members
- [ ] `promotionZone: Bool` / `demotionZone: Bool` computed (top 3 / bottom 3)
- [ ] Timer for countdown updates (every minute)
- [ ] Cancels observation task on deinit

---

## Task 9: Presentation — League UI Components
**Status:** pending
**Estimated effort:** medium
**Dependencies:** Task 1, Task 8

### Description
Create reusable SwiftUI components for the league feature: tier badge, ranking row, and home card widget.

### Files to create/modify
- `FitToday/FitToday/Presentation/Features/League/Components/LeagueTierBadge.swift`
- `FitToday/FitToday/Presentation/Features/League/Components/LeagueRankingRow.swift`
- `FitToday/FitToday/Presentation/Features/League/Components/LeagueHomeCard.swift`

### Acceptance Criteria
- [ ] `LeagueTierBadge` — displays tier icon + name with tier-specific color, supports `.small` and `.large` sizes
- [ ] `LeagueRankingRow` — shows rank number, avatar, display name, weekly XP; highlights current user; green highlight for top 3 (promotion zone), red for bottom 3 (demotion zone)
- [ ] `LeagueHomeCard` — compact card showing current tier badge, user rank, countdown timer, top 3 preview; tappable to navigate to full league screen
- [ ] All components use localized strings (keys only, actual strings added in Task 14)
- [ ] Components respect Dynamic Type and Dark Mode
- [ ] Each view file is under 100 lines

---

## Task 10: Presentation — Main League Screen
**Status:** pending
**Estimated effort:** medium
**Dependencies:** Task 8, Task 9

### Description
Create the full `LeagueView` screen showing the complete league ranking, tier information, countdown timer, and navigation to history.

### Files to create/modify
- `FitToday/FitToday/Presentation/Features/League/LeagueView.swift`

### Acceptance Criteria
- [ ] Shows `LeagueTierBadge` (large) at top with season info
- [ ] Countdown timer to season end displayed prominently
- [ ] Full scrollable ranking list using `LeagueRankingRow`
- [ ] Promotion zone (top 3) and demotion zone (bottom 3) visually distinguished
- [ ] Current user row highlighted and auto-scrolled to
- [ ] Loading state with `ProgressView`
- [ ] Empty state when no league assigned
- [ ] Navigation link to `LeagueHistoryView`
- [ ] Pull-to-refresh support
- [ ] Uses `@Bindable` for LeagueViewModel bindings

---

## Task 11: Presentation — Promotion/Demotion Animations
**Status:** pending
**Estimated effort:** medium
**Dependencies:** Task 8

### Description
Create overlay views for promotion and demotion animations shown when a new season starts and the user has been promoted or demoted.

### Files to create/modify
- `FitToday/FitToday/Presentation/Features/League/LeaguePromotionView.swift`
- `FitToday/FitToday/Presentation/Features/League/LeagueDemotionView.swift`

### Acceptance Criteria
- [ ] `LeaguePromotionView` — confetti animation, shows new tier badge, "Promoted!" message, dismiss button
- [ ] `LeagueDemotionView` — subtle shake animation, shows new tier badge, "Demoted" message, dismiss button
- [ ] Both respect `accessibilityReduceMotion` — skip animations when enabled, show static result instead
- [ ] Both auto-dismiss after 5 seconds
- [ ] Animations use SwiftUI native `.animation()` and `withAnimation` (no UIKit)
- [ ] Both views are presented as `.fullScreenCover` or `.sheet` from LeagueView

---

## Task 12: Presentation — League History
**Status:** pending
**Estimated effort:** small
**Dependencies:** Task 8, Task 9

### Description
Create `LeagueHistoryView` showing past season results with tier, rank, XP, and promotion/demotion indicators.

### Files to create/modify
- `FitToday/FitToday/Presentation/Features/League/LeagueHistoryView.swift`

### Acceptance Criteria
- [ ] List of past seasons ordered by most recent first
- [ ] Each row shows: season week number, tier badge (small), final rank, XP earned
- [ ] Promotion indicated with green arrow up icon
- [ ] Demotion indicated with red arrow down icon
- [ ] Empty state when no history
- [ ] Loading state with `ProgressView`
- [ ] Uses `LeagueViewModel.history`

---

## Task 13: Presentation — HomeView Integration
**Status:** pending
**Estimated effort:** small
**Dependencies:** Task 2, Task 9

### Description
Add `LeagueHomeCard` to `HomeView`, gated behind the `leaguesEnabled` feature flag. Follow existing patterns for feature-flag-gated sections in `HomeView`.

### Files to create/modify
- `FitToday/FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/FitToday/Presentation/Features/Home/HomeViewModel.swift`

### Acceptance Criteria
- [ ] `LeagueHomeCard` appears in HomeView when `leaguesEnabled` flag is `true`
- [ ] Card is hidden when flag is `false` (no empty space)
- [ ] Tapping card navigates to `LeagueView` via router
- [ ] `HomeViewModel` resolves `GetCurrentLeagueUseCase` and exposes league data for the card
- [ ] Position: after existing gamification/XP section (contextual proximity)

---

## Task 14: Localization
**Status:** pending
**Estimated effort:** small
**Dependencies:** Task 9, Task 10, Task 11, Task 12

### Description
Add all league-related user-facing strings to both `en.lproj` and `pt-BR.lproj` Localizable.strings files.

### Files to create/modify
- `FitToday/FitToday/Resources/en.lproj/Localizable.strings`
- `FitToday/FitToday/Resources/pt-BR.lproj/Localizable.strings`

### Acceptance Criteria
- [ ] Tier names: Bronze, Silver, Gold, Diamond, Legend (en) / Bronze, Prata, Ouro, Diamante, Lenda (pt-BR)
- [ ] UI strings: "Your League", "Season ends in", "Ranking", "Promoted!", "Demoted", "League History", "No league yet", "Season Week %d"
- [ ] Promotion/demotion messages: "You've been promoted to %@!", "You've been demoted to %@"
- [ ] Zone labels: "Promotion Zone", "Demotion Zone", "Safe Zone"
- [ ] Home card strings: "Your Rank", "View League"
- [ ] All strings use `league.` key prefix (e.g., `"league.tier.bronze"`)
- [ ] No hardcoded strings remain in any league view files

---

## Task 15: Unit Tests
**Status:** pending
**Estimated effort:** medium
**Dependencies:** Task 1, Task 2, Task 3, Task 6, Task 8

### Description
Write unit tests for domain entities, use cases, mapper, entitlement policy changes, and view model. Use existing test patterns (spies, stubs, fixtures).

### Files to create/modify
- `FitToday/FitTodayTests/Domain/LeagueTierTests.swift`
- `FitToday/FitTodayTests/Domain/LeagueEntitlementTests.swift`
- `FitToday/FitTodayTests/Domain/LeagueUseCasesTests.swift`
- `FitToday/FitTodayTests/Data/LeagueMapperTests.swift`
- `FitToday/FitTodayTests/Presentation/Features/LeagueViewModelTests.swift`
- `FitToday/FitTodayTests/Mocks/MockLeagueRepository.swift`
- `FitToday/FitTodayTests/Fixtures/LeagueFixtures.swift`

### Acceptance Criteria
- [ ] `LeagueTierTests` — tier ordering (Comparable), display names, colors, all 5 tiers
- [ ] `LeagueEntitlementTests` — Free can access Bronze only, Pro can access up to Diamond, Elite can access Legend
- [ ] `LeagueUseCasesTests` — each use case delegates to repository correctly, returns nil/empty when feature flag disabled
- [ ] `LeagueMapperTests` — DTO to domain mapping, rank computation by XP sorting, `isCurrentUser` flag, nil/edge cases
- [ ] `LeagueViewModelTests` — loading states, error handling, promotion/demotion zone computation, countdown text formatting
- [ ] `MockLeagueRepository` — spy implementing `LeagueRepository` with configurable return values
- [ ] `LeagueFixtures` — factory methods for test `League`, `LeagueMember`, `LeagueResult`, `FBLeague`
- [ ] All tests use XCTest framework
- [ ] Minimum 80% coverage on use cases and view model logic
