# Task 4.0: Add sendChat() to NewOpenAIClient (M)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Add a generic chat completion method to NewOpenAIClient that accepts a messages array, reusing existing retry logic and session management.

<requirements>
- New public method sendChat(messages:maxTokens:temperature:)
- Reuses existing apiKey, session, retry logic
- Returns content string from first choice
- Does NOT use response_format: json_object (that's workout-specific)
</requirements>

## Subtasks

- [ ] 4.1 In `Data/Services/OpenAI/NewOpenAIClient.swift`, add:
  ```swift
  func sendChat(
      messages: [[String: String]],
      maxTokens: Int = 1000,
      temperature: Double = 0.7
  ) async throws -> String
  ```
  - Build URLRequest with same auth headers pattern as `performRequest`
  - Payload: model, messages, max_tokens, temperature (NO response_format)
  - Retry loop same as `generateWorkout` (up to maxRetries)
  - Decode via existing `ChatCompletionResponse`
  - Return content string, throw `ClientError.emptyWorkoutResponse` renamed or new case if empty
- [ ] 4.2 Add `ClientError.emptyChatResponse` case if needed (or reuse existing)
- [ ] 4.3 Write `FitTodayTests/Data/Services/OpenAI/NewOpenAIClientChatTests.swift`:
  - Test: sendChat builds correct payload structure
  - Test: throws on empty response content

## Implementation Details

- **File**: `Data/Services/OpenAI/NewOpenAIClient.swift`
- **Reuse**: Same `session`, `apiKey`, `baseURL`, retry pattern as `generateWorkout`
- **Difference from generateWorkout**: accepts messages array, no json_object format, returns String not Data
- **ChatCompletionResponse** already exists at line 187

## Success Criteria

- sendChat method compiles and works
- Reuses retry logic (not duplicated)
- Returns String content from API
- Tests pass
- Existing generateWorkout tests still pass

## Relevant Files
- `Data/Services/OpenAI/NewOpenAIClient.swift` — sole file to modify (+ new test file)

## Dependencies
- None (can run in parallel with Tasks 1-3)

## status: pending

<task_context>
<domain>data</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>none</dependencies>
</task_context>
