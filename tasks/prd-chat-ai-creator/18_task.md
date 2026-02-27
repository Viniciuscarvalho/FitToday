# Task 18.0: Security Audit — API Key + Message Privacy (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Verify that the API key is never logged or exposed, and that chat message content is not sent to analytics.

<requirements>
- API key never in logs, analytics, or error messages
- Message content never sent to analytics/Firebase
- #if DEBUG guards on print statements don't leak key
</requirements>

## Subtasks

- [ ] 18.1 Review `Data/Services/AIChatService.swift`:
  - No API key in print statements or error messages
  - No message content logged
- [ ] 18.2 Review `Data/Services/OpenAI/NewOpenAIClient.swift`:
  - Verify #if DEBUG prints don't include API key
  - Verify error messages don't include key
- [ ] 18.3 Review `Data/Services/OpenAI/UserAPIKeyManager.swift`:
  - Verify Keychain access is properly secured
- [ ] 18.4 Review analytics/Firebase events:
  - No chat message content in any analytics event
  - No API key in any analytics event
- [ ] 18.5 Document findings and fix any issues found

## Success Criteria

- No API key in any log output
- No message content in analytics
- Keychain properly secured (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
- Review documented

## Relevant Files
- `Data/Services/AIChatService.swift`
- `Data/Services/OpenAI/NewOpenAIClient.swift`
- `Data/Services/OpenAI/UserAPIKeyManager.swift`
- Any analytics/Firebase event code

## Dependencies
- Task 5 (refactored AIChatService)

## status: pending

<task_context>
<domain>infra</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies>task_5</dependencies>
</task_context>
