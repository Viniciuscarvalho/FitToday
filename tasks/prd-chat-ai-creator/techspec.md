# Technical Specification

**Project Name:** FitOrb AI Chat - Integracao Completa
**Version:** 1.0
**Date:** 2026-02-27
**Author:** FitToday Team
**Status:** Approved

---

## Overview

### Problem Statement
AIChatService duplica logica HTTP do NewOpenAIClient, sem reuso de retry/session. System prompt e estatico. Mensagens sao in-memory. Nao ha gating freemium nem contexto do usuario.

### Proposed Solution
Refatorar camada de servico, adicionar persistencia via SwiftData, construir prompt contextualizado, e integrar gating via EntitlementPolicy existente.

### Goals
- Eliminar duplicacao HTTP entre AIChatService e NewOpenAIClient
- Persistir historico de chat via SwiftData
- Personalizar system prompt com dados reais do usuario
- Adicionar gating de 5 msgs/dia para free

---

## Scope

### In Scope
- ChatRepository protocol + SwiftData implementation
- SDChatMessage model + ChatMessageMapper
- Refatoracao AIChatService -> NewOpenAIClient
- ChatSystemPromptBuilder com contexto do usuario
- Typing effect simulado (sem SSE)
- ProFeature.aiChat + usage tracking
- ErrorPresenting no ViewModel
- Localizacao EN + PT-BR

### Out of Scope
- Streaming SSE real
- Suporte a Anthropic/Claude
- Analise de refeicoes com foto
- Push notifications

---

## Requirements

### Functional Requirements

#### FR-001: Chat Persistence [MUST]
SwiftData-backed repository para historico de mensagens com load/save/clear/count.

**Acceptance Criteria:**
- Ultimas 50 mensagens carregam ao abrir
- Mensagens persistem entre sessoes

#### FR-002: Personalized System Prompt [MUST]
Builder que injeta UserProfile, UserStats e ultimos WorkoutHistoryEntry no prompt.

**Acceptance Criteria:**
- Prompt inclui dados reais quando disponiveis
- Fallback generico quando repositorios falham

#### FR-003: Service Consolidation [MUST]
AIChatService delega a NewOpenAIClient.sendChat() ao inves de URLSession.shared direto.

**Acceptance Criteria:**
- performChatRequest removido
- Retry logic herdada

#### FR-004: Freemium Gating [MUST]
5 msgs/dia free, ilimitado Pro, via EntitlementPolicy + AIUsageTracking existentes.

**Acceptance Criteria:**
- 6a mensagem bloqueada com CTA Pro
- Contador separado de workout generation

### Non-Functional Requirements

#### NFR-001: Performance [MUST]
Carregamento de 50 mensagens em < 200ms. Prompt builder < 50ms.

#### NFR-002: Security [MUST]
API key em Keychain, nunca em logs. Mensagens nao enviadas a analytics.

#### NFR-003: Test Coverage [MUST]
70%+ ViewModel, 80%+ PromptBuilder, 70%+ Repository.

---

## Technical Approach

### Architecture Overview

```
AIChatView
    |
    v
AIChatViewModel (@MainActor @Observable, ErrorPresenting)
    |
    +-- AIChatService (actor)
    |       +-- NewOpenAIClient (actor, retry, session)
    |       +-- ChatSystemPromptBuilder (struct, Sendable)
    |       +-- UserProfileRepository
    |       +-- UserStatsRepository
    |       +-- WorkoutHistoryRepository
    |
    +-- ChatRepository (protocol)
    |       +-- SwiftDataChatRepository (@MainActor)
    |               +-- SDChatMessage (@Model)
    |               +-- ChatMessageMapper (struct)
    |
    +-- FeatureGating (protocol)
            +-- EntitlementPolicy
            +-- AIUsageTracking
```

### Key Technologies
- **SwiftData**: Persistencia local de mensagens
- **Swinject**: Injecao de dependencia
- **URLSession**: Comunicacao HTTP com OpenAI (via NewOpenAIClient)

### Components

#### Component 1: NewOpenAIClient (Extension)
**Purpose:** Adicionar metodo `sendChat()` generico para conversacao.

**New Method:**
```swift
func sendChat(
    messages: [[String: String]],
    maxTokens: Int = 1000,
    temperature: Double = 0.7
) async throws -> String
```

**Responsibilities:**
- Reusar `session`, `apiKey`, retry logic existentes
- Construir payload com messages array
- Decodificar ChatCompletionResponse e retornar content string

**File:** `Data/Services/OpenAI/NewOpenAIClient.swift`

---

#### Component 2: AIChatService (Refactored)
**Purpose:** Orquestrar chat com prompt contextualizado.

**New Dependencies:**
- `NewOpenAIClient` (injetado)
- `UserProfileRepository`, `UserStatsRepository`, `WorkoutHistoryRepository`
- `ChatSystemPromptBuilder` (criado internamente)

**Responsibilities:**
- Construir system prompt via builder com dados dos repositorios
- Montar array de mensagens (system + history + user)
- Delegar a `client.sendChat()`
- Cache do system prompt por sessao

**File:** `Data/Services/AIChatService.swift`

---

#### Component 3: ChatSystemPromptBuilder
**Purpose:** Construir prompt personalizado com contexto do usuario.

**Interface:**
```swift
struct ChatSystemPromptBuilder: Sendable {
    func buildSystemPrompt(
        profile: UserProfile?,
        stats: UserStats?,
        recentWorkouts: [WorkoutHistoryEntry]
    ) -> String
}
```

**Sections:**
1. `basePersonality()` — Persona FitOrb (motivador, direto, cientifico)
2. `userProfileSection()` — Objetivo, nivel, equipamento, condicoes
3. `userStatsSection()` — Streak, treinos/semana, calorias
4. `recentWorkoutsSection()` — Ultimos 3 treinos (titulo, foco, duracao)
5. `responseGuidelines()` — Responder em PT-BR, ser conciso, usar markdown

**File:** `Data/Services/OpenAI/ChatSystemPromptBuilder.swift`

---

#### Component 4: Chat Persistence Layer
**Protocol:** `ChatRepository` in `Domain/Protocols/ChatRepository.swift`
**Model:** `SDChatMessage` in `Data/Models/SDChatMessage.swift`
**Mapper:** `ChatMessageMapper` in `Data/Mappers/ChatMessageMapper.swift`
**Impl:** `SwiftDataChatRepository` in `Data/Repositories/SwiftDataChatRepository.swift`

**SDChatMessage Schema:**
```swift
@Model final class SDChatMessage {
    @Attribute(.unique) var id: UUID
    var roleRaw: String   // "user", "assistant", "system"
    var content: String
    var timestamp: Date
}
```

---

#### Component 5: Freemium Gating
**Files:**
- `Domain/Entities/EntitlementPolicy.swift` — Add `ProFeature.aiChat`
- `Domain/UseCases/FeatureGatingUseCase.swift` — Add `aiChat` handling
- `AIUsageTracking` protocol — Add `dailyChatUsageCount()`, `registerChatUsage()`

**Limits:**
- Free: `freeAIChatMessagesPerDay = 5`
- Pro: Unlimited

---

### Data Model

#### Entity: AIChatMessage (existing, Domain)
```swift
struct AIChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let role: Role           // .user, .assistant, .system
    let content: String
    let timestamp: Date
}
```

#### Entity: SDChatMessage (new, SwiftData)
```swift
@Model final class SDChatMessage {
    @Attribute(.unique) var id: UUID
    var roleRaw: String
    var content: String
    var timestamp: Date
}
```

---

## Implementation Considerations

### Design Patterns
- **Repository Pattern**: ChatRepository protocol + SwiftData implementation (same as all repos)
- **Actor Isolation**: AIChatService stays `actor`, NewOpenAIClient stays `actor`
- **Builder Pattern**: ChatSystemPromptBuilder builds prompt from sections
- **ErrorPresenting**: ViewModel conforms to protocol, uses ErrorMapper

### Error Handling
- `AIChatService.ServiceError` cases mapped in `ErrorMapper`
- `DomainError.chatMessageLimitReached` for gating
- Fallback to generic prompt on repository failures (never crash)

### Configuration Management
- API key via Keychain (UserAPIKeyManager) — BYOK model
- No .xcconfig files, no environment variables in production
- Secrets.plist for debug bootstrapping only (gitignored)

---

## Testing Strategy

### Unit Testing
**Coverage Target:** 70% ViewModel, 80% PromptBuilder

**Focus Areas:**
- ChatSystemPromptBuilder: all section combinations
- AIChatViewModel: load/save/clear/send/gating/error
- ChatMessageMapper: bidirectional mapping
- SwiftDataChatRepository: CRUD operations
- EntitlementPolicy: aiChat limits

### Mocks Required
- `MockChatRepository` — spy/stub (saves, loads, clears)
- `MockAIChatService` — spy/stub (sendMessage result)
- `AIChatFixtures` — namespace enum with sample messages

### Test Pattern
```swift
// Given/When/Then with Swinject mock container
func test_sendMessage_savesUserAndAssistantMessages() async {
    // Given
    let mockRepo = MockChatRepository()
    let mockService = MockAIChatService()
    mockService.sendMessageResult = "AI response"
    // When
    await viewModel.sendMessage()
    // Then
    XCTAssertEqual(mockRepo.savedMessages.count, 2)
}
```

---

## Dependencies

### External Dependencies
| Dependency | Version | Purpose | Risk |
|------------|---------|---------|------|
| OpenAI API | v1 | Chat completions (gpt-4o-mini) | Rate limiting, cost |
| Swinject | 2.10.0 | Dependency injection | Low |

### Internal Dependencies
- `NewOpenAIClient` — must support `sendChat()` before AIChatService refactor
- `UserProfileRepository`, `UserStatsRepository`, `WorkoutHistoryRepository` — already registered
- `EntitlementPolicy` + `AIUsageTracking` — extend for chat gating
- `ErrorMapper` — extend for chat errors

---

## Assumptions and Constraints

### Assumptions
1. User provides own OpenAI API key (BYOK)
2. gpt-4o-mini sufficient for chat quality
3. System prompt under 2000 tokens adequate for personalization
4. 50 messages history sufficient for context

### Constraints
1. iOS 17+, Swift 6.0 strict concurrency
2. No external LLM SDK — raw URLSession via NewOpenAIClient
3. All strings via Localizable.strings (PT-BR primary, EN secondary)
4. SwiftData for persistence (no CoreData)

---

## Success Criteria

- [ ] User sends message and receives personalized response with their data
- [ ] Chat history persists between sessions
- [ ] System prompt includes real user data (profile, stats, workouts)
- [ ] No hardcoded strings (all localized)
- [ ] API key never exposed in code or logs
- [ ] Typing indicator functional during response
- [ ] Offline error message adequate
- [ ] Free user blocked after 5 msgs/day
- [ ] All tests passing with target coverage
