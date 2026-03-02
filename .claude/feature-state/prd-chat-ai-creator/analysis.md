# Analysis — FitOrb AI Chat

## Current State
- AIChatView: Full UI (bubbles, chips, orb, input, Pro gating)
- AIChatViewModel: @Observable, in-memory messages, no ErrorPresenting
- AIChatService: actor, direct URLSession (duplicates NewOpenAIClient)
- AIChatMessage: domain entity (id, role, content, timestamp)
- No SwiftData model for chat
- No ChatRepository
- Static generic system prompt

## Gaps Identified
1. No persistence (messages lost on dismiss)
2. Duplicate HTTP logic (bypasses NewOpenAIClient retry/session)
3. No user context in prompt
4. No freemium gating
5. No ErrorPresenting conformance
6. No contextual quick actions

## Architecture Decision
- Keep OpenAI BYOK (gpt-4o-mini)
- Simulated typing (no SSE)
- 5 msgs/day free limit
- Follow all existing patterns (Repository, Mapper, ErrorPresenting, DI)
