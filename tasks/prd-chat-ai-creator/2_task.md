# Task 2.0: SwiftDataChatRepository Implementation (M)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Implement the ChatRepository protocol using SwiftData, following the existing repository pattern.

<requirements>
- @MainActor final class with @unchecked Sendable
- ModelContainer injected at init
- Fresh ModelContext per operation via context() factory
- All CRUD operations functional
</requirements>

## Subtasks

- [ ] 2.1 Create `Data/Repositories/SwiftDataChatRepository.swift`:
  - `@MainActor final class SwiftDataChatRepository: ChatRepository, @unchecked Sendable`
  - `private let modelContainer: ModelContainer`
  - `private func context() -> ModelContext { ModelContext(modelContainer) }`
  - `loadMessages(limit:)` — FetchDescriptor sorted by timestamp ascending, with fetchLimit
  - `saveMessage(_:)` — insert via ChatMessageMapper.toModel, save context
  - `clearHistory()` — fetch all, delete each, save
  - `messageCount()` — fetchCount
- [ ] 2.2 Write `FitTodayTests/Data/Repositories/SwiftDataChatRepositoryTests.swift`:
  - Use in-memory ModelContainer: `ModelConfiguration(isStoredInMemoryOnly: true)`
  - Test: save and load messages in correct chronological order
  - Test: clearHistory removes all messages
  - Test: messageCount returns accurate count
  - Test: loadMessages respects limit parameter

## Implementation Details

- **Pattern**: Follow `Data/Repositories/SwiftDataWorkoutHistoryRepository.swift` exactly
- **Context**: Always create new ModelContext per operation (never share)
- **Sorting**: `SortDescriptor(\.timestamp, order: .forward)` for chronological

## Success Criteria

- All ChatRepository protocol methods implemented
- Uses ModelContext(modelContainer) pattern
- All 4 repository tests pass
- Project builds successfully

## Relevant Files
- `Data/Repositories/SwiftDataWorkoutHistoryRepository.swift` — pattern reference
- `Data/Repositories/SwiftDataUserStatsRepository.swift` — pattern reference
- `Data/Models/SDChatMessage.swift` — from Task 1
- `Data/Mappers/ChatMessageMapper.swift` — from Task 1

## Dependencies
- Task 1 (ChatRepository protocol, SDChatMessage, ChatMessageMapper)

## status: pending

<task_context>
<domain>data</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_1</dependencies>
</task_context>
