# Task 9.0: Integrate ChatRepository in ViewModel + View Updates (M)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Wire ChatRepository into AIChatViewModel for persistent chat history, and update the View to load history and support clear functionality.

<requirements>
- ViewModel loads persisted messages on appear
- User and assistant messages saved after each exchange
- Clear history function works
- View calls loadHistory on appear
- Clear chat button in toolbar
</requirements>

## Subtasks

- [ ] 9.1 In `Presentation/Features/AIChat/AIChatViewModel.swift`:
  - Add `private let chatRepository: ChatRepository?` (resolved from Resolver)
  - Add `func loadHistory() async`:
    - Load last 50 messages from chatRepository
    - Populate `messages` array
    - Handle errors via `handleError()`
  - In `sendMessage()`:
    - After creating user message, save to repo: `try? await chatRepository?.saveMessage(userMessage)`
    - After receiving assistant response, save to repo: `try? await chatRepository?.saveMessage(assistantMessage)`
  - Add `func clearHistory() async`:
    - Clear `messages` array
    - Call `try? await chatRepository?.clearHistory()`
- [ ] 9.2 Update init to resolve ChatRepository:
  ```swift
  init(resolver: Resolver) {
      self.chatRepository = resolver.resolve(ChatRepository.self)
      self.chatService = resolver.resolve(AIChatService.self)
      // ...existing init code
  }
  ```
- [ ] 9.3 In `Presentation/Features/AIChat/AIChatView.swift`:
  - Add `.task { await viewModel.loadHistory() }` on the body
  - Add toolbar button (trash icon) that calls `viewModel.clearHistory()`
  - Add confirmation dialog before clearing
- [ ] 9.4 Create test mocks and fixtures:
  - `FitTodayTests/Mocks/MockChatRepository.swift`
  - `FitTodayTests/Mocks/MockAIChatService.swift`
  - `FitTodayTests/Fixtures/AIChatFixtures.swift`
- [ ] 9.5 Write `FitTodayTests/Presentation/Features/AIChatViewModelTests.swift`:
  - Test: loadHistory populates messages from repository
  - Test: sendMessage saves both user and assistant messages to repo
  - Test: clearHistory empties messages and calls repo clear
  - Test: error handling shows ErrorMessage

## Implementation Details

- **Mock pattern**: Follow `FitTodayTests/Mocks/MockSocialRepositories.swift`
  - `@unchecked Sendable` with spy/stub properties
- **Fixture pattern**: Follow `FitTodayTests/Fixtures/WorkoutCompositionFixtures.swift`
  - Namespace `enum` with static sample messages
- **View pattern**: `.task {}` for async loading (not `.onAppear`)
- **Toolbar**: Use `.toolbar { ToolbarItem(placement: .topBarTrailing) { ... } }`

## Success Criteria

- Messages persist between view dismissals
- Messages load on view appear
- Clear history works with confirmation
- All 4 ViewModel tests pass
- Project builds

## Relevant Files
- `Presentation/Features/AIChat/AIChatViewModel.swift` — main modification
- `Presentation/Features/AIChat/AIChatView.swift` — view updates
- `FitTodayTests/Mocks/MockSocialRepositories.swift` — mock pattern
- `FitTodayTests/Fixtures/WorkoutCompositionFixtures.swift` — fixture pattern

## Dependencies
- Task 3 (ChatRepository registered in DI)
- Task 8 (ErrorPresenting adopted)

## status: pending

<task_context>
<domain>presentation</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_3,task_8</dependencies>
</task_context>
