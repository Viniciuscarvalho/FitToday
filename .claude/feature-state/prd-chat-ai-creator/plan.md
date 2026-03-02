# Implementation Plan — FitOrb AI Chat

See approved plan at: `.claude/plans/melodic-honking-gray.md`

## Execution Order (19 tasks, 7 phases)

### Wave 1 (Parallel): Tasks 1, 4, 6, 11
- T1: ChatRepository + SDChatMessage + Mapper
- T4: sendChat() on NewOpenAIClient
- T6: ChatSystemPromptBuilder
- T11: ProFeature.aiChat

### Wave 2: Tasks 2, 5, 12
- T2: SwiftDataChatRepository
- T5: AIChatService refactor
- T12: Chat usage tracking

### Wave 3: Tasks 3, 7
- T3: Schema + DI registration
- T7: Builder integration + DI update

### Wave 4: Tasks 8, 16
- T8: ErrorPresenting adoption
- T16: Error mapping

### Wave 5: Task 9
- T9: ViewModel persistence + mocks

### Wave 6 (Parallel): Tasks 10, 13, 14
- T10: Typing animation
- T13: Message limit enforcement
- T14: Contextual quick actions

### Wave 7: Task 15
- T15: Localization

### Wave 8: Tasks 17, 18, 19
- T17: Comprehensive tests
- T18: Security audit
- T19: Build verification
