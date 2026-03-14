# Technical Specification

**Project Name:** Sistema de Streaks & XP com Níveis (PRO-90)
**Version:** 1.0
**Date:** 2026-03-12
**Author:** Vinicius Carvalho
**Status:** Draft

---

## Overview

### Problem Statement

O FitToday tem streak tracking básico mas sem progressão tangível (XP/Níveis). Usuários não sentem acúmulo de valor ao treinar consistentemente.

### Proposed Solution

Adicionar sistema de XP e Níveis ao fluxo existente de workout completion, usando a arquitetura MVVM + @Observable do projeto. XP persiste em SwiftData (local) e Firestore (remote).

### Goals

- XP creditado automaticamente após treino
- Níveis temáticos derivados do XP total
- Level-up animation no workout completion
- Display de nível/progresso no home screen
- Feature flag gating via Remote Config

---

## Scope

### In Scope

- Domain entities: `UserXP`, `XPLevel`, `XPTransaction`
- Use case: `AwardXPUseCase`
- Repository: `XPRepository` (protocol + SwiftData + Firestore impl)
- UI: `XPLevelCard` (home), `LevelUpCelebrationView` (completion)
- Feature flag: `gamification_enabled`

### Out of Scope

- Push notifications (APNs/FCM)
- Server-side XP calculation (Cloud Functions)
- Leaderboard de XP
- Badges/Achievements

---

## Technical Approach

### Architecture Overview

Segue a arquitetura existente do FitToday: MVVM com @Observable, injeção via Swinject, persistência dual (SwiftData local + Firestore remote).

### Key Technologies

- **SwiftData**: Persistência local do XP (`SDUserXP`)
- **Firestore**: Persistência remota em `users/{uid}/xp`
- **SwiftUI**: UI components com animações
- **Firebase Remote Config**: Feature flag

### Layer Mapping

```
Domain/
├── Entities/
│   ├── UserXP.swift          # XP total, level, transactions
│   └── XPLevel.swift         # Enum com níveis temáticos
├── Protocols/
│   └── XPRepository.swift    # Repository protocol
└── UseCases/
    └── AwardXPUseCase.swift  # Lógica de award + level-up detection

Data/
├── Models/
│   └── SDUserXP.swift        # SwiftData model
├── DTOs/
│   └── FBUserXP.swift        # Firestore DTO
└── Repositories/
    └── SwiftDataXPRepository.swift  # Implementation

Presentation/
└── Features/
    ├── Home/Components/
    │   └── XPLevelCard.swift  # Home display
    └── Workout/
        └── LevelUpCelebrationView.swift  # Confetti animation
```

---

## Data Model

### Entity: UserXP (Domain)

```swift
struct UserXP: Codable, Sendable {
    var totalXP: Int
    var lastAwardDate: Date?

    var level: Int { totalXP / 1000 + 1 }
    var currentLevelXP: Int { totalXP % 1000 }
    var xpToNextLevel: Int { 1000 - currentLevelXP }
    var levelProgress: Double { Double(currentLevelXP) / 1000.0 }
    var levelTitle: XPLevel { XPLevel(level: level) }

    static let empty = UserXP(totalXP: 0)
}
```

### Entity: XPLevel (Domain)

```swift
enum XPLevel: String, Sendable {
    case iniciante = "Iniciante"
    case guerreiro = "Guerreiro"
    case tita = "Titã"
    case lenda = "Lenda"
    case imortal = "Imortal"

    init(level: Int) {
        switch level {
        case 1...4: self = .iniciante
        case 5...9: self = .guerreiro
        case 10...14: self = .tita
        case 15...19: self = .lenda
        default: self = .imortal
        }
    }

    var icon: String {
        switch self {
        case .iniciante: return "star"
        case .guerreiro: return "shield.fill"
        case .tita: return "bolt.fill"
        case .lenda: return "crown.fill"
        case .imortal: return "flame.fill"
        }
    }
}
```

### Entity: XPTransaction (Domain)

```swift
enum XPTransactionType: String, Codable, Sendable {
    case workoutCompleted
    case streakBonus7
    case streakBonus30
    case challengeCompleted
}

struct XPTransaction: Codable, Sendable {
    let type: XPTransactionType
    let amount: Int
    let date: Date

    static func xpAmount(for type: XPTransactionType) -> Int {
        switch type {
        case .workoutCompleted: return 100
        case .streakBonus7: return 200
        case .streakBonus30: return 500
        case .challengeCompleted: return 500
        }
    }
}
```

### SwiftData Model: SDUserXP

```swift
@Model
final class SDUserXP {
    @Attribute(.unique) var id: String  // "current"
    var totalXP: Int
    var lastAwardDate: Date?

    init(totalXP: Int = 0) {
        self.id = "current"
        self.totalXP = totalXP
    }

    func toDomain() -> UserXP {
        UserXP(totalXP: totalXP, lastAwardDate: lastAwardDate)
    }
}
```

### Firestore DTO: FBUserXP

```swift
struct FBUserXP: Codable, Sendable {
    var totalXP: Int
    var lastAwardDate: Date?
    var level: Int
}
```

Stored at: `users/{uid}` (campos adicionais no documento existente)

---

## Repository

### Protocol: XPRepository

```swift
protocol XPRepository: Sendable {
    func getUserXP() async throws -> UserXP
    func awardXP(transaction: XPTransaction) async throws -> UserXP
    func syncFromRemote() async throws
}
```

### Implementation: SwiftDataXPRepository

- Lê/escreve `SDUserXP` localmente
- Sync com Firestore via `FirebaseUserService` (campos no doc do user)
- Singleton pattern (`id = "current"`) como `SDUserStats`

---

## Use Cases

### AwardXPUseCase

```swift
struct XPAwardResult: Sendable {
    let previousLevel: Int
    let newLevel: Int
    let xpAwarded: Int
    let totalXP: Int
    let didLevelUp: Bool
}

final class AwardXPUseCase {
    func execute(type: XPTransactionType, currentStreak: Int) async throws -> XPAwardResult
}
```

**Logic:**

1. Get current XP from repository
2. Calculate XP amount for transaction type
3. Check streak bonuses (7d → +200, 30d → +500)
4. Award XP via repository
5. Compare previous level vs new level
6. Return `XPAwardResult` with `didLevelUp` flag

---

## UI Components

### XPLevelCard (Home Screen)

Positioned after `WeekStreakRow` in `HomeView`. Shows:

- Level number + nome temático
- SF Symbol icon do nível
- Progress bar (XP atual / 1000)
- XP text: "750 / 1000 XP"

Gated by `gamification_enabled` feature flag.

### LevelUpCelebrationView (Workout Completion)

Overlay shown in `WorkoutCompletionView` when `XPAwardResult.didLevelUp == true`:

- Confetti animation (Canvas-based)
- New level number + nome temático
- "Parabéns!" text
- Auto-dismiss after 5s or on tap
- Respects `accessibilityReduceMotion`

---

## Integration Points

### Workout Completion Flow

In `WorkoutCompletionView.task`:

1. (existing) Save workout to history
2. (existing) `SyncWorkoutCompletionUseCase.execute()`
3. (existing) `UpdateUserStatsUseCase.execute()`
4. **(NEW)** `AwardXPUseCase.execute(type: .workoutCompleted, currentStreak:)`
5. **(NEW)** If `didLevelUp` → show `LevelUpCelebrationView`

### HomeViewModel

Add to `loadUserData()`:

1. **(NEW)** Check `gamification_enabled` flag
2. **(NEW)** Load `UserXP` from repository
3. **(NEW)** Expose `userXP: UserXP?` to view

---

## Feature Flag

Add to `FeatureFlagKey`:

```swift
case gamificationEnabled = "gamification_enabled"  // default: false
```

---

## Testing Strategy

### Unit Tests

- `XPLevelTests`: Verify level calculation from XP amounts
- `AwardXPUseCaseTests`: Test XP award, streak bonuses, level-up detection
- `UserXPTests`: Test computed properties (level, progress, title)

### Coverage Target: 80%+

Focus: `AwardXPUseCase`, `UserXP`, `XPLevel`

---

## Dependencies

### External

| Dependency             | Version  | Purpose            |
| ---------------------- | -------- | ------------------ |
| SwiftData              | iOS 17+  | Local persistence  |
| Firestore              | Existing | Remote persistence |
| Firebase Remote Config | Existing | Feature flag       |

### Internal

- `UpdateUserStatsUseCase` — provides `currentStreak` for bonus calc
- `WorkoutCompletionView` — integration point for XP award
- `HomeViewModel` — integration point for display
- `AppContainer` — DI registration

---

## Success Criteria

- [ ] XP awarded after every workout completion
- [ ] Level calculated correctly from XP total
- [ ] Level-up animation plays when reaching new level
- [ ] Home screen shows level + progress bar
- [ ] Feature flag gates all gamification UI
- [ ] 80%+ unit test coverage on business logic
- [ ] Performance: < 100ms for XP award flow
