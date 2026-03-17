# Technical Specification: League System (PRO-91)

**Platform:** iOS 17+ | **Language:** Swift 6.0 | **UI:** SwiftUI
**Architecture:** MVVM with @Observable | **Backend:** Firebase Firestore
**Status:** Draft | **Date:** 2026-03-14

---

## 1. Architecture Overview

The League System is a **read-only** feature on iOS. All league assignment, promotion, and demotion logic is handled by Cloud Functions. The iOS client reads Firestore data and presents it.

### Data Flow

```
Firestore → FirebaseLeagueService (actor) → FirebaseLeagueRepository → UseCase → LeagueViewModel → View
```

### Layer Responsibilities

| Layer | Component | Responsibility |
|-------|-----------|----------------|
| **Data** | `FirebaseLeagueService` | Firestore queries, snapshot listeners, returns `FB*` DTOs |
| **Data** | `FirebaseLeagueRepository` | Implements `LeagueRepository`, maps DTOs to domain entities |
| **Data** | `LeagueMapper` | Bidirectional mapping `FB*` <-> domain structs |
| **Domain** | `LeagueRepository` protocol | Contract for league data access |
| **Domain** | `GetCurrentLeagueUseCase` | Fetches user's current league + members |
| **Domain** | `ObserveLeagueUseCase` | Real-time ranking updates via `AsyncStream` |
| **Domain** | `GetLeagueHistoryUseCase` | Past season results |
| **Presentation** | `LeagueViewModel` | Manages state, coordinates use cases |
| **Presentation** | `LeagueView`, `LeagueHomeCard`, etc. | SwiftUI views |

### File Locations

```
FitToday/
├── Data/
│   ├── DTOs/
│   │   └── FBLeagueModels.swift          # FBLeague, FBLeagueMember, FBLeagueResult
│   ├── Mappers/
│   │   └── LeagueMapper.swift            # FB* <-> Domain mapping
│   ├── Services/Firebase/
│   │   └── FirebaseLeagueService.swift   # Firestore queries (actor)
│   └── Repositories/
│       └── FirebaseLeagueRepository.swift
├── Domain/
│   ├── Entities/
│   │   └── LeagueModels.swift            # LeagueTier, League, LeagueMember, etc.
│   ├── Protocols/
│   │   └── LeagueRepository.swift
│   └── UseCases/
│       └── LeagueUseCases.swift          # GetCurrentLeague, Observe, GetHistory
└── Presentation/
    └── Features/League/
        ├── Views/
        │   ├── LeagueView.swift
        │   ├── LeagueRankingRow.swift
        │   ├── LeaguePromotionView.swift
        │   ├── LeagueDemotionView.swift
        │   ├── LeagueTierBadge.swift
        │   ├── LeagueHistoryView.swift
        │   └── LeagueHomeCard.swift
        └── ViewModels/
            └── LeagueViewModel.swift
```

---

## 2. Data Model

### 2.1 Firestore Collections

#### `leagues/{leagueId}`

League instance document. Each league holds up to 30 users in the same tier for a given season (week).

```
{
  "tier": "silver",               // string: bronze | silver | gold | diamond | legend
  "season": 12,                   // int: week number in the year
  "memberCount": 28,              // int: current members (max 30)
  "startDate": Timestamp,         // start of the weekly season
  "endDate": Timestamp,           // end of the weekly season
  "isActive": true                // bool: whether season is in progress
}
```

#### `leagues/{leagueId}/members/{userId}`

Member within a league instance. Updated as users earn XP.

```
{
  "userId": "abc123",
  "displayName": "John",
  "photoURL": "https://...",
  "weeklyXP": 450,               // int: XP earned this week
  "rank": 3                       // int: current rank (1-based, computed by Cloud Function)
}
```

#### `leagueHistory/{historyId}`

Historical record written by Cloud Function at end of each season.

```
{
  "userId": "abc123",
  "season": 11,
  "tier": "bronze",
  "finalRank": 2,
  "xpEarned": 520,
  "result": "promoted",           // string: promoted | demoted | stayed
  "previousTier": "bronze",
  "newTier": "silver",
  "processedAt": Timestamp
}
```

### 2.2 Swift Domain Entities

File: `Domain/Entities/LeagueModels.swift`

```swift
// MARK: - League Tier

enum LeagueTier: String, Codable, CaseIterable, Sendable {
    case bronze
    case silver
    case gold
    case diamond
    case legend

    var displayName: String {
        switch self {
        case .bronze:  return String(localized: "league_tier_bronze")
        case .silver:  return String(localized: "league_tier_silver")
        case .gold:    return String(localized: "league_tier_gold")
        case .diamond: return String(localized: "league_tier_diamond")
        case .legend:  return String(localized: "league_tier_legend")
        }
    }

    var iconName: String {
        switch self {
        case .bronze:  return "shield.fill"
        case .silver:  return "shield.lefthalf.filled"
        case .gold:    return "shield.checkered"
        case .diamond: return "diamond.fill"
        case .legend:  return "crown.fill"
        }
    }

    /// Minimum subscription tier required to participate
    var requiredSubscription: SubscriptionTier {
        switch self {
        case .bronze:           return .free
        case .silver, .gold:    return .pro
        case .diamond:          return .pro
        case .legend:           return .elite
        }
    }

    /// Sort order for display (0 = lowest)
    var level: Int {
        switch self {
        case .bronze:  return 0
        case .silver:  return 1
        case .gold:    return 2
        case .diamond: return 3
        case .legend:  return 4
        }
    }
}

// MARK: - League

struct League: Identifiable, Sendable {
    let id: String
    let tier: LeagueTier
    let season: Int
    let memberCount: Int
    let startDate: Date
    let endDate: Date
    let isActive: Bool
}

// MARK: - League Member

struct LeagueMember: Identifiable, Sendable {
    let id: String           // same as userId
    let userId: String
    let displayName: String
    let photoURL: URL?
    let weeklyXP: Int
    let rank: Int
    let isCurrentUser: Bool
}

// MARK: - League Result

enum LeagueOutcome: String, Codable, Sendable {
    case promoted
    case demoted
    case stayed
}

struct LeagueResult: Sendable {
    let previousTier: LeagueTier
    let newTier: LeagueTier
    let finalRank: Int
    let outcome: LeagueOutcome
}

// MARK: - League History

struct LeagueHistory: Identifiable, Sendable {
    let id: String
    let season: Int
    let tier: LeagueTier
    let finalRank: Int
    let xpEarned: Int
    let outcome: LeagueOutcome
    let previousTier: LeagueTier
    let newTier: LeagueTier
    let processedAt: Date
}
```

### 2.3 DTOs (Firestore)

File: `Data/DTOs/FBLeagueModels.swift`

```swift
import FirebaseFirestore

// MARK: - FBLeague

struct FBLeague: Codable, Sendable {
    @DocumentID var id: String?
    var tier: String
    var season: Int
    var memberCount: Int
    var startDate: Timestamp?
    var endDate: Timestamp?
    var isActive: Bool
}

// MARK: - FBLeagueMember

struct FBLeagueMember: Codable, Sendable {
    @DocumentID var id: String?
    var userId: String
    var displayName: String
    var photoURL: String?
    var weeklyXP: Int
    var rank: Int
}

// MARK: - FBLeagueHistory

struct FBLeagueHistory: Codable, Sendable {
    @DocumentID var id: String?
    var userId: String
    var season: Int
    var tier: String
    var finalRank: Int
    var xpEarned: Int
    var result: String
    var previousTier: String
    var newTier: String
    var processedAt: Timestamp?
}
```

---

## 3. Domain Layer

### 3.1 Repository Protocol

File: `Domain/Protocols/LeagueRepository.swift`

```swift
protocol LeagueRepository: Sendable {
    /// Fetches the current league for the authenticated user.
    func getCurrentLeague() async throws -> League?

    /// Fetches members of a league, sorted by rank.
    func getLeagueMembers(leagueId: String) async throws -> [LeagueMember]

    /// Real-time listener for league member ranking updates.
    func observeLeagueMembers(leagueId: String) -> AsyncStream<[LeagueMember]>

    /// Fetches past season results for the current user.
    func getLeagueHistory(userId: String) async throws -> [LeagueHistory]

    /// Fetches the latest league result (promotion/demotion) for the user.
    func getLatestResult(userId: String) async throws -> LeagueResult?
}
```

### 3.2 Use Cases

File: `Domain/UseCases/LeagueUseCases.swift`

```swift
// MARK: - GetCurrentLeagueUseCase

/// Fetches user's current league and its members.
/// Returns nil if user is not assigned to any league.
final class GetCurrentLeagueUseCase: @unchecked Sendable {
    private let leagueRepository: LeagueRepository

    init(leagueRepository: LeagueRepository) {
        self.leagueRepository = leagueRepository
    }

    func execute() async throws -> (league: League, members: [LeagueMember])? {
        guard let league = try await leagueRepository.getCurrentLeague() else {
            return nil
        }
        let members = try await leagueRepository.getLeagueMembers(leagueId: league.id)
        return (league, members)
    }
}

// MARK: - ObserveLeagueUseCase

/// Provides a real-time stream of league member rankings.
final class ObserveLeagueUseCase: @unchecked Sendable {
    private let leagueRepository: LeagueRepository

    init(leagueRepository: LeagueRepository) {
        self.leagueRepository = leagueRepository
    }

    func execute(leagueId: String) -> AsyncStream<[LeagueMember]> {
        leagueRepository.observeLeagueMembers(leagueId: leagueId)
    }
}

// MARK: - GetLeagueHistoryUseCase

/// Fetches the user's past season results.
final class GetLeagueHistoryUseCase: @unchecked Sendable {
    private let leagueRepository: LeagueRepository

    init(leagueRepository: LeagueRepository) {
        self.leagueRepository = leagueRepository
    }

    func execute(userId: String) async throws -> [LeagueHistory] {
        try await leagueRepository.getLeagueHistory(userId: userId)
    }
}
```

---

## 4. Data Layer

### 4.1 FirebaseLeagueService

File: `Data/Services/Firebase/FirebaseLeagueService.swift`

An `actor` encapsulating all Firestore queries for league data. Follows the same pattern as `FirebaseLeaderboardService`.

```swift
actor FirebaseLeagueService {
    private let db = Firestore.firestore()

    // MARK: - Auth Check

    private func currentUserId() throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw LeagueError.userNotAuthenticated
        }
        return user.uid
    }

    // MARK: - Queries

    /// Finds the active league the current user belongs to.
    /// Query: `leagues` where `isActive == true`, then check subcollection `members` for userId.
    func getCurrentLeague() async throws -> FBLeague? { ... }

    /// Fetches all members in a league, ordered by `rank` ascending.
    func getLeagueMembers(leagueId: String) async throws -> [FBLeagueMember] { ... }

    /// Real-time listener on `leagues/{leagueId}/members` ordered by `rank`.
    /// Returns AsyncStream<[FBLeagueMember]> using Firestore snapshotListener.
    func observeLeagueMembers(leagueId: String) -> AsyncStream<[FBLeagueMember]> {
        AsyncStream { continuation in
            let listener = db.collection("leagues")
                .document(leagueId)
                .collection("members")
                .order(by: "rank")
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    let members = documents.compactMap {
                        try? $0.data(as: FBLeagueMember.self)
                    }
                    continuation.yield(members)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    /// Fetches league history for a user, ordered by season descending.
    func getLeagueHistory(userId: String) async throws -> [FBLeagueHistory] { ... }

    /// Fetches the most recent league result for promotion/demotion display.
    func getLatestResult(userId: String) async throws -> FBLeagueHistory? { ... }
}
```

**Firestore indexes required:**
- `leagues` composite: `isActive ASC` (for active league queries)
- `leagues/{leagueId}/members` composite: `rank ASC`
- `leagueHistory` composite: `userId ASC, season DESC`

### 4.2 FirebaseLeagueRepository

File: `Data/Repositories/FirebaseLeagueRepository.swift`

Implements `LeagueRepository` protocol. Maps all `FB*` types to domain entities using `LeagueMapper`. Follows the same pattern as `FirebaseLeaderboardRepository`.

```swift
final class FirebaseLeagueRepository: LeagueRepository, @unchecked Sendable {
    private let leagueService: FirebaseLeagueService

    init(leagueService: FirebaseLeagueService = FirebaseLeagueService()) {
        self.leagueService = leagueService
    }

    func getCurrentLeague() async throws -> League? {
        guard let fb = try await leagueService.getCurrentLeague() else { return nil }
        return fb.toDomain()
    }

    func getLeagueMembers(leagueId: String) async throws -> [LeagueMember] {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let fbMembers = try await leagueService.getLeagueMembers(leagueId: leagueId)
        return fbMembers.map { $0.toDomain(isCurrentUser: $0.userId == currentUserId) }
    }

    func observeLeagueMembers(leagueId: String) -> AsyncStream<[LeagueMember]> {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        return AsyncStream { continuation in
            let task = Task {
                for await fbMembers in leagueService.observeLeagueMembers(leagueId: leagueId) {
                    let members = fbMembers.map {
                        $0.toDomain(isCurrentUser: $0.userId == currentUserId)
                    }
                    continuation.yield(members)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func getLeagueHistory(userId: String) async throws -> [LeagueHistory] {
        let fbHistory = try await leagueService.getLeagueHistory(userId: userId)
        return fbHistory.map { $0.toDomain() }
    }

    func getLatestResult(userId: String) async throws -> LeagueResult? {
        guard let fb = try await leagueService.getLatestResult(userId: userId) else { return nil }
        return fb.toLeagueResult()
    }
}
```

### 4.3 LeagueMapper

File: `Data/Mappers/LeagueMapper.swift`

Extension-based mapping following the existing `SocialUserMapper` pattern.

```swift
extension FBLeague {
    func toDomain() -> League {
        League(
            id: id ?? "",
            tier: LeagueTier(rawValue: tier) ?? .bronze,
            season: season,
            memberCount: memberCount,
            startDate: startDate?.dateValue() ?? Date(),
            endDate: endDate?.dateValue() ?? Date(),
            isActive: isActive
        )
    }
}

extension FBLeagueMember {
    func toDomain(isCurrentUser: Bool = false) -> LeagueMember {
        LeagueMember(
            id: userId,
            userId: userId,
            displayName: displayName,
            photoURL: photoURL.flatMap { URL(string: $0) },
            weeklyXP: weeklyXP,
            rank: rank,
            isCurrentUser: isCurrentUser
        )
    }
}

extension FBLeagueHistory {
    func toDomain() -> LeagueHistory {
        LeagueHistory(
            id: id ?? "",
            season: season,
            tier: LeagueTier(rawValue: tier) ?? .bronze,
            finalRank: finalRank,
            xpEarned: xpEarned,
            outcome: LeagueOutcome(rawValue: result) ?? .stayed,
            previousTier: LeagueTier(rawValue: previousTier) ?? .bronze,
            newTier: LeagueTier(rawValue: newTier) ?? .bronze,
            processedAt: processedAt?.dateValue() ?? Date()
        )
    }

    func toLeagueResult() -> LeagueResult {
        LeagueResult(
            previousTier: LeagueTier(rawValue: previousTier) ?? .bronze,
            newTier: LeagueTier(rawValue: newTier) ?? .bronze,
            finalRank: finalRank,
            outcome: LeagueOutcome(rawValue: result) ?? .stayed
        )
    }
}
```

### 4.4 Errors

```swift
enum LeagueError: LocalizedError {
    case userNotAuthenticated
    case leagueNotFound
    case firestoreError(Error)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to access leagues"
        case .leagueNotFound:
            return "No active league found for user"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        }
    }
}
```

---

## 5. Presentation Layer

### 5.1 LeagueViewModel

File: `Presentation/Features/League/ViewModels/LeagueViewModel.swift`

Follows the same `@MainActor @Observable` pattern as `LeaderboardViewModel`.

```swift
@MainActor
@Observable final class LeagueViewModel {
    // MARK: - State

    enum ViewState: Equatable {
        case loading
        case loaded
        case empty           // user not in any league yet
        case error(String)
    }

    private(set) var state: ViewState = .loading
    private(set) var league: League?
    private(set) var members: [LeagueMember] = []
    private(set) var history: [LeagueHistory] = []
    private(set) var latestResult: LeagueResult?
    private(set) var timeRemaining: TimeInterval = 0

    /// Controls display of promotion/demotion sheet
    var showResultSheet = false

    // MARK: - Dependencies

    private let resolver: Resolver
    nonisolated(unsafe) private var observeTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: - Load

    func loadLeague() async {
        state = .loading

        guard let getCurrentLeague = resolver.resolve(GetCurrentLeagueUseCase.self) else {
            state = .error("League service unavailable")
            return
        }

        do {
            guard let result = try await getCurrentLeague.execute() else {
                state = .empty
                return
            }
            league = result.league
            members = result.members
            state = .loaded

            // Start real-time observation
            startObserving(leagueId: result.league.id)
            startCountdown(endDate: result.league.endDate)

            // Check for recent promotion/demotion
            await checkLatestResult()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Observe

    private func startObserving(leagueId: String) {
        observeTask?.cancel()

        guard let observeUseCase = resolver.resolve(ObserveLeagueUseCase.self) else { return }

        observeTask = Task {
            for await updatedMembers in observeUseCase.execute(leagueId: leagueId) {
                await MainActor.run {
                    self.members = updatedMembers
                }
            }
        }
    }

    // MARK: - Countdown

    private func startCountdown(endDate: Date) {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                let remaining = endDate.timeIntervalSinceNow
                await MainActor.run {
                    self.timeRemaining = max(0, remaining)
                }
                if remaining <= 0 { break }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    // MARK: - Result Check

    private func checkLatestResult() async {
        guard let repo = resolver.resolve(LeagueRepository.self),
              let userId = Auth.auth().currentUser?.uid else { return }

        latestResult = try? await repo.getLatestResult(userId: userId)
        if latestResult != nil {
            showResultSheet = true
        }
    }

    // MARK: - History

    func loadHistory() async {
        guard let historyUseCase = resolver.resolve(GetLeagueHistoryUseCase.self),
              let userId = Auth.auth().currentUser?.uid else { return }

        history = (try? await historyUseCase.execute(userId: userId)) ?? []
    }

    // MARK: - Cleanup

    func stopObserving() {
        observeTask?.cancel()
        timerTask?.cancel()
    }
}
```

### 5.2 Views

#### LeagueView (Main Screen)

Primary league screen showing the ranking list, tier badge, and countdown timer.

| Section | Content |
|---------|---------|
| Header | `LeagueTierBadge` + tier name + countdown to reset |
| Ranking List | `List` of `LeagueRankingRow` (current user highlighted) |
| Top 3 | Green background/accent (promotion zone) |
| Bottom 3 | Red background/accent (demotion zone) |
| Empty State | Message prompting user to complete workouts to earn XP |
| Navigation | Link to `LeagueHistoryView` |

#### LeagueRankingRow

Individual row showing: rank medal/number, avatar, display name, XP badge. Current user row uses `.listRowBackground` highlight.

#### LeaguePromotionView

Full-screen overlay triggered when `latestResult.outcome == .promoted`. Shows confetti animation (using Canvas or a lightweight confetti package), new tier badge, and dismiss button.

#### LeagueDemotionView

Full-screen overlay triggered when `latestResult.outcome == .demoted`. Subtle shake animation on the tier badge, motivational message, dismiss button.

#### LeagueTierBadge

Reusable component accepting a `LeagueTier`. Renders the tier icon with a colored background circle. Used in `LeagueView`, `LeagueHomeCard`, and `LeagueHistoryView`.

#### LeagueHistoryView

List of past seasons showing: season number, tier badge, final rank, XP earned, outcome indicator (arrow up/down/neutral).

#### LeagueHomeCard

Compact card for `HomeView` showing: current tier badge, current rank, "View League" CTA. Hidden when `leagues_enabled` is `false` or user has no league.

---

## 6. Feature Flag Integration

### New Flag

Add to `FeatureFlagKey` enum:

```swift
// MARK: - Leagues
/// Enables the league ranking system.
case leaguesEnabled = "leagues_enabled"
```

- **Default value:** `false` (added to the `false` switch case group with other unreleased features)
- **Display name:** `"Leagues"`

### Gating Points

1. **HomeView** -- hide `LeagueHomeCard` when flag is disabled
2. **Tab/Navigation** -- hide league entry point when flag is disabled
3. **LeagueViewModel.loadLeague()** -- early return when flag is disabled

### Usage Pattern

```swift
// In LeagueViewModel
let flagUseCase = resolver.resolve(FeatureFlagChecking.self)
guard await flagUseCase?.isFeatureEnabled(.leaguesEnabled) == true else {
    state = .empty
    return
}
```

---

## 7. Entitlement Integration

League tier access is controlled by `SubscriptionTier`. The Cloud Function assigns users to appropriate leagues based on their subscription. The iOS client validates display access.

| League Tier | Required Subscription | Behavior |
|-------------|----------------------|----------|
| Bronze | `.free` | All users can participate |
| Silver | `.pro` | Free users see paywall if promoted to Silver |
| Gold | `.pro` | Same as Silver |
| Diamond | `.pro` | Same as Silver |
| Legend | `.elite` | Pro users see Elite upgrade prompt |

### New ProFeature Case

Add to `ProFeature` enum:

```swift
case leagueSilverPlus = "league_silver_plus"
```

Add to `EntitlementPolicy.canAccess`:

```swift
case .leagueSilverPlus:
    return .requiresPro(feature: feature)
```

### Client-Side Check

When displaying a league that requires a higher subscription:

```swift
func tierAccessCheck(tier: LeagueTier, entitlement: ProEntitlement) -> FeatureAccessResult {
    switch tier.requiredSubscription {
    case .free:
        return .allowed
    case .pro where entitlement.isPro:
        return .allowed
    case .elite where entitlement.isElite:
        return .allowed
    case .pro:
        return .requiresPro(feature: .leagueSilverPlus)
    case .elite:
        return .requiresElite(feature: .leagueSilverPlus)
    }
}
```

---

## 8. DI Registration

Add to `AppContainer.swift` after the existing leaderboard registrations:

```swift
// ========== LEAGUES ==========

let leagueService = FirebaseLeagueService()

container.register(LeagueRepository.self) { _ in
    FirebaseLeagueRepository(leagueService: leagueService)
}.inObjectScope(.container)

container.register(GetCurrentLeagueUseCase.self) { resolver in
    GetCurrentLeagueUseCase(
        leagueRepository: resolver.resolve(LeagueRepository.self)!
    )
}.inObjectScope(.transient)

container.register(ObserveLeagueUseCase.self) { resolver in
    ObserveLeagueUseCase(
        leagueRepository: resolver.resolve(LeagueRepository.self)!
    )
}.inObjectScope(.transient)

container.register(GetLeagueHistoryUseCase.self) { resolver in
    GetLeagueHistoryUseCase(
        leagueRepository: resolver.resolve(LeagueRepository.self)!
    )
}.inObjectScope(.transient)
```

**Scope rationale:**
- `LeagueRepository`: `.container` (single instance, holds the service actor)
- Use cases: `.transient` (lightweight, no state)

---

## 9. Localization

All user-facing strings added to `Localizable.strings` for `en` and `pt-BR`.

### Keys

```
// League Tiers
"league_tier_bronze" = "Bronze";
"league_tier_silver" = "Silver";
"league_tier_gold" = "Gold";
"league_tier_diamond" = "Diamond";
"league_tier_legend" = "Legend";

// League View
"league_title" = "League";
"league_ranking_title" = "Ranking";
"league_your_rank" = "Your Rank";
"league_weekly_xp" = "%d XP this week";
"league_time_remaining" = "Resets in %@";
"league_promotion_zone" = "Promotion Zone";
"league_demotion_zone" = "Demotion Zone";
"league_no_league" = "You're not in a league yet";
"league_no_league_description" = "Complete workouts to earn XP and join a league!";
"league_history_title" = "Past Seasons";

// Promotion/Demotion
"league_promoted_title" = "Promoted!";
"league_promoted_message" = "You advanced to %@!";
"league_demoted_title" = "Demoted";
"league_demoted_message" = "You dropped to %@. Keep training!";
"league_stayed_title" = "Season Complete";
"league_stayed_message" = "You stayed in %@. Aim higher next week!";

// Home Card
"league_home_card_title" = "Your League";
"league_home_card_rank" = "Rank #%d";
"league_home_card_cta" = "View League";

// Entitlement
"league_requires_pro" = "Silver league and above require Pro";
"league_requires_elite" = "Legend league requires Elite";
```

**pt-BR equivalents** follow the same keys with Portuguese translations.

---

## 10. Testing Strategy

### 10.1 Unit Tests

#### Domain Tests

| Test File | What It Tests |
|-----------|---------------|
| `LeagueUseCasesTests.swift` | `GetCurrentLeagueUseCase`, `ObserveLeagueUseCase`, `GetLeagueHistoryUseCase` |
| `LeagueTierTests.swift` | `LeagueTier.requiredSubscription` mapping, `level` ordering |

#### Data Tests

| Test File | What It Tests |
|-----------|---------------|
| `LeagueMapperTests.swift` | `FBLeague.toDomain()`, `FBLeagueMember.toDomain()`, `FBLeagueHistory.toDomain()` |

#### Presentation Tests

| Test File | What It Tests |
|-----------|---------------|
| `LeagueViewModelTests.swift` | State transitions (loading/loaded/empty/error), result sheet trigger, countdown |

### 10.2 Mock Repository

```swift
final class MockLeagueRepository: LeagueRepository, @unchecked Sendable {
    var currentLeague: League?
    var members: [LeagueMember] = []
    var history: [LeagueHistory] = []
    var latestResult: LeagueResult?
    var shouldThrow = false

    func getCurrentLeague() async throws -> League? {
        if shouldThrow { throw LeagueError.leagueNotFound }
        return currentLeague
    }

    func getLeagueMembers(leagueId: String) async throws -> [LeagueMember] {
        if shouldThrow { throw LeagueError.firestoreError(NSError()) }
        return members
    }

    func observeLeagueMembers(leagueId: String) -> AsyncStream<[LeagueMember]> {
        AsyncStream { continuation in
            continuation.yield(members)
            continuation.finish()
        }
    }

    func getLeagueHistory(userId: String) async throws -> [LeagueHistory] {
        history
    }

    func getLatestResult(userId: String) async throws -> LeagueResult? {
        latestResult
    }
}
```

### 10.3 Key Test Scenarios

- **Promotion/Demotion display:** Verify `showResultSheet` triggers correctly for each `LeagueOutcome`
- **Empty state:** User with no league sees empty state
- **Feature flag disabled:** ViewModel returns empty state when `leagues_enabled == false`
- **Tier access:** Free user in Silver league sees paywall prompt
- **Mapper edge cases:** Missing/invalid tier strings default to `.bronze`
- **Real-time updates:** `observeLeagueMembers` stream yields updated rankings

### 10.4 Fixtures

```swift
enum LeagueFixtures {
    static let bronzeLeague = League(
        id: "league-1",
        tier: .bronze,
        season: 12,
        memberCount: 25,
        startDate: Date(),
        endDate: Date().addingTimeInterval(7 * 24 * 3600),
        isActive: true
    )

    static let sampleMembers: [LeagueMember] = (1...5).map { rank in
        LeagueMember(
            id: "user-\(rank)",
            userId: "user-\(rank)",
            displayName: "User \(rank)",
            photoURL: nil,
            weeklyXP: 500 - (rank * 50),
            rank: rank,
            isCurrentUser: rank == 3
        )
    }
}
```

---

## Implementation Order

1. **Domain entities** (`LeagueModels.swift`, `LeagueRepository.swift`)
2. **DTOs and Mappers** (`FBLeagueModels.swift`, `LeagueMapper.swift`)
3. **Firebase service** (`FirebaseLeagueService.swift`)
4. **Repository implementation** (`FirebaseLeagueRepository.swift`)
5. **Use cases** (`LeagueUseCases.swift`)
6. **Feature flag** (add `leaguesEnabled` to `FeatureFlagKey`)
7. **Entitlement** (add `leagueSilverPlus` to `ProFeature`)
8. **DI registration** (update `AppContainer.swift`)
9. **ViewModel** (`LeagueViewModel.swift`)
10. **Views** (start with `LeagueTierBadge`, then `LeagueRankingRow`, then `LeagueView`, then cards/sheets)
11. **Localization** (add all strings)
12. **Tests** (mappers first, then use cases, then ViewModel)
