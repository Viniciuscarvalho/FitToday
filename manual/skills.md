---
description: Complete reference for every available command in the FitToday knowledge system
type: manual
generated_from: "arscontexta-v0.8.0"
---

# Skills

All commands use `/skill-name` syntax. Plugin commands use `/arscontexta:command-name`. Sixteen generated skills are available after restarting Claude Code.

## Processing Skills

These are the core pipeline — they transform raw source material into connected knowledge.

### /extract `[file]`
**Extract structured iOS/Swift patterns from source material.**

Mines a source for architecture decisions, SwiftUI patterns, concurrency patterns, standards, testing patterns, debugging insights, and build/deploy knowledge. Comprehensive extraction is the default — if the source is iOS/Swift relevant, skip rate should be under 10%.

```
/extract captures/wwdc-state-of-swiftui.md
/extract captures/architecture-decision-record.md
```

After extracting: runs `/verify` on each new pattern, then chains to `/connect` to build relationships.

### /connect `[pattern]`
**Find connections between patterns and update domain guides.**

Analyzes one or all patterns to find genuine relationships — not surface-level keyword matches, but conceptual dependencies, contrasts, and reinforcements. Updates domain guides (architecture.md, swiftui.md, etc.) with new entries.

```
/connect patterns/observable-removes-objectwill-change.md
/connect all
```

### /update `[pattern]`
**Update old patterns with new connections (the backward pass).**

Revisits existing patterns that predate newer related content. Adds connections, sharpens claims, considers whether a pattern should be split into two. The backward pass that `/connect` doesn't do by default.

```
/update patterns/combine-publisher-pattern.md
```

### /verify `[pattern]`
**Combined quality gate: cold-read test + schema check + health review.**

Three passes: (1) recite — can you predict what's in the pattern from the title alone? (2) validate — does the schema comply with the template? (3) review — is the description non-empty and meaningful?

```
/verify patterns/async-let-parallel-binding.md
/verify all
```

### /validate `[pattern]`
**Schema-only validation against domain templates.**

Non-blocking — warns but doesn't prevent writes. Use when you only want to check schema compliance, not full quality.

```
/validate patterns/swiftui-list-performance.md
/validate all
```

## Orchestration Skills

These coordinate the pipeline and manage work at scale.

### /seed `[file]`
**Add a source to the processing queue.**

Checks for duplicates, creates an archive folder, moves the source from `captures/`, creates an extract task, and updates `ops/queue/queue.json`. Entry point for the queue pipeline.

```
/seed captures/apple-concurrency-guide.pdf
```

### /ralph `[N]`
**Queue processing with fresh context per phase.**

Processes N tasks from the queue using isolated subagents — prevents context contamination across sources. Supports serial, parallel, batch, and dry-run modes.

```
/ralph 5
/ralph 10 --parallel
/ralph --dry-run
```

### /pipeline `[file]`
**End-to-end source processing in one command.**

Seed → extract → connect → update → verify → archive. The full pipeline for a single source.

```
/pipeline captures/swiftdata-migration-notes.md
```

### /tasks
**View and manage the task stack and processing queue.**

Shows pending work, active tasks, completed items, and queue state. Use to understand what the system is working on.

```
/tasks
/tasks pending
```

## Navigation Skills

These help you orient and find your next action.

### /next
**Surface the most valuable next action.**

Combines task stack, queue pressure, captures count, vault health, and active goals to recommend one specific action with rationale.

```
/next
```

### /stats
**Vault statistics and knowledge graph metrics.**

Shows pattern count, type distribution, link density, captures waiting, queue depth, and session history.

```
/stats
```

### /graph `[query]`
**Knowledge graph analysis.**

Routes natural language questions to graph scripts in `ops/queries/`. Interprets results and suggests concrete actions.

```
/graph health
/graph orphans
/graph "find cross-domain connections"
/graph "what swiftui patterns are stale"
```

## Growth Skills

### /learn `[topic]`
**Research a topic and grow your knowledge graph.**

Uses Exa deep researcher (or web search fallback) to investigate a topic. Files results to `captures/` with full provenance, then chains to `/extract`.

```
/learn "Swift 6 concurrency migration"
/learn "SwiftUI performance best practices 2025"
```

### /remember `[description]`
**Capture friction as methodology notes.**

Three modes:
- **Explicit**: `/remember I've been repeating the actor isolation check — make it a default step in /extract`
- **Contextual**: `/remember` with no args reviews recent conversation for corrections
- **Session mining**: `/remember --mine-sessions` scans unprocessed session transcripts

Writes to `ops/methodology/` as canonical directives. Rule Zero: methodology notes are spec, not incident reports.

```
/remember "always check for MainActor isolation when extracting concurrency patterns"
/remember --mine-sessions
```

## Evolution Skills

### /rethink
**Challenge system assumptions against accumulated evidence.**

Triages observations in `ops/observations/` and tensions in `ops/tensions/`. Detects methodology drift. Generates proposals for system improvements. NEVER auto-implements — all proposals require approval.

Run when: observation count ≥ 10, tension count ≥ 5, or when the system feels misaligned with your workflow.

```
/rethink
/rethink drift
/rethink --focus voice
```

### /refactor
**Plan vault restructuring from config changes.**

Compares `ops/config.yaml` against `ops/derivation.md` to identify dimension shifts. Shows a restructuring plan with affected skills and folders. Executes only on explicit approval.

```
/refactor --dry-run
/refactor
```

## Plugin Commands

These are always available via the arscontexta plugin (no restart required).

| Command | Purpose |
|---------|---------|
| `/arscontexta:help` | Contextual command discovery |
| `/arscontexta:health` | Run vault health diagnostics (8 categories) |
| `/arscontexta:ask [question]` | Query research knowledge base for methodology guidance |
| `/arscontexta:architect` | Research-backed evolution advice |
| `/arscontexta:tutorial` | Interactive walkthrough for new users |
| `/arscontexta:upgrade` | Check for methodology improvements |
| `/arscontexta:reseed` | Re-derive system from first principles |
| `/arscontexta:add-domain` | Add a new knowledge domain |
| `/arscontexta:recommend` | Get architecture recommendations |
| `/arscontexta:setup` | Re-run setup (generates new vaults) |

## See Also

- [[workflows]] — How skills chain together in the pipeline
- [[meta-skills]] — Deep guide to /arscontexta:ask, /arscontexta:architect, /rethink, /remember

---

Topics:
- [[manual]]
