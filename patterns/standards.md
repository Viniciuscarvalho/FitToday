---
description: Coding standards — Swift style, naming conventions, project rules for FitToday
type: moc
---

# standards

Coding standards and conventions for FitToday. This guide captures the rules from CLAUDE.md and patterns that emerge from development practice.

## Core Standards

- Use Swift 6 strict concurrency
- Follow Apple's Swift API Design Guidelines
- Use guard for early exits
- Prefer value types (structs) over reference types (classes)
- No force unwrapping (!) without justification
- No deprecated APIs (UIKit when SwiftUI suffices)
- No massive monolithic views
- Ignore Swift 6 concurrency warnings is NOT acceptable

## DO NOT

- Write UITests during scaffolding phase
- Use deprecated APIs
- Create massive monolithic views
- Use force unwrapping without justification
- Ignore Swift 6 concurrency warnings

## Open Questions

- Which standards create the most friction during development?
- What new standards emerge as the project matures?

---

Domains:
- [[index]]
