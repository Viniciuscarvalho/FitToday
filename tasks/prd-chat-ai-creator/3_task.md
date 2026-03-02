# Task 3.0: Register SDChatMessage Schema + ChatRepository DI (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Wire the new SwiftData model into the schema and register the ChatRepository in the DI container.

<requirements>
- SDChatMessage added to SwiftData Schema array
- ChatRepository registered in Swinject container as singleton
</requirements>

## Subtasks

- [ ] 3.1 In `Presentation/DI/AppContainer.swift`, add `SDChatMessage.self` to the `Schema([...])` array in `makeModelContainer()` (~line 638)
- [ ] 3.2 In `Presentation/DI/AppContainer.swift`, register ChatRepository:
  ```swift
  container.register(ChatRepository.self) { _ in
      SwiftDataChatRepository(modelContainer: modelContainer)
  }.inObjectScope(.container)
  ```
  Place near the AI Chat Service registration (~line 197)
- [ ] 3.3 Verify app builds and launches without SwiftData migration crash

## Implementation Details

- **Schema**: See `AppContainer.swift` ~line 638 for existing schema array
- **DI**: Follow pattern of other repository registrations with `.inObjectScope(.container)`

## Success Criteria

- SDChatMessage.self in Schema array
- ChatRepository resolves from container
- App builds and launches

## Relevant Files
- `Presentation/DI/AppContainer.swift` — sole file to modify

## Dependencies
- Task 2 (SwiftDataChatRepository)

## status: pending

<task_context>
<domain>infra</domain>
<type>configuration</type>
<scope>configuration</scope>
<complexity>low</complexity>
<dependencies>task_2</dependencies>
</task_context>
