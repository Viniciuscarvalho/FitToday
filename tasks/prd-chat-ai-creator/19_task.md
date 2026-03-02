# Task 19.0: Build Verification + Integration Test (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Final verification that everything compiles, tests pass, and the feature works end-to-end.

<requirements>
- Clean build on simulator
- All tests pass
- No compiler warnings from new code
- SwiftData schema works without migration issues
</requirements>

## Subtasks

- [ ] 19.1 Run full build: `mcp__xcodebuildmcp__build_sim_name_proj`
  - Fix any build errors
  - Fix any new warnings in modified files
- [ ] 19.2 Run full test suite: `mcp__xcodebuildmcp__test_sim_name_proj`
  - All existing tests still pass
  - All new tests pass
- [ ] 19.3 Verify SwiftData schema:
  - App launches without crash
  - SDChatMessage model works (save/load)
- [ ] 19.4 Manual smoke test checklist:
  - [ ] Open FitOrb tab
  - [ ] Send a message
  - [ ] Verify response is personalized (mentions user goal/stats if available)
  - [ ] Close and reopen app — messages persist
  - [ ] Clear chat history
  - [ ] Verify typing animation
  - [ ] Test with no API key — friendly error
  - [ ] Test 6th message as free user — limit reached

## Implementation Details

- Use XcodeBuildMCP tools for build and test
- Fix issues iteratively

## Success Criteria

- Zero build errors
- All tests pass
- Feature works end-to-end
- No regressions

## Relevant Files
- All modified files from tasks 1-18

## Dependencies
- All tasks (final verification)

## status: pending

<task_context>
<domain>infra</domain>
<type>testing</type>
<scope>core_feature</scope>
<complexity>low</complexity>
<dependencies>all</dependencies>
</task_context>
