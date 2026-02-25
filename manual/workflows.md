---
description: Processing pipeline, maintenance cycle, and session rhythm for the FitToday knowledge system
type: manual
generated_from: "arscontexta-v0.8.0"
---

# Workflows

Three workflows drive the system: the processing pipeline (turning sources into patterns), the session rhythm (per-session structure), and the maintenance cycle (keeping the vault healthy over time).

## The Processing Pipeline

The pipeline transforms raw source material into structured, connected iOS/Swift knowledge.

```
Source → captures/ → /seed → /extract → /connect → /update → /verify → patterns/
```

### Stage 1: Capture

Drop source material into `captures/`. This is the zero-friction entry point — no structure required. Articles, WWDC session notes, code snippets, architecture decision records, team docs, anything.

### Stage 2: Seed

Register the source with the queue:

```
/seed captures/swiftdata-migration-notes.md
```

This deduplicates (won't queue the same source twice), creates an archive folder, and adds an extract task to `ops/queue/queue.json`.

### Stage 3: Extract

Pull structured patterns from the source:

```
/extract captures/swiftdata-migration-notes.md
```

The extractor looks for 7 iOS/Swift insight categories:
1. **Architecture decisions** — MVVM patterns, layer boundaries, dependency direction
2. **SwiftUI patterns** — view composition, state management, layout approaches
3. **Concurrency patterns** — async/await, actors, Sendable, task isolation
4. **Standards** — Swift API design, naming conventions, code style
5. **Testing patterns** — unit testing strategies, test doubles, @Observable testing
6. **Debugging insights** — tools, techniques, root-cause patterns
7. **Build/deploy** — SPM configuration, CI/CD, signing, provisioning

Each extracted pattern lands in `patterns/` with a prose-as-title (the insight as a proposition) and required schema fields.

### Stage 4: Connect

Find relationships between new patterns and existing knowledge:

```
/connect patterns/swiftdata-migration-requires-schema-versioning.md
```

This adds wiki links between related patterns and updates domain guides (`patterns/architecture.md`, `patterns/swiftui.md`, etc.) with new entries.

### Stage 5: Update (Backward Pass)

Revisit existing patterns that predate the new content:

```
/update patterns/core-data-migration-approach.md
```

The backward pass adds connections in older patterns that didn't know about newer ones. Run on patterns that are topically related to what you just extracted.

### Stage 6: Verify

Quality gate before a pattern is considered complete:

```
/verify patterns/swiftdata-migration-requires-schema-versioning.md
```

Three checks: can the description be predicted from the title? Does the schema comply with the template? Is the description meaningful and non-empty?

### Running the Full Pipeline

For a single source end-to-end:
```
/pipeline captures/apple-swift-testing-guide.md
```

For processing multiple queued items:
```
/ralph 5        # process 5 items serially
/ralph 10 --parallel  # process 10 with parallel subagents
```

## The Session Rhythm

Every session follows three beats: **Orient → Work → Persist**.

### Orient (Session Start)

The session-orient.sh hook runs automatically on SessionStart. It reads:
- `ops/reminders.md` — surfaces any overdue items
- `ops/queue/queue.json` — shows pending task count
- `captures/` — shows how many sources are waiting
- `ops/observations/` and `ops/tensions/` — alerts if thresholds are crossed (≥10 observations or ≥5 tensions triggers a /rethink recommendation)

After the hook, scan:
1. `ops/tasks.md` — what's pending
2. `self/goals.md` — active threads

Run `/next` if you're unsure where to start. It combines all signals and recommends one specific action.

### Work (The Session)

Follow the task queue or pursue an active goal. Common session patterns:

**Source processing session:**
```
/seed captures/[new-source]
/ralph 3
```

**Connection-building session:**
```
/connect all
/update [stale-pattern]
```

**Learning session:**
```
/learn "Swift 6 migration approach"
```

**Maintenance session:**
```
/arscontexta:health
/verify all
/graph orphans
```

### Persist (Session End)

The session-capture.sh hook runs automatically on Stop. It writes a session record to `ops/sessions/YYYYMMDD-HHMMSS.md` tracking patterns created/modified, queue state, and captures count.

Before stopping:
- Update `self/goals.md` with new threads or completed work
- Capture any friction: `/remember [what went wrong or right]`

## The Maintenance Cycle

Maintenance runs on conditions, not calendar. The system tracks triggers automatically.

| Condition | Action |
|-----------|--------|
| `captures/` has ≥ 5 files | Run `/ralph` to process the backlog |
| Observations ≥ 10 | Run `/rethink` to surface methodology improvements |
| Tensions ≥ 5 | Run `/rethink` to resolve contradictions |
| Pattern is ≥ 30 days old with < 2 links | Run `/update` on that pattern |
| Orphan patterns detected | Run `/connect` to add incoming links |
| Missing descriptions detected | Run `/verify` on flagged patterns |

Run `ops/queries/stale-patterns.sh` from the repo root to see what needs attention. Other query scripts:

```bash
bash ops/queries/type-distribution.sh      # count patterns by type
bash ops/queries/orphan-patterns.sh        # find isolated patterns
bash ops/queries/missing-description.sh    # find incomplete patterns
bash ops/queries/cross-type-connections.sh # find integration points
```

Or use `/graph health` to get an interpreted maintenance report.

## Batch Processing with /ralph

When the queue grows, use `/ralph` to process it efficiently. Each queue item gets its own subagent with fresh context — no contamination between sources.

```
/ralph 5          # process 5 tasks from the queue
/ralph --dry-run  # see what would be processed without doing it
/ralph --filter extract  # process only extract-phase tasks
```

## See Also

- [[skills]] — Command reference for every skill
- [[configuration]] — Tuning pipeline behavior via ops/config.yaml
- [[meta-skills]] — /rethink and /remember for system evolution

---

Topics:
- [[manual]]
