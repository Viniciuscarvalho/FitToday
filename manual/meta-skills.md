---
description: Deep guide to /arscontexta:ask, /arscontexta:architect, /rethink, and /remember
type: manual
generated_from: "arscontexta-v0.8.0"
---

# Meta-Skills

Meta-skills are the system's self-awareness layer. Where processing skills transform knowledge, meta-skills maintain the system itself — capturing friction, detecting drift, and evolving the methodology.

## /arscontexta:ask

**Query the bundled research knowledge graph.**

The Ars Contexta plugin includes a knowledge base of PKM/TFT research backing every design decision in your system. Use `/ask` to interrogate that research directly.

```
/arscontexta:ask why does atomic granularity require heavier processing?
/arscontexta:ask how should I handle patterns that are too large to be atomic?
/arscontexta:ask what is the failure mode for heavy processing without maintenance?
/arscontexta:ask how do domain guides differ from tags in a flat vault?
```

The knowledge base is organized into three tiers:
- **WHY** — Research claims with citations explaining the reasoning behind methodology choices
- **HOW** — Guidance documents for applying methodology in practice
- **WHAT IT LOOKS LIKE** — Domain examples showing methodology in action

Results include specific claim citations so you can trace the reasoning chain. Use `/ask` when you're unsure why the system is configured a certain way, or when you want to understand the trade-offs before changing something.

`/ask` also searches your local `ops/methodology/` folder and surfaces any relevant directives from `/remember` sessions.

## /arscontexta:architect

**Research-backed evolution advice.**

Where `/ask` answers questions, `/architect` proposes changes. It analyzes your vault's current state and friction history to suggest specific structural improvements.

```
/arscontexta:architect
```

The architect workflow:
1. Reads `ops/config.yaml`, `ops/derivation.md`, and recent health reports
2. Scans `ops/observations/` and `ops/tensions/` for accumulated friction signals
3. Cross-references against the research knowledge base
4. Proposes specific changes with justification
5. Shows exactly what would change — dimension positions, affected skills, folder impacts
6. Waits for your approval before implementing anything

Use `/arscontexta:architect` when:
- Multiple observations point to the same problem (3+ in same category)
- A health check reveals a systemic issue, not a one-off
- You want to change the system's architecture, not just a config value
- You've been using the system for a while and want a structured review

**Important:** The architect proposes — it never auto-implements. You review, adjust, and approve each proposal.

## /rethink

**Challenge system assumptions against accumulated evidence.**

While `/arscontexta:architect` looks at structural changes, `/rethink` focuses on methodology drift — the gradual gap between what the methodology specifies and what actually happens in practice.

```
/rethink
/rethink drift
/rethink --focus extraction
```

Six phases:

**Phase 0 — Drift check.** Compares current behavior against methodology spec in `ops/methodology/`. If the system is doing things the methodology doesn't specify, or not doing things it requires, drift is flagged.

**Phase 1 — Triage.** Reviews all observations in `ops/observations/` and tensions in `ops/tensions/`. Categorizes by theme (processing, capture, connection, maintenance, voice, behavior, quality).

**Phase 2 — Methodology folder updates.** Any confirmed directives become methodology notes in `ops/methodology/`. These are canonical spec going forward.

**Phase 3 — Pattern detection.** Looks for recurring themes across observations. Three observations in the same category suggest a systemic issue, not a one-off.

**Phase 4 — Proposal generation.** Creates specific proposals for methodology changes, skill updates, or config adjustments.

**Phase 5 — Present for approval.** Shows all proposals. NEVER auto-implements. You approve, modify, or reject each one.

Run `/rethink` when the session-orient hook shows ≥10 observations or ≥5 tensions. The hook will surface this recommendation automatically.

## /remember

**Capture friction as methodology notes.**

`/remember` is the input side of the evolution loop — the way you tell the system what's working and what isn't. Every `/remember` call eventually becomes a directive in `ops/methodology/`.

Three modes:

### Explicit mode

```
/remember always check for MainActor isolation when extracting concurrency patterns
/remember the description field should describe the significance, not restate the title
/remember when a source is a WWDC session, extract the session metadata as provenance
```

Use explicit mode when you notice something in the moment — a step you keep forgetting, a pattern the extractor misses, a quality issue you've seen twice.

### Contextual mode

```
/remember
```

With no arguments, `/remember` reviews the current conversation for corrections, clarifications, and explicit methodology feedback you've given. It synthesizes these into methodology notes without requiring you to restate them.

Use contextual mode at the end of a session where you gave a lot of feedback inline.

### Session mining mode

```
/remember --mine-sessions
```

Scans unprocessed session transcripts in `ops/sessions/` (where `mined: false` in frontmatter) for implicit feedback signals. Surfaces patterns across multiple sessions that you may not have noticed individually.

### Rule Zero

Methodology notes written by `/remember` are **canonical spec** — they override ad-hoc behavior. When the methodology says "always check for MainActor isolation," the system must check, not just remember. Write directives, not incident reports:

- "I should remember to check X" ❌
- "Always check X when Y" ✓

## How Meta-Skills Relate

The evolution loop:

```
/remember → ops/observations/ → /rethink → ops/methodology/ → CLAUDE.md
                                              ↑
                               /arscontexta:architect (structural changes)
```

1. Friction accumulates in `ops/observations/` via `/remember`
2. `/rethink` triages, detects patterns, proposes methodology updates
3. Approved updates land in `ops/methodology/` as canonical spec
4. CLAUDE.md references `ops/methodology/` — the system evolves
5. For structural changes (dimension shifts, skill regeneration), `/arscontexta:architect` takes over

## See Also

- [[configuration]] — ops/config.yaml and dimension settings
- [[workflows]] — How maintenance triggers connect to meta-skills
- [[troubleshooting]] — Drift detection and recovery

---

Topics:
- [[manual]]
