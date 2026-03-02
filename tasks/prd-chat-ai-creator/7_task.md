# Task 7.0: Integrate Builder into AIChatService + Update DI (M)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Replace the hardcoded static system prompt in AIChatService with the dynamic ChatSystemPromptBuilder, and update DI registration.

<requirements>
- AIChatService receives repository dependencies
- Dynamic system prompt built from user data
- Cached prompt per session (rebuilt when messages empty)
- Fallback to generic prompt on repository failure
- Updated DI registration in AppContainer
</requirements>

## Subtasks

- [ ] 7.1 Update `Data/Services/AIChatService.swift`:
  - Add dependencies: `UserProfileRepository`, `UserStatsRepository`, `WorkoutHistoryRepository`
  - Update init:
    ```swift
    init(client: NewOpenAIClient,
         profileRepository: UserProfileRepository,
         statsRepository: UserStatsRepository,
         historyRepository: WorkoutHistoryRepository)
    ```
  - Remove static `systemPrompt` string
  - Add `private var cachedSystemPrompt: String?`
  - Add `private func buildContextualPrompt() async -> String`:
    - Load profile, stats, last 3 workouts from repos
    - Use ChatSystemPromptBuilder to build prompt
    - Cache result
    - On any error, return generic prompt
  - In `sendMessage()`, use `await buildContextualPrompt()` for system message
- [ ] 7.2 Update `Presentation/DI/AppContainer.swift` (~line 198):
  ```swift
  if let client = NewOpenAIClient.fromUserKey() {
      container.register(NewOpenAIClient.self) { _ in client }
          .inObjectScope(.container)

      let chatService = AIChatService(
          client: client,
          profileRepository: container.resolve(UserProfileRepository.self)!,
          statsRepository: container.resolve(UserStatsRepository.self)!,
          historyRepository: container.resolve(WorkoutHistoryRepository.self)!
      )
      container.register(AIChatService.self) { _ in chatService }
          .inObjectScope(.container)
  }
  ```
- [ ] 7.3 Update AIChatServiceTests:
  - Test: system prompt contains user goal when profile exists
  - Test: generic prompt when profile is nil

## Implementation Details

- **Caching**: Build prompt once, cache in `cachedSystemPrompt`. Invalidate when messages array is empty (new conversation).
- **Error resilience**: If any repo fails, use `ChatSystemPromptBuilder.buildSystemPrompt(profile: nil, stats: nil, recentWorkouts: [])` as fallback.
- **History limit**: Load only last 3 workouts for context (not full history).

## Success Criteria

- System prompt includes user data
- Falls back gracefully on repo failure
- DI resolves correctly
- Tests pass
- App builds and launches

## Relevant Files
- `Data/Services/AIChatService.swift` — main modification
- `Presentation/DI/AppContainer.swift` — DI update
- `Data/Services/OpenAI/ChatSystemPromptBuilder.swift` — from Task 6

## Dependencies
- Task 5 (refactored AIChatService)
- Task 6 (ChatSystemPromptBuilder)

## status: pending

<task_context>
<domain>data/infra</domain>
<type>integration</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_5,task_6</dependencies>
</task_context>
