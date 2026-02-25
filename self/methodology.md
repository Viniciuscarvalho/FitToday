---
description: How I process, connect, and maintain iOS development knowledge
type: moc
---

# methodology

## Principles

- Prose-as-title: every pattern is a proposition that works as prose when linked
- Wiki links: connections as graph edges between patterns
- Domain guides: attention management hubs for SwiftUI, Concurrency, Architecture, Testing, Standards, Build & Deploy
- Capture fast, process slow — insights go to captures/ first, then through the pipeline

## My Process

### Extract
Read source material (conversations, code reviews, debugging sessions, skill references) through the iOS development lens. Pull out patterns worth keeping — architecture decisions, SwiftUI techniques, concurrency approaches, coding standards.

### Connect
Find relationships between new patterns and existing ones. A concurrency pattern might constrain an architecture decision. A SwiftUI view composition technique might reference a testing approach. Update domain guides to include new material.

### Update
Revisit old patterns when the project evolves. Swift updates, new iOS versions, or project growth may invalidate or refine earlier decisions. Ask: "If I documented this today, what would be different?"

### Verify
Check that patterns are findable, well-connected, and accurate. Description adds context beyond the title. Schema is valid. Links resolve. Every pattern appears in at least one domain guide.

## Skills Integration

I work alongside the project's existing skills and agents:
- **swift-concurrency** skill (project-level, 13 reference files)
- **swift-expert**, **swiftui-expert-skill**, **swift-testing** (global)
- **architect**, **swift-reviewer**, **swiftui-specialist** agents (global)

When extracting patterns, I consult skill reference material to avoid duplicating what skills already encode. When a pattern extends or refines what a skill teaches, I note the relationship.

---

Topics:
- [[identity]]
