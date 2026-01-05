# Tech Spec — FitToday (MVP)

## Resumo Executivo

O MVP do FitToday será implementado em **SwiftUI + SwiftData**, com **injeção de dependências via Swinject**, e navegação centralizada por um **Router** capaz de interpretar **DeepLinks**. A arquitetura segue três camadas dentro do mesmo target (sem módulos separados): **Domain** (structs + regras + protocolos de repositório + UseCases), **Data** (implementações concretas, DTOs e mappers, persistência e carregamento de JSON), e **Presentation** (Features: Views/ViewModels + camada de aplicação).

A TabBar terá **navegação independente por tab** (cada tab mantém seu próprio `NavigationStack`/`NavigationPath`). A área Pro será habilitada via **StoreKit 2** (assinatura real), com paywall após tentativa de “Gerar treino”.

## Arquitetura do Sistema

### Visão Geral dos Componentes

- **Presentation**
  - `AppRouter`: roteamento, deep links, coordenação de tabs.
  - `TabRootView`: `TabView` com um `NavigationStack` por tab.
  - Features:
    - Onboarding
    - Setup (Questionário inicial)
    - Home
    - Questionário diário
    - Treino (lista + detalhe + execução + conclusão)
    - Biblioteca (Free)
    - Histórico
    - Perfil/Pro (paywall/assinatura/restore)
  - ViewModels:
    - `@MainActor` (UI-bound), chamam UseCases async e expõem estado estável para evitar invalidations excessivas.

- **Domain**
  - Entidades (structs): `UserProfile`, `DailyCheckIn`, `WorkoutPlan`, `Exercise`, `WorkoutSession`, `SubscriptionState`.
  - UseCases:
    - `CreateUserProfileUseCase`
    - `GetUserProfileUseCase`
    - `SaveDailyCheckInUseCase`
    - `GenerateWorkoutPlanUseCase`
    - `StartWorkoutSessionUseCase`
    - `CompleteWorkoutSessionUseCase`
    - `ListWorkoutHistoryUseCase`
    - `GetProEntitlementUseCase`
  - Protocolos de repositório:
    - `UserProfileRepository`
    - `WorkoutHistoryRepository`
    - `WorkoutBlocksRepository`
    - `EntitlementRepository`

- **Data**
  - Persistência local via SwiftData (ex.: perfil, histórico, estado Pro).
  - Carregamento de blocos curados via JSON no bundle.
  - Mappers DTO ↔ Domain:
    - `UserProfileMapper`
    - `WorkoutPlanMapper`
    - `WorkoutHistoryMapper`
  - Implementações concretas:
    - `SwiftDataUserProfileRepository`
    - `SwiftDataWorkoutHistoryRepository`
    - `BundleWorkoutBlocksRepository`
    - `StoreKitEntitlementRepository`

- **Infra/DI**
  - `Swinject.Container` + `Assembly` por feature/infra.
  - Entry point `FitTodayApp` cria container e injeta dependências via environment.

Fluxo (alto nível):
1) Presentation captura ações → 2) chama UseCase no Domain → 3) UseCase usa repositórios → 4) Data persiste/carrega → 5) retorna resultado → 6) ViewModel atualiza estado.

## Design de Implementação

### Interfaces Principais

**Repositórios (Domain)**

```swift
public protocol UserProfileRepository: Sendable {
    func load() async throws -> UserProfile?
    func save(_ profile: UserProfile) async throws
}

public protocol WorkoutBlocksRepository: Sendable {
    func loadBlocks() async throws -> [WorkoutBlock]
}

public protocol WorkoutHistoryRepository: Sendable {
    func list() async throws -> [WorkoutHistoryEntry]
    func save(_ entry: WorkoutHistoryEntry) async throws
}

public protocol EntitlementRepository: Sendable {
    func currentEntitlement() async -> ProEntitlement
    func observeEntitlementChanges() -> AsyncStream<ProEntitlement>
}
```

**Router (Presentation)**

```swift
enum AppTab: Hashable, Sendable { case home, library, history, profile }

enum AppRoute: Hashable, Sendable {
    case onboarding
    case setup
    case dailyQuestionnaire
    case workoutDetail(WorkoutPlan.ID)
    case exerciseDetail(WorkoutPlan.ID, Exercise.ID)
    case paywall
}

protocol AppRouting: AnyObject {
    func select(tab: AppTab)
    func push(_ route: AppRoute, on tab: AppTab?)
    func pop(on tab: AppTab?)
    func handle(deeplink: DeepLink)
}
```

### Modelos de Dados

**Domain (value types / Sendable por padrão)**
- `UserProfile`
  - objetivo, estrutura, metodologia, nível, condições de saúde, frequência
- `DailyCheckIn`
  - foco do dia, nível de dor, (opcional) região
- `WorkoutBlock`
  - id, grupo, nível, equipamentos compatíveis, exercícios (IDs/nomes), tags
- `WorkoutPlan`
  - id, título, duração estimada, intensidade, lista de `ExercisePrescription`
- `WorkoutHistoryEntry`
  - data, tipo, status (concluído/pulado), referência ao plano
- `ProEntitlement`
  - `isPro: Bool`, `source`, `expirationDate?`

**SwiftData (Data layer)**
- Modelos persistidos:
  - `SDUserProfile`
  - `SDWorkoutHistoryEntry`
  - `SDProEntitlementSnapshot` (cache local do estado Pro)

### Endpoints de API

Não aplicável no MVP (sem backend). Integração com OpenAI, se habilitada, será via HTTP e ficará isolada atrás de um protocolo `WorkoutPlanComposer`.

## Pontos de Integração

- **StoreKit 2 (assinaturas)**
  - Compra, restore, observação de transações.
  - Estado Pro propagado para o app via `EntitlementRepository` (AsyncStream).
- **DeepLinks**
  - Suporte a `fittoday://...` para abrir telas específicas (ex.: paywall, treino do dia).
- (Opcional) **OpenAI**
  - Apenas via interface; com validação de saída para garantir “somente blocos fornecidos”.

## Abordagem de Testes

### Testes Unitários

- UseCases do Domain:
  - `GenerateWorkoutPlanUseCase` (garante que apenas blocos existentes são usados)
  - Ajuste por dor (redução de volume/intensidade)
  - Persistência do perfil e histórico via repos fake/in-memory
- Repositórios (Data):
  - Mappers DTO↔Domain
  - Loader de JSON (valida schema e fallback)
- StoreKit:
  - Testar com StoreKit Testing (config file) e mocks do repositório de entitlement quando possível.

### Testes de UI

Fluxos críticos:
- Onboarding → setup → Home
- Questionário diário → paywall (Free) → compra Pro → gerar treino
- Navegação por TabBar mantendo stacks independentes
- Histórico registra sessão

## Sequenciamento de Desenvolvimento

### Ordem de Construção

1. Fundação: estrutura de diretórios, DI com Swinject, Router/DeepLinks e TabBar com stacks independentes.
2. Domain: modelos, protocolos e UseCases principais.
3. Data: SwiftData models + repos concretos + loader JSON.
4. Design System + componentes SwiftUI base (inspirado no kit; respeitando HIG).
5. Features em sequência: onboarding/setup → home → diário → treino → histórico → biblioteca.
6. StoreKit 2: paywall + compra/restore + observação de entitlements + gating.
7. Testes + auditoria de performance e acessibilidade.

### Dependências Técnicas

- Adicionar dependência SPM: **Swinject**.
- iOS 17+ (para SwiftData). Se precisar iOS 16-, reavaliar persistência.
- StoreKit Test Configuration para simular assinaturas.

## Considerações Técnicas

### Decisões Principais

- **Sem módulos separados**: manter no mesmo target, mas impor limites por camada (Domain não importa SwiftUI/SwiftData).
- **Swinject para DI**: container único no app, assemblies por feature/infra.
- **Router central**: reduz acoplamento entre Views e navegação, facilita deep links e “independent stacks per tab”.
- **SwiftData**: persistência local simples e eficiente para MVP.
- **Concurrency**:
  - ViewModels anotados com `@MainActor`.
  - Repositórios `Sendable` e operações async.
  - Evitar trabalho pesado no `body` (pré-computar, cache e identities estáveis).

### Riscos Conhecidos

- StoreKit 2: estados de assinatura/transações podem ser fonte de bugs; mitigação via StoreKit Testing e observação contínua.
- Performance SwiftUI: listas e imagens podem gerar invalidações; mitigação seguindo guidelines do audit (identidade estável, sem computação pesada no `body`).
- DeepLinks + Router: risco de rotas inconsistentes entre tabs; mitigação com testes de UI e roteamento centralizado.

### Requisitos Especiais

- **Performance**
  - Identidade estável para listas (`ForEach`) e modelos.
  - Evitar formatters e sorting no `body`.
- **Acessibilidade**
  - Touch targets ≥ 44pt, contraste adequado, suporte a Dynamic Type quando possível.

### Conformidade com Padrões

- Skills aplicadas:
  - `@.cursor/skills/swift-concurrency-expert/`
  - `@.cursor/skills/swiftui-performance-audit/`
  - `@.cursor/skills/ios-development-skill/`
  - `@.cursor/skills/design/`

### Arquivos relevantes

- App atual:
  - `FitToday/FitToday/FitTodayApp.swift`
  - `FitToday/FitToday/ContentView.swift`
  - `FitToday/FitToday/Item.swift`
- Templates:
  - `templates/prd-template.md`
  - `templates/techspec-template.md`
  - `templates/tasks-template.md`
  - `templates/task-template.md`



