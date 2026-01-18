# Technical Specification: Workout Quality Optimization

## Executive Summary

Esta especificação técnica detalha a implementação das melhorias de qualidade de treinos do FitToday. A solução envolve: (1) reestruturação do `WorkoutPromptAssembler` para incluir histórico de 7 dias, limites de exercícios por fase e feedback do usuário; (2) expansão do `SDWorkoutHistoryEntry` com campo de avaliação; (3) integração bidirecional completa com HealthKit; (4) novo modelo `SDUserStats` para métricas agregadas.

A arquitetura mantém o cache em memória existente do `ExerciseDBService`, aproveitando os endpoints disponíveis (Target List, Target, Name, Equipment List, Body Part List) para garantir nomes e imagens corretos dos exercícios.

## System Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Workout      │  │ Completion   │  │ History/Stats        │  │
│  │ Session      │  │ + Feedback   │  │ Dashboard            │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                        Domain Layer                              │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐ │
│  │ GenerateWorkoutPlan  │  │ CompleteWorkoutSession           │ │
│  │ UseCase              │  │ UseCase (+ feedback + HealthKit) │ │
│  └──────────────────────┘  └──────────────────────────────────┘ │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐ │
│  │ FeedbackAnalyzer     │  │ UserStatsCalculator              │ │
│  │ (intensity adjust)   │  │ (streak, aggregates)             │ │
│  └──────────────────────┘  └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ WorkoutPrompt    │  │ ExerciseDB   │  │ HealthKit        │  │
│  │ Assembler v2     │  │ Service      │  │ Service          │  │
│  └──────────────────┘  └──────────────┘  └──────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SwiftData: SDWorkoutHistoryEntry + SDUserStats           │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Componentes Principais:**
- **WorkoutPromptAssembler v2**: Prompt otimizado com histórico 7 dias, limites por fase, feedback
- **FeedbackAnalyzer**: Analisa últimas 5 avaliações para ajustar intensidade
- **UserStatsCalculator**: Calcula streak e métricas agregadas
- **SDUserStats**: Novo modelo SwiftData para métricas pré-calculadas

## Implementation Design

### Core Interfaces

```swift
// MARK: - Feedback System

enum WorkoutRating: String, Codable, CaseIterable, Sendable {
    case tooEasy = "too_easy"
    case adequate = "adequate"
    case tooHard = "too_hard"
}

protocol FeedbackAnalyzing: Sendable {
    /// Analisa últimas N avaliações e retorna ajuste de intensidade
    func analyzeRecentFeedback(
        ratings: [WorkoutRating],
        currentIntensity: WorkoutIntensity
    ) -> IntensityAdjustment
}

struct IntensityAdjustment: Sendable {
    let volumeMultiplier: Double      // 0.8 - 1.2
    let rpeAdjustment: Int            // -1, 0, +1
    let restAdjustment: TimeInterval  // -15s to +30s
    let recommendation: String        // Para incluir no prompt
}

// MARK: - User Stats

protocol UserStatsCalculating: Sendable {
    func calculateCurrentStreak(from history: [WorkoutHistoryEntry]) -> Int
    func calculateWeeklyStats(from history: [WorkoutHistoryEntry]) -> WeeklyStats
    func calculateMonthlyStats(from history: [WorkoutHistoryEntry]) -> MonthlyStats
}

struct WeeklyStats: Codable, Sendable {
    let weekStartDate: Date
    let workoutsCompleted: Int
    let totalDurationMinutes: Int
    let totalCaloriesBurned: Int
    let averageRating: Double?
}
```

### Data Models

```swift
// MARK: - SDWorkoutHistoryEntry (Extended)

@Model
final class SDWorkoutHistoryEntry {
    // ... campos existentes ...

    // NOVO: Avaliação do usuário
    var userRating: String?  // "too_easy", "adequate", "too_hard"

    // NOVO: Lista de exercícios completados (JSON serializado)
    var completedExercisesJSON: Data?
}

// MARK: - SDUserStats (New Model)

@Model
final class SDUserStats {
    @Attribute(.unique) var id: String  // "current" (singleton)

    // Streak
    var currentStreak: Int
    var longestStreak: Int
    var lastWorkoutDate: Date?

    // Agregados semanais
    var weekStartDate: Date
    var weekWorkoutsCount: Int
    var weekTotalMinutes: Int
    var weekTotalCalories: Int

    // Agregados mensais
    var monthStartDate: Date
    var monthWorkoutsCount: Int
    var monthTotalMinutes: Int
    var monthTotalCalories: Int

    // Metadata
    var lastUpdatedAt: Date

    init() {
        self.id = "current"
        self.currentStreak = 0
        self.longestStreak = 0
        self.weekStartDate = Date().startOfWeek
        self.weekWorkoutsCount = 0
        self.weekTotalMinutes = 0
        self.weekTotalCalories = 0
        self.monthStartDate = Date().startOfMonth
        self.monthWorkoutsCount = 0
        self.monthTotalMinutes = 0
        self.monthTotalCalories = 0
        self.lastUpdatedAt = Date()
    }
}

// MARK: - Completed Exercise Record

struct CompletedExercise: Codable, Sendable {
    let exerciseId: String
    let exerciseName: String
    let muscleGroup: String
    let completed: Bool
}
```

### Prompt Structure v2

```swift
// WorkoutPromptAssembler - Melhorias no buildUserMessage

private func buildUserMessage(
    blueprint: WorkoutBlueprint,
    blocks: [WorkoutBlock],
    profile: UserProfile,
    checkIn: DailyCheckIn,
    previousWorkouts: [WorkoutPlan],
    recentRatings: [WorkoutRating]  // NOVO
) -> String {
    let blueprintJSON = formatBlueprint(blueprint)
    let catalogJSON = formatCatalog(blocks: blocks, blueprint: blueprint)
    let previousExercisesContext = formatPreviousWorkouts(previousWorkouts)
    let feedbackContext = formatFeedbackHistory(recentRatings)  // NOVO

    return """
    ## USUÁRIO
    **OBJETIVO PRINCIPAL: \(profile.mainGoal.rawValue.uppercased())**
    Nível: \(profile.level.rawValue) | Equipamentos: \(profile.availableStructure.rawValue)

    ## HOJE
    Foco: \(checkIn.focus.rawValue) | DOMS: \(checkIn.sorenessLevel.rawValue) | Energia: \(checkIn.energyLevel)/10

    ## ESTRUTURA DO TREINO (OBRIGATÓRIO)
    \(blueprintJSON)

    ## LIMITES POR FASE (RESPEITAR)
    - Warmup: 2-3 exercícios
    - Strength: 4-6 exercícios
    - Accessory: 2-4 exercícios
    - Cooldown: 2-3 exercícios

    \(previousExercisesContext)

    \(feedbackContext)

    ## REGRA DE DIVERSIDADE
    - Variar padrões de movimento: incluir PUSH, PULL, HINGE, SQUAT
    - ≥80% dos exercícios devem ser DIFERENTES dos últimos 3 treinos

    ## EXERCÍCIOS DISPONÍVEIS (use APENAS estes)
    \(catalogJSON)

    Retorne APENAS o JSON final.
    """
}

private func formatFeedbackHistory(_ ratings: [WorkoutRating]) -> String {
    guard !ratings.isEmpty else { return "" }

    let summary = analyzeFeedbackTrend(ratings)

    return """
    ## HISTÓRICO DE FEEDBACK DO USUÁRIO
    Últimas \(ratings.count) avaliações: \(ratings.map(\.rawValue).joined(separator: ", "))

    \(summary.recommendation)
    """
}

private func analyzeFeedbackTrend(_ ratings: [WorkoutRating]) -> IntensityAdjustment {
    let tooEasyCount = ratings.filter { $0 == .tooEasy }.count
    let tooHardCount = ratings.filter { $0 == .tooHard }.count

    if tooEasyCount >= 3 {
        return IntensityAdjustment(
            volumeMultiplier: 1.15,
            rpeAdjustment: 1,
            restAdjustment: -15,
            recommendation: "⚡ AUMENTAR INTENSIDADE: Usuário achou últimos treinos muito fáceis. Adicione mais séries ou reduza descanso."
        )
    } else if tooHardCount >= 3 {
        return IntensityAdjustment(
            volumeMultiplier: 0.85,
            rpeAdjustment: -1,
            restAdjustment: 30,
            recommendation: "🛡️ REDUZIR INTENSIDADE: Usuário achou últimos treinos muito difíceis. Reduza volume ou aumente descanso."
        )
    }

    return IntensityAdjustment(
        volumeMultiplier: 1.0,
        rpeAdjustment: 0,
        restAdjustment: 0,
        recommendation: ""
    )
}
```

## Integration Points

### ExerciseDB API (RapidAPI)

**Endpoints utilizados** (conforme imagem):
| Endpoint | Uso | Cache |
|----------|-----|-------|
| `GET /exercises/targetList` | Lista de músculos-alvo válidos | Em memória (sessão) |
| `GET /exercises/target/{target}` | Exercícios por músculo | Em memória |
| `GET /exercises/name/{name}` | Busca por nome | Em memória |
| `GET /exercises/equipmentList` | Lista de equipamentos | Em memória (sessão) |
| `GET /exercises/bodyPartList` | Lista de partes do corpo | Em memória (sessão) |
| `GET /image` | Imagem/GIF do exercício | Em memória |

**Estratégia de otimização (manter <100 req/mês):**
1. Carregar `targetList`, `equipmentList`, `bodyPartList` uma vez por sessão
2. Buscar exercícios por target sob demanda (cache em memória)
3. Enriquecer mídia apenas para exercícios do treino atual (lazy loading)

### Apple HealthKit

**Fluxo de Export (após completar treino):**
```swift
func completeWorkout(
    plan: WorkoutPlan,
    rating: WorkoutRating?,
    completedAt: Date
) async throws {
    // 1. Salvar no histórico local
    let entry = await saveToHistory(plan, rating: rating, completedAt: completedAt)

    // 2. Exportar para HealthKit (se autorizado)
    if await healthKitService.authorizationState() == .authorized {
        let receipt = try await healthKitService.exportWorkout(plan: plan, completedAt: completedAt)

        // 3. Buscar calorias do HealthKit (após ~5s para sync)
        try await Task.sleep(for: .seconds(5))
        let metrics = try await healthKitService.fetchWorkouts(
            in: DateInterval(start: completedAt.addingTimeInterval(-3600), end: completedAt)
        )

        if let matched = metrics.first(where: { $0.workoutUUID == receipt.workoutUUID }) {
            await updateEntryWithHealthKitData(entry, calories: matched.caloriesBurned)
        }
    }

    // 4. Atualizar estatísticas agregadas
    await updateUserStats()
}
```

## Testing Strategy

### Unit Tests

**Componentes críticos:**
1. `FeedbackAnalyzer` - Testar ajustes de intensidade para diferentes combinações de ratings
2. `UserStatsCalculator` - Testar cálculo de streak (gaps, consecutivos, edge cases)
3. `WorkoutPromptAssembler` - Testar formatação de prompt com feedback history

**Cenários de teste:**
```swift
// FeedbackAnalyzerTests
func test_analyze_whenMajorityTooEasy_shouldIncreaseIntensity()
func test_analyze_whenMajorityTooHard_shouldDecreaseIntensity()
func test_analyze_whenMixed_shouldMaintainIntensity()

// UserStatsCalculatorTests
func test_streak_consecutiveDays_shouldCountCorrectly()
func test_streak_withGap_shouldResetToZero()
func test_weeklyStats_shouldAggregateCorrectly()
```

## Development Sequencing

### Build Order

1. **Fase 1: Data Models** (1-2 dias)
   - Adicionar `userRating` ao `SDWorkoutHistoryEntry`
   - Criar `SDUserStats` model
   - Migração SwiftData

2. **Fase 2: Feedback System** (2-3 dias)
   - Implementar `FeedbackAnalyzer`
   - UI de avaliação pós-treino
   - Integrar com `WorkoutPromptAssembler`

3. **Fase 3: Prompt Optimization** (2-3 dias)
   - Refatorar `buildUserMessage` com limites por fase
   - Adicionar contexto de feedback
   - Implementar regra de diversidade 80%

4. **Fase 4: HealthKit Integration** (2 dias)
   - Completar fluxo de export + import calorias
   - Toggle de sincronização nas configurações

5. **Fase 5: Stats Dashboard** (2-3 dias)
   - Implementar `UserStatsCalculator`
   - UI de streak e comparativos na aba Histórico

### Technical Dependencies

- SwiftData migration para novos campos
- HealthKit entitlements (já configurados)
- OpenAI API key (usuários Pro)

## Technical Considerations

### Key Decisions

| Decisão | Justificativa |
|---------|---------------|
| Cache em memória (não SwiftData) | Simplicidade, ExerciseDB já tem cache eficiente, limite de 200 req/mês é suficiente |
| `userRating` como String | Flexibilidade para adicionar novos valores sem migração |
| `SDUserStats` singleton | Performance - evita recálculo a cada abertura da aba Histórico |
| Buscar calorias após 5s delay | HealthKit pode demorar para sincronizar dados do Apple Watch |

### Known Risks

| Risco | Mitigação |
|-------|-----------|
| HealthKit negado pelo usuário | Fallback: mostrar apenas duração, sem calorias |
| OpenAI ignorar limites de exercícios | Quality gate existente + retry com feedback explícito |
| Streak quebrado por timezone | Usar `Calendar.current` com timezone do dispositivo |

### Special Requirements

- **Performance**: Cálculo de stats < 100ms (usar índices SwiftData)
- **Privacy**: Dados de saúde apenas no device (já garantido pelo HealthKit)

## Relevant Files

### Files to Modify
- `/Data/Services/OpenAI/WorkoutPromptAssembler.swift` - Adicionar feedback context
- `/Data/Models/SDWorkoutHistoryEntry.swift` - Adicionar `userRating`
- `/Data/Services/HealthKit/HealthKitService.swift` - Import calorias
- `/Domain/UseCases/CompleteWorkoutSessionUseCase.swift` - Integrar feedback + HealthKit
- `/Presentation/Features/Workout/WorkoutCompletionView.swift` - UI de avaliação

### Files to Create
- `/Data/Models/SDUserStats.swift` - Novo modelo de estatísticas
- `/Domain/Services/FeedbackAnalyzer.swift` - Análise de tendência de feedback
- `/Domain/Services/UserStatsCalculator.swift` - Cálculo de métricas agregadas
- `/Presentation/Features/History/StatsCardView.swift` - Card de streak/stats
