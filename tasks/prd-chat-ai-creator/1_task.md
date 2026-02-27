# Task 1.0: ChatRepository Protocol + SDChatMessage Model + Mapper (M)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Create the full persistence foundation: domain protocol, SwiftData model, and bidirectional mapper for chat messages.

<requirements>
- ChatRepository protocol with Sendable conformance
- SDChatMessage SwiftData model with @Attribute(.unique) on id
- ChatMessageMapper with toDomain/toModel static methods
- Follow existing repository/model/mapper patterns exactly
</requirements>

## Subtasks

- [ ] 1.1 Create `Domain/Protocols/ChatRepository.swift` with protocol:
  ```swift
  protocol ChatRepository: Sendable {
      func loadMessages(limit: Int) async throws -> [AIChatMessage]
      func saveMessage(_ message: AIChatMessage) async throws
      func clearHistory() async throws
      func messageCount() async throws -> Int
  }
  ```
- [ ] 1.2 Create `Data/Models/SDChatMessage.swift` with `@Model final class`:
  - `@Attribute(.unique) var id: UUID`
  - `var roleRaw: String` (stores "user", "assistant", "system")
  - `var content: String`
  - `var timestamp: Date`
- [ ] 1.3 Create `Data/Mappers/ChatMessageMapper.swift`:
  - `static func toDomain(_ model: SDChatMessage) -> AIChatMessage?` (nil for invalid role)
  - `static func toModel(_ message: AIChatMessage) -> SDChatMessage`
- [ ] 1.4 Write `FitTodayTests/Data/Mappers/ChatMessageMapperTests.swift`:
  - Test valid role mapping (user/assistant/system)
  - Test nil return for unknown role string

## Implementation Details

- **Protocol pattern**: Follow `Domain/Protocols/Repositories.swift:10-13` (UserProfileRepository)
- **Model pattern**: Follow `Data/Models/SDUserStats.swift`
- **Mapper pattern**: Follow `Data/Mappers/UserStatsMapper.swift`
- **AIChatMessage entity**: Already exists at `Domain/Entities/AIChatMessage.swift` with Role enum

## Success Criteria

- Protocol compiles with Sendable conformance
- SDChatMessage has @Attribute(.unique) on id
- Mapper handles all 3 roles correctly
- Mapper returns nil for invalid roleRaw
- Mapper tests pass
- Project builds successfully

## Relevant Files
- `Domain/Protocols/Repositories.swift` — pattern reference
- `Data/Models/SDUserStats.swift` — model pattern reference
- `Data/Mappers/UserStatsMapper.swift` — mapper pattern reference
- `Domain/Entities/AIChatMessage.swift` — existing domain entity

## Dependencies
- None (first task)

## status: pending

<task_context>
<domain>data/domain</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>none</dependencies>
</task_context>
