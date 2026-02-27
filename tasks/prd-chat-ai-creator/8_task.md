# Task 8.0: Adopt ErrorPresenting in AIChatViewModel (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Replace ad-hoc error handling with the project's standard ErrorPresenting protocol pattern.

<requirements>
- AIChatViewModel conforms to ErrorPresenting
- errorMessage type changes from String? to ErrorMessage?
- handleError() used in catch blocks
- AIChatService.ServiceError mapped in ErrorMapper
- View alert updated to use ErrorMessage
</requirements>

## Subtasks

- [ ] 8.1 In `Presentation/Features/AIChat/AIChatViewModel.swift`:
  - Change `var errorMessage: String?` to `var errorMessage: ErrorMessage?`
  - Add conformance to `ErrorPresenting`
  - Replace `errorMessage = error.localizedDescription` with `handleError(error)`
  - Remove `clearError()` method (ErrorPresenting handles nil-setting)
- [ ] 8.2 In `Presentation/Infrastructure/ErrorMapper.swift`:
  - Add `case let chatError as AIChatService.ServiceError:` handler
  - Map `.clientUnavailable` -> "Configure sua API key nas configuracoes"
  - Map `.emptyResponse` -> "FitOrb nao conseguiu gerar uma resposta"
- [ ] 8.3 In `Presentation/Features/AIChat/AIChatView.swift`:
  - Update `.alert` binding to use `ErrorMessage` model (title + message)
  - Remove any direct `errorMessage` string references

## Implementation Details

- **ErrorPresenting pattern**: See `Presentation/Infrastructure/ErrorPresenting.swift`
- **ErrorMapper pattern**: See `Presentation/Infrastructure/ErrorMapper.swift`
- **View alert pattern**: See how `HomeView` uses `ErrorMessage`-based alerts

## Success Criteria

- AIChatViewModel conforms to ErrorPresenting
- Error alerts show user-friendly mapped messages
- ErrorMapper handles AIChatService.ServiceError
- Project builds

## Relevant Files
- `Presentation/Features/AIChat/AIChatViewModel.swift` — main modification
- `Presentation/Features/AIChat/AIChatView.swift` — alert update
- `Presentation/Infrastructure/ErrorPresenting.swift` — protocol reference
- `Presentation/Infrastructure/ErrorMapper.swift` — mapper to extend

## Dependencies
- Task 7 (updated AIChatService)

## status: pending

<task_context>
<domain>presentation</domain>
<type>implementation</type>
<scope>middleware</scope>
<complexity>low</complexity>
<dependencies>task_7</dependencies>
</task_context>
