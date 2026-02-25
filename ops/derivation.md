---
description: How this knowledge system was derived -- enables architect and reseed commands
created: 2026-02-23
engine_version: "1.0.0"
---

# System Derivation

## Configuration Dimensions

| Dimension | Position | Conversation Signal | Confidence |
|-----------|----------|--------------------|--------------------|
| Granularity | Moderate | "architectural decisions, patterns, standards" -- per-pattern notes | High |
| Organization | Flat | Default -- flat with domain guide MOCs | Inferred |
| Linking | Explicit+implicit | Cross-domain connections needed (concurrency affects architecture, SwiftUI references standards) | High |
| Processing | Heavy | "recursive for continuous learning", "countless skills to learn and follow" | High |
| Navigation | 3-tier | Multiple domain areas: SwiftUI, Concurrency, Architecture, Testing, Standards, Build & Deploy | High |
| Maintenance | Condition-based | "decisions to be made as the project grows" + fast-evolving iOS/Swift ecosystem | High |
| Schema | Moderate | Structured enough for queries (pattern type, applies-to, status) but not bureaucratic | High |
| Automation | Full | Claude Code platform + existing skills/agents ecosystem + "recursive learning" goal | High |

## Personality Dimensions

| Dimension | Position | Signal |
|-----------|----------|--------|
| Warmth | clinical | Technical domain, professional register |
| Opinionatedness | neutral | default |
| Formality | formal | Professional/technical context |
| Emotional Awareness | task-focused | Purely technical domain |

## Vocabulary Mapping

| Universal Term | Domain Term | Category |
|---------------|-------------|----------|
| notes | patterns | folder |
| inbox | captures | folder |
| archive | archived | folder |
| note (type) | pattern | note type |
| note_plural | patterns | note type |
| reduce | extract | process phase |
| reflect | connect | process phase |
| reweave | update | process phase |
| verify | verify | process phase |
| validate | validate | process phase |
| rethink | rethink | process phase |
| MOC | domain guide | navigation |
| topic_map | domain guide | navigation |
| hub | hub | navigation |
| description | context | schema field |
| topics | domains | schema field |
| relevant_notes | related patterns | schema field |
| cmd_reduce | /extract | command |
| cmd_reflect | /connect | command |
| cmd_reweave | /update | command |
| cmd_verify | /verify | command |
| cmd_rethink | /rethink | command |
| orient | review status | session phase |
| persist | save progress | session phase |
| processing / pipeline | development pipeline | process |
| wiki link | connection | linking |
| thinking notes | patterns | note type |
| self/ space | dev mind | space |

## Platform

- Tier: Claude Code
- Automation level: full
- Automation: full (default)

## Active Feature Blocks

- [x] wiki-links -- always included (kernel)
- [x] atomic-notes -- moderate granularity benefits from composability principles
- [x] mocs -- 3-tier navigation for multiple domain areas
- [x] processing-pipeline -- heavy processing, full automation
- [x] semantic-search -- explicit+implicit linking requires semantic discovery
- [x] schema -- moderate schema, structured enough for queries
- [x] maintenance -- always included
- [x] self-evolution -- always included
- [x] methodology-knowledge -- always included
- [x] session-rhythm -- always included
- [x] templates -- always included
- [x] ethical-guardrails -- always included
- [x] helper-functions -- always included
- [x] graph-analysis -- always included
- [x] self-space -- agent project context persistence across sessions
- [ ] personality -- disabled (neutral-helpful default for technical domain)
- [ ] multi-domain -- single project (FitToday)

## Coherence Validation Results

- Hard constraints checked: 3. Violations: none
- Soft constraints checked: 7. Auto-adjusted: none. User-confirmed: none
- Compensating mechanisms active: none needed

## Failure Mode Risks

1. **Productivity Porn (HIGH)** -- spending more time organizing patterns than writing code
2. **Temporal Staleness (HIGH)** -- iOS and Swift evolve fast; patterns need freshness checks
3. **Collector's Fallacy (HIGH)** -- capturing patterns without processing or connecting them
4. **Schema Erosion (medium)** -- skipping fields over time degrades query reliability

## Generation Parameters

- Folder names: patterns/, captures/, archived/, self/, ops/, templates/, manual/
- Skills to generate: all 16 -- vocabulary-transformed for iOS development
- Hooks to generate: session-orient, session-capture, validate-note, auto-commit
- Templates to create: pattern-note.md, domain-guide.md, source-capture.md, observation.md
- Topology: single-agent with fresh-context skills

## Extraction Categories

1. **architecture-decisions** -- Why X over Y, constraints, implications → pattern
2. **swiftui-patterns** -- View composition, state management, navigation → pattern
3. **concurrency-patterns** -- async/await, actors, sendable, task groups → pattern
4. **standards** -- Coding standards, naming conventions, project rules → pattern
5. **testing-patterns** -- XCTest approaches, mocking, fixtures → pattern
6. **debugging-insights** -- Solutions to tricky bugs, gotchas → pattern
7. **build-deploy** -- App Store, signing, CI/CD learnings → pattern

## Skills Integration

Project-level skills:
- swift-concurrency (with 13 reference files)

Global skills (iOS-relevant):
- swift-expert, swiftui-expert-skill, swift-testing, swift-testing-expert
- swift-code-reviewer-skill, xcodebuildmcp-cli
- asc-build-lifecycle, asc-cli-usage, asc-release-flow, asc-signing-setup
- asc-submission-health, asc-testflight-orchestration, asc-xcode-build

Global agents (iOS-relevant):
- architect, system-architect, staff-engineer
- swift-expert, swift-reviewer, swiftui-specialist, mobile-developer
- code-reviewer, senior-code-reviewer, code-refactor
