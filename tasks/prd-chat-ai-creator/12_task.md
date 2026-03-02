# Task 12.0: AI Chat Usage Tracking (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Add daily chat message counting to the AIUsageTracking protocol and SimpleAIUsageTracker, separate from workout generation tracking.

<requirements>
- New methods on AIUsageTracking protocol: dailyChatUsageCount(), registerChatUsage()
- Separate UserDefaults keys from workout tracking
- Daily reset at midnight
- Add aiChat handling in FeatureGatingUseCase
</requirements>

## Subtasks

- [ ] 12.1 Find and update `AIUsageTracking` protocol:
  - Add `func dailyChatUsageCount() -> Int`
  - Add `func registerChatUsage()`
- [ ] 12.2 Update `SimpleAIUsageTracker` implementation:
  - Add UserDefaults keys for chat: `"ai_chat_daily_count"`, `"ai_chat_last_date"`
  - `dailyChatUsageCount()`: return count if same day, 0 if new day
  - `registerChatUsage()`: increment count, update date
- [ ] 12.3 Update `FeatureGatingUseCase.swift`:
  - Add `case .aiChat` handling in `checkAccess(to:)` method
  - Use `usageTracker.dailyChatUsageCount()` for usage count
- [ ] 12.4 Write tests:
  - Test: dailyChatUsageCount increments on registerChatUsage
  - Test: count resets on new day (mock date)

## Implementation Details

- **Pattern**: Follow existing `dailyAIUsageCount()` / `registerAIUsage()` pattern
- **Key difference**: Chat uses separate keys from workout generation
- **Reset logic**: Compare date component (day) of last usage with current date

## Success Criteria

- Chat tracking separate from workout tracking
- Daily reset works
- FeatureGatingUseCase handles aiChat
- Tests pass

## Relevant Files
- Search for `AIUsageTracking` protocol and `SimpleAIUsageTracker` implementation
- `Domain/UseCases/FeatureGatingUseCase.swift`

## Dependencies
- Task 11 (ProFeature.aiChat)

## status: pending

<task_context>
<domain>domain</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies>task_11</dependencies>
</task_context>
