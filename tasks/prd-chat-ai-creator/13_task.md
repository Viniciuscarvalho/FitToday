# Task 13.0: Enforce Message Limits in ViewModel (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Check feature gating before sending each message and register usage after successful sends.

<requirements>
- Check featureGating.checkAccess(to: .aiChat) before sending
- Show limit reached message with remaining count
- Register usage after successful send
- Pro users never blocked
</requirements>

## Subtasks

- [ ] 13.1 In `Presentation/Features/AIChat/AIChatViewModel.swift`:
  - Add `FeatureGating` dependency (from Resolver)
  - Add `AIUsageTracking` dependency (from Resolver)
  - In `sendMessage()`, before calling service:
    ```swift
    let access = featureGating.checkAccess(to: .aiChat)
    guard access.isAllowed else {
        handleError(DomainError.chatMessageLimitReached)
        return
    }
    ```
  - After successful send, call `usageTracker.registerChatUsage()`
- [ ] 13.2 Add remaining messages indicator (optional computed property):
  ```swift
  var remainingMessages: Int? {
      // Only for free users, show 5 - currentCount
  }
  ```
- [ ] 13.3 Add tests to `AIChatViewModelTests.swift`:
  - Test: free user within limit can send message
  - Test: free user at limit gets blocked with error
  - Test: pro user always allowed
  - Test: usage increments after successful send

## Implementation Details

- **FeatureGating**: Already exists as protocol, find its concrete implementation
- **DomainError**: Add `case chatMessageLimitReached` (done in Task 16)
  - For now, use existing `DomainError.dailyGenerationLimitReached` or a temporary error
  - Will be properly mapped in Task 16

## Success Criteria

- Free users blocked after 5 msgs/day
- Pro users never blocked
- Usage tracked after each send
- Tests pass

## Relevant Files
- `Presentation/Features/AIChat/AIChatViewModel.swift` — main modification
- `Domain/UseCases/FeatureGatingUseCase.swift` — gating logic
- `Domain/Entities/EntitlementPolicy.swift` — limits

## Dependencies
- Task 9 (ViewModel with persistence)
- Task 12 (chat usage tracking)

## status: pending

<task_context>
<domain>presentation</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies>task_9,task_12</dependencies>
</task_context>
