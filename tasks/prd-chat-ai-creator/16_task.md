# Task 16.0: Error Mapping for Chat Errors (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Add chat-specific domain errors and ensure all chat error paths produce user-friendly messages.

<requirements>
- New DomainError cases for chat
- ErrorMapper handles all chat errors
- Localized error messages
</requirements>

## Subtasks

- [ ] 16.1 In `Domain/Support/DomainError.swift`:
  - Add `case chatMessageLimitReached`
  - Add `case chatServiceUnavailable`
  - Add localized descriptions for both
- [ ] 16.2 In `Presentation/Infrastructure/ErrorMapper.swift`:
  - Ensure `AIChatService.ServiceError` cases are mapped
  - Ensure `DomainError.chatMessageLimitReached` is mapped
  - Ensure `DomainError.chatServiceUnavailable` is mapped
- [ ] 16.3 Test ErrorMapper with chat error cases

## Implementation Details

- **DomainError pattern**: Follow existing cases like `dailyGenerationLimitReached`
- **ErrorMapper pattern**: Follow existing error type switching

## Success Criteria

- All chat errors produce user-friendly messages
- Messages are localized
- Tests pass

## Relevant Files
- `Domain/Support/DomainError.swift`
- `Presentation/Infrastructure/ErrorMapper.swift`

## Dependencies
- Task 8 (ErrorPresenting adopted)

## status: pending

<task_context>
<domain>domain/presentation</domain>
<type>implementation</type>
<scope>middleware</scope>
<complexity>low</complexity>
<dependencies>task_8</dependencies>
</task_context>
