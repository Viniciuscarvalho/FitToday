# TechSpec: Ajustes em Desafios, Stats, Configuracoes e Explorar

## Arquitetura Existente

- MVVM com @Observable
- Swinject DI
- AppRouter com NavigationPath por tab
- SwiftData + Firebase para persistencia
- Tabs: home, workout, create, activity, profile

## Mudanca 1: Wiring do Share/Invite nos Desafios

### Problema
- `ChallengeDetailView` toolbar share button: acao vazia (stub)
- `GroupsView.handleInviteTapped()`: corpo vazio (stub)
- `InviteShareSheet` e `GenerateInviteLinkUseCase` ja implementados e funcionais

### Solucao

**ChallengesView.swift** (`ChallengeDetailView`):
- Adicionar `groupId: String?` como parametro
- Adicionar `@State private var showShareSheet = false`
- No share button: `showShareSheet = true`
- Adicionar `.sheet(isPresented: $showShareSheet)` com `InviteShareSheet`
- Usar `GenerateInviteLinkUseCase` para gerar links

**GroupsView.swift** (`handleInviteTapped`):
- Adicionar `@State private var showInviteSheet = false`
- Em `handleInviteTapped()`: set `showInviteSheet = true`
- Adicionar `.sheet(isPresented: $showInviteSheet)` com `InviteShareSheet`
- Usar `GenerateInviteLinkUseCase` com `viewModel.currentGroup?.id`

**ChallengesViewModel.swift**:
- Adicionar `currentGroupId` (ja existe) para passar ao `ChallengeDetailView`

### Dependencias
- `InviteShareSheet` (existe em `Groups/Components/InviteShareSheet.swift`)
- `GenerateInviteLinkUseCase` (existe em `Domain/UseCases/`)

---

## Mudanca 2: Stats com Swift Charts

### Problema
- `ActivityStatsView` exibe dados mock hardcoded
- Sem ViewModel, sem conexao a dados reais
- Sem graficos — apenas cards estaticos

### Solucao

**Novo arquivo: `ActivityStatsViewModel.swift`**
- `@Observable @MainActor final class ActivityStatsViewModel`
- Dependencias: `UserStatsRepository`, `WorkoutHistoryRepository`
- Properties: `stats: UserStats?`, `weeklyChartData: [DailyChartEntry]`, `monthlyChartData: [WeeklyChartEntry]`
- `loadStats()`: busca `UserStats` do repository
- `loadChartData()`: busca `WorkoutHistoryEntry` e agrupa por dia (semana) e por semana (mes)

**Novos modelos de chart (dentro do ViewModel ou arquivo separado)**:
```swift
struct DailyChartEntry: Identifiable {
    let id = UUID()
    let dayName: String       // "Seg", "Ter", etc.
    let date: Date
    let workoutCount: Int
    let totalMinutes: Int
    let calories: Int
}

struct WeeklyChartEntry: Identifiable {
    let id = UUID()
    let weekLabel: String     // "Sem 1", "Sem 2", etc.
    let startDate: Date
    let workoutCount: Int
    let totalMinutes: Int
    let calories: Int
}
```

**Modificar `ActivityStatsView`** (em `ActivityTabView.swift`):
- Adicionar `import Charts`
- Conectar ao `ActivityStatsViewModel`
- Substituir cards mock por:
  1. Resumo cards no topo (treinos, calorias, streak) — dados reais
  2. `Chart { BarMark }` para treinos diarios da semana
  3. `Chart { BarMark }` para treinos semanais do mes
- Manter `ActivityStatCard` para os resumos

### Dependencias
- `UserStatsRepository.getCurrentStats()` (existe)
- `WorkoutHistoryRepository.listEntries()` (existe)
- `import Charts` (framework nativo iOS 16+)

---

## Mudanca 3: Ocultar API Key em Producao

### Problema
- `SettingsRow(icon: "key")` visivel para todos os usuarios
- Chave pessoal OpenAI nao deve ser exposta em release

### Solucao

**ProfileProView.swift** (accountSection, ~linha 416-420):
- Envolver o `SettingsRow` + `Divider` da API key em `#if DEBUG`

### Impacto
- Minimo — apenas 4-6 linhas afetadas

---

## Mudanca 4: Conectar Botao Explorar

### Problema
- `ProgramsListView.swift` tem botao "Explorar" com acao vazia (TODO)
- Nao existe rota `explore` no Router
- `LibraryView` ja existe como catalogo de exercicios

### Solucao

**AppRouter.swift**:
- Adicionar `case libraryExplore` ao enum `AppRoute`

**TabRootView.swift**:
- Adicionar case `libraryExplore` no `navigationDestination`
- Destino: `LibraryView()` (ja existe)

**ProgramsListView.swift**:
- No botao "Explorar": `router.push(.libraryExplore, on: .workout)`

### Dependencias
- `LibraryView` (existe em `Features/Library/LibraryView.swift`)
- `AppRouter` routing infrastructure (funcional)

---

## Arquivos Afetados

| Arquivo | Mudanca |
|---------|---------|
| `Activity/Views/ChallengesView.swift` | Wire share button |
| `Groups/Views/GroupsView.swift` | Wire invite button |
| `Activity/Views/ActivityTabView.swift` | Reescrever ActivityStatsView com Charts |
| **NOVO** `Activity/ViewModels/ActivityStatsViewModel.swift` | ViewModel para stats |
| `Pro/ProfileProView.swift` | `#if DEBUG` na API key row |
| `Programs/Views/ProgramsListView.swift` | Conectar botao Explorar |
| `Router/AppRouter.swift` | Adicionar rota libraryExplore |
| `Root/TabRootView.swift` | Adicionar destination libraryExplore |
