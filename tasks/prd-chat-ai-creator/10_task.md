# Task 10.0: Simulated Typing Animation (ViewModel + View) (M)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Add a simulated typing effect that displays the AI response character-by-character for a premium UX feel, without real SSE streaming.

<requirements>
- Full response received first, then animated character-by-character
- isTyping flag for UI indicator
- ~5 characters per chunk with ~15ms delay
- Message saved to repository only after animation completes
- Animation cancellable if user sends new message
</requirements>

## Subtasks

- [ ] 10.1 In `Presentation/Features/AIChat/AIChatViewModel.swift`:
  - Add `var isTyping: Bool = false`
  - Add `private var typingTask: Task<Void, Never>?`
  - In `sendMessage()` after receiving response:
    1. Create assistant message with empty content, append to messages
    2. Set `isTyping = true`
    3. Start typingTask that iterates through response characters:
       - Update last message's content in chunks (~5 chars)
       - `try? await Task.sleep(nanoseconds: 15_000_000)` between chunks
    4. On completion: set `isTyping = false`, save final message to repo
    5. On cancellation: save partial content to repo
  - Before sending new message, cancel existing typingTask
- [ ] 10.2 In `Presentation/Features/AIChat/AIChatView.swift`:
  - Replace `ProgressView("Thinking...")` with pulsing dot indicator when `isTyping`
  - Message bubble for last assistant message updates as content changes
  - Auto-scroll `.scrollTo(lastMessageId)` during typing animation
- [ ] 10.3 Add tests to `AIChatViewModelTests.swift`:
  - Test: after sendMessage, isTyping becomes true then false
  - Test: final message content matches full response

## Implementation Details

- **AIChatMessage immutability**: Since `AIChatMessage` is a struct with `let content`, you need to replace the last message in the array instead of mutating it. Create new message with updated content each chunk.
- **Chunk size**: `stride(from: 0, to: response.count, by: 5)` for 5-char chunks
- **Task cancellation**: `typingTask?.cancel()` before starting new one

## Success Criteria

- Text appears progressively in the chat bubble
- Pulsing indicator visible during animation
- Auto-scroll follows new content
- Full response saved after animation
- Tests pass

## Relevant Files
- `Presentation/Features/AIChat/AIChatViewModel.swift` — main modification
- `Presentation/Features/AIChat/AIChatView.swift` — UI updates
- `Domain/Entities/AIChatMessage.swift` — message model (immutable)

## Dependencies
- Task 9 (ViewModel with persistence)

## status: pending

<task_context>
<domain>presentation</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>task_9</dependencies>
</task_context>
