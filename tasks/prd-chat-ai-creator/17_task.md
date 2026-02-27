# Task 17.0: Comprehensive Test Suite (L)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create complete test coverage for all new and modified components. Target: 70%+ ViewModel, 80%+ PromptBuilder.

<requirements>
- Mock implementations for all dependencies
- Fixture data for common test scenarios
- Comprehensive ViewModel tests
- PromptBuilder tests for all sections
- Repository tests for all CRUD operations
</requirements>

## Subtasks

- [ ] 17.1 Create `FitTodayTests/Mocks/MockChatRepository.swift`:
  - `loadMessagesResult`, `loadMessagesCalled`
  - `savedMessages: [AIChatMessage]`, `saveMessageCalled`
  - `clearHistoryCalled`
  - `messageCountResult: Int`
- [ ] 17.2 Create `FitTodayTests/Mocks/MockAIChatService.swift`:
  - Mock `actor` or protocol-based mock
  - `sendMessageResult: String`
  - `sendMessageError: Error?`
  - `sendMessageCalled: Bool`
- [ ] 17.3 Create `FitTodayTests/Fixtures/AIChatFixtures.swift`:
  ```swift
  enum AIChatFixtures {
      enum Messages {
          static let userHello = AIChatMessage(role: .user, content: "Ola")
          static let assistantGreeting = AIChatMessage(role: .assistant, content: "Ola! Como posso ajudar?")
          static let systemMessage = AIChatMessage(role: .system, content: "System prompt")
      }
  }
  ```
- [ ] 17.4 Complete `AIChatViewModelTests.swift` with all scenarios:
  - Initial state: empty messages, not loading
  - loadHistory: populates from repository
  - sendMessage: adds user + assistant messages
  - sendMessage: saves both to repository
  - sendMessage: handles service error
  - clearHistory: empties all
  - isChatAvailable: false when no service
  - Message limit: free user blocked
  - Typing: isTyping toggles correctly
- [ ] 17.5 Complete `ChatSystemPromptBuilderTests.swift`:
  - Full profile prompt contains goal, level, equipment
  - Nil profile gives generic prompt
  - Stats section has streak data
  - Recent workouts listed
  - Empty workouts omits section
  - Reasonable output length
- [ ] 17.6 Verify coverage targets met

## Implementation Details

- **Mock pattern**: `@unchecked Sendable` with spy/stub — see `MockSocialRepositories.swift`
- **Fixture pattern**: Namespace `enum` with static properties — see `WorkoutCompositionFixtures.swift`
- **Test naming**: `test_methodName_whenCondition_expectedResult`
- **Async tests**: `@MainActor func test...() async { }`

## Success Criteria

- All tests pass
- 70%+ line coverage on AIChatViewModel
- 80%+ coverage on ChatSystemPromptBuilder
- 70%+ coverage on SwiftDataChatRepository

## Relevant Files
- All test files created in earlier tasks
- `FitTodayTests/Mocks/MockSocialRepositories.swift` — mock pattern
- `FitTodayTests/Fixtures/WorkoutCompositionFixtures.swift` — fixture pattern

## Dependencies
- Tasks 1-16 (all feature implementation complete)

## status: pending

<task_context>
<domain>testing</domain>
<type>testing</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>tasks_1-16</dependencies>
</task_context>
