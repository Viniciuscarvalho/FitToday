---
description: Why each configuration dimension was chosen — the reasoning behind initial system setup for iOS development
category: derivation-rationale
created: 2026-02-23
status: active
---

# derivation rationale for iOS development

This knowledge system was derived for an iOS developer working on FitToday, an iOS 17+ SwiftUI fitness application. The developer needs to track architectural decisions, SwiftUI patterns, concurrency patterns, coding standards, and testing approaches — knowledge that grows as the project evolves.

## Key Dimension Choices

**Granularity: Moderate.** Per-pattern notes rather than atomic claims. An architecture decision includes its rationale, alternatives considered, and implications — decomposing this into separate files would fragment the context that makes the decision useful. Each pattern stands alone as a discrete, linkable unit.

**Processing: Heavy.** The developer explicitly requested "recursive continuous learning." This means a full processing pipeline: extract patterns from development sessions, connect them across domains (concurrency affects architecture, SwiftUI patterns reference standards), update old patterns when Swift or iOS evolves, and verify quality.

**Linking: Explicit + Implicit.** Cross-domain connections are the core value. A concurrency pattern constrains architecture decisions. A SwiftUI view composition technique affects testing approaches. Semantic search helps find these connections even when different vocabulary is used across domains.

**Navigation: 3-tier.** Six domain areas (SwiftUI, Concurrency, Architecture, Testing, Standards, Build & Deploy) each have enough depth to warrant their own domain guide. Hub → domain guides → individual patterns.

**Automation: Full.** The developer operates on Claude Code with an extensive skills and agents ecosystem (28+ global skills, 25 agents, project-level swift-concurrency skill). Full automation leverages this existing infrastructure.

**Self-space: Enabled.** Agent project context persistence across sessions is valuable — the agent needs to remember FitToday's architecture, current development threads, and accumulated operational wisdom.

## Platform

Claude Code with full hook support. XcodeBuildMCP integration for builds and tests. Extensive existing skill and agent ecosystem that the vault integrates with rather than duplicates.

## Coherence Validation

All hard constraints passed. No soft constraint violations detected. The configuration is coherent: moderate granularity with heavy processing and full automation is a well-supported combination.

---

Topics:
- [[methodology]]
