# Task 5.0: Refactor AIChatService to Delegate to NewOpenAIClient (M)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Remove duplicated HTTP logic from AIChatService. Delegate to NewOpenAIClient.sendChat() instead.

<requirements>
- Remove performChatRequest method entirely (lines 89-111)
- Remove direct URLSession.shared usage
- Remove direct UserAPIKeyManager call
- Delegate to client.sendChat(messages:maxTokens:temperature:)
- Keep same public API: sendMessage(_:history:) async throws -> String
</requirements>

## Subtasks

- [ ] 5.1 In `Data/Services/AIChatService.swift`:
  - Remove `performChatRequest(payload:)` method
  - Remove local `ChatCompletionResponse` decoding (it's in NewOpenAIClient)
  - In `sendMessage()`, build messages array as before
  - Call `try await client.sendChat(messages: chatMessages, maxTokens: 1000, temperature: 0.7)`
  - Return the string result directly
  - Keep `ServiceError` enum (clientUnavailable, emptyResponse)
- [ ] 5.2 Update init to accept `NewOpenAIClient` directly instead of resolving from Resolver:
  ```swift
  init(client: NewOpenAIClient) {
      self.client = client
  }
  ```
- [ ] 5.3 Write `FitTodayTests/Data/Services/AIChatServiceTests.swift`:
  - Test: sendMessage calls client with correct messages array
  - Test: empty response from client throws ServiceError.emptyResponse

## Implementation Details

- **Before**: AIChatService calls URLSession.shared directly, reads API key from UserAPIKeyManager
- **After**: AIChatService only calls client.sendChat(), client handles HTTP/auth/retry
- **Init change**: From `init(resolver:)` to `init(client:)` — DI registration updated in Task 7

## Success Criteria

- No URLSession.shared in AIChatService
- No UserAPIKeyManager in AIChatService
- Public API unchanged: `sendMessage(_:history:) async throws -> String`
- Tests pass
- Project builds

## Relevant Files
- `Data/Services/AIChatService.swift` — main file to modify
- `Data/Services/OpenAI/NewOpenAIClient.swift` — dependency (from Task 4)

## Dependencies
- Task 4 (sendChat method on NewOpenAIClient)

## status: pending

<task_context>
<domain>data</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_4</dependencies>
</task_context>
