---
description: SwiftUI patterns for view composition, state management, and navigation in FitToday
type: moc
---

# swiftui

SwiftUI patterns used in FitToday. This guide covers view composition, state management with @Observable and @State, navigation with Router pattern, and component extraction.

## Core Patterns

(Patterns will be added as they are captured and processed)

## Decisions

- Use @Observable over ObservableObject (Swift 6.0+)
- Use @Bindable for bindings to @Observable objects
- Use @State for local view state only
- Prefer Router Navigation Pattern over deprecated NavigationView
- Extract views when they exceed 100 lines

## Open Questions

- Which view composition patterns emerge most frequently?
- How does the Router pattern interact with deep linking?

---

Domains:
- [[index]]
