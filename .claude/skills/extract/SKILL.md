---
name: extract
description: Extract structured iOS development patterns from source material. Comprehensive extraction is the default — every insight that serves iOS/Swift development gets extracted. For domain-relevant sources, skip rate must be below 10%. Zero extraction from a domain-relevant source is a BUG. Triggers on "/extract", "/extract [file]", "extract patterns", "mine this", "process this source".
version: "1.0"
generated_from: "arscontexta-v0.8.0"
user-invocable: true
allowed-tools: Read, Write, Grep, Glob, mcp__qmd__vector_search
context: fork
---

## Runtime Configuration (Step 0)

Read these files before any processing:

1. **`ops/derivation-manifest.md`** — vocabulary mapping, extraction categories, platform hints
2. **`ops/config.yaml`** — processing depth, pipeline chaining, selectivity

Vocabulary for this vault:
- notes folder: `patterns/`
- inbox folder: `captures/`
- note type: `pattern`
- process verb: `extract`
- next-phase command: `/connect`
- topic map: `domain guide`

---

## THE MISSION

You are the extraction engine for iOS/Swift development knowledge. Raw source material enters. Structured, atomic patterns exit.

**For domain-relevant sources (iOS/Swift/FitToday), COMPREHENSIVE EXTRACTION is the default.**

The 7 extraction categories for this vault:

| Category | What to Find | Output |
|----------|--------------|--------|
| architecture-decisions | Why X over Y, constraints, trade-offs, implications | pattern |
| swiftui-patterns | View composition, state management, navigation, bindings | pattern |
| concurrency-patterns | async/await, actors, @Sendable, task groups, MainActor | pattern |
| standards | Coding conventions, naming rules, project guidelines | pattern |
| testing-patterns | XCTest approaches, mocking, spies, fixtures, coverage | pattern |
| debugging-insights | Solutions to tricky bugs, gotchas, workarounds | pattern |
| build-deploy | App Store, signing, CI/CD, provisioning learnings | pattern |

**INVALID skip reasons (these are BUGS):**
- "validates existing approach" — validations ARE evidence, extract them
- "we already do this" — DOING is not EXPLAINING, extract the WHY
- "obvious" — obvious to whom? Future sessions need explicit reasoning
- "near-duplicate" — near-duplicates almost always add detail, create enrichment task

---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- File path → extract patterns from that file
- `--handoff` → output RALPH HANDOFF block after extraction
- Empty → scan `captures/` for unprocessed items, pick one
- "all" → process all captures sequentially

**Steps:**
1. Read the source file fully
2. Hunt for insights across all 7 extraction categories
3. For each candidate: run semantic duplicate check via `mcp__qmd__vector_search` (collection: `patterns`, limit: 5)
4. Categorize: CLOSED (standalone) or OPEN (needs investigation)
5. Output extraction report by category with counts
6. Wait for user approval before creating files

**Anti-shortcut language:** Do NOT write pattern files until the user approves the extraction report. Never auto-extract.

---

## Pattern Format

```markdown
---
description: [~150 chars elaborating the pattern, adds info beyond title]
type: architecture | swiftui | concurrency | standards | testing | debugging | build-deploy
created: YYYY-MM-DD
applies_to: "FitToday/[Presentation|Domain|Data]/**"
status: active | superseded | experimental
---

# [prose-as-title — the pattern as a claim]

[Body: 150-400 words showing reasoning. Use connectives: because, but, therefore, which means.]

---

Source: [[source filename]]

Relevant Patterns:
- [[related pattern]] — [why it relates: extends, contradicts, grounds]

Domains:
- [[relevant domain guide]]
```

**Title test:** "this pattern argues that [title]" must make sense.
**Context test:** Context must add mechanism or implication, not restate the title.

---

## Quality Gates

Before finalizing:
- [ ] Title passes claim test
- [ ] Context adds new info beyond title
- [ ] Body shows reasoning path
- [ ] At least one domain guide linked
- [ ] Source attribution present

**Skip rate < 10% for domain-relevant sources. Zero extraction = BUG.**

---

## Handoff Mode (--handoff)

When invoked with `--handoff`, create per-pattern task files in `ops/queue/`, update `ops/queue/queue.json`, and output:

```
=== RALPH HANDOFF: extract ===
Target: [source file]
Work Done:
- Extracted N patterns
- Created task files: [list]
Files Modified: [list]
Learnings: [friction | surprise | methodology | NONE]
Queue Updates: [entries added]
=== END HANDOFF ===
```

## Pipeline Chaining

After extraction:
- **manual:** "Next: /connect [created patterns]"
- **suggested:** Output next step AND add to queue with `current_phase: "create"`
- **automatic:** Queue entries created, pipeline continues
