# Task 11.0: Add ProFeature.aiChat + Limits to EntitlementPolicy (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Register AI Chat as a gated feature in the EntitlementPolicy with 5 messages/day for free users.

<requirements>
- New ProFeature case: aiChat
- Free limit: 5 messages/day
- Pro: unlimited
- Integrated into canAccess, isProOnly, limitedFreeFeatures
</requirements>

## Subtasks

- [ ] 11.1 In `Domain/Entities/EntitlementPolicy.swift`:
  - Add `case aiChat = "ai_chat"` to ProFeature enum
  - Add displayName: `"Assistente IA FitOrb"`
  - Add constant: `static let freeAIChatMessagesPerDay = 5`
  - Add `case .aiChat` to `canAccess()` switch:
    - Pro: always `.allowed`
    - Free: check `usageCount >= freeAIChatMessagesPerDay` -> `.limitReached`
  - Add to `isProOnly()`: return `false` (limited free access)
  - Add to `limitedFreeFeatures`: `(.aiChat, "5/dia", "ilimitado")`
  - Add to `usageLimit(for:entitlement:)`: Free -> (5, "dia"), Pro -> nil
- [ ] 11.2 Update `FitTodayTests/Domain/EntitlementPolicyTests.swift`:
  - Test: free user with 0 usage -> .allowed
  - Test: free user with 5 usage -> .limitReached
  - Test: pro user -> .allowed (always)
  - Test: isProOnly(.aiChat) returns false

## Implementation Details

- **Pattern**: Follow existing `aiWorkoutGeneration` case exactly
- **Daily vs Weekly**: aiChat uses daily limit (unlike aiWorkoutGeneration which is weekly for free)

## Success Criteria

- ProFeature.aiChat compiles
- canAccess returns correct results for all scenarios
- Tests pass
- Project builds

## Relevant Files
- `Domain/Entities/EntitlementPolicy.swift` — sole file to modify (+ test file)

## Dependencies
- None (can run in parallel with earlier phases)

## status: pending

<task_context>
<domain>domain</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies>none</dependencies>
</task_context>
