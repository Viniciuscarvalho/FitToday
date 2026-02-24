---
name: stats
description: Show vault statistics and knowledge graph metrics. Provides a shareable snapshot of vault health, growth, and progress. Triggers on "/stats", "vault stats", "show metrics", "how big is my vault".
version: "1.0"
generated_from: "arscontexta-v1.6"
user-invocable: true
context: fork
model: sonnet
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "[--share] — optional flag for compact shareable output"
---

## Runtime Configuration (Step 0 — before any processing)

Read these files to configure domain-specific behavior:

1. **`ops/derivation-manifest.md`** — vocabulary mapping
   - Use `vocabulary.notes` for the patterns folder name
   - Use `vocabulary.note` / `vocabulary.note_plural` for pattern type references
   - Use `vocabulary.topic_map` / `vocabulary.topic_map_plural` for domain guide references
   - Use `vocabulary.inbox` for the captures folder name

2. **`ops/config.yaml`** — processing depth, automation settings

If no derivation file exists, use universal terms (patterns, domain guides, etc.).

---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- If target contains `--share`: output compact shareable format after full stats
- If target is empty: output full stats display
- If target names a specific category (e.g., "health", "growth", "pipeline"): show only that category

**START NOW.** Collect metrics and present them.

---

## Philosophy

**Make the invisible visible.**

The knowledge graph grows silently. Without metrics, the user cannot tell whether their system is healthy, growing, stagnating, or fragmenting. /stats provides a snapshot that makes growth tangible — numbers that show progress, health indicators that catch problems, and trends that reveal trajectory.

The output should make the user feel informed, not overwhelmed. Metrics are evidence, not judgment. "12 orphans" is a fact. What to DO about it belongs to /graph or /connect.

---

## Step 1: Collect Metrics

Gather all metrics. Run these checks in parallel where possible to minimize latency.

### 1a. Knowledge Graph Metrics

```bash
NOTES_DIR="patterns"

# Pattern count (excluding domain guides)
TOTAL_FILES=$(ls -1 "$NOTES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
MOC_COUNT=$(grep -rl '^type: moc' "$NOTES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
NOTE_COUNT=$((TOTAL_FILES - MOC_COUNT))

# Connection count (all wiki links across patterns/)
LINK_COUNT=$(grep -ohP '\[\[[^\]]+\]\]' "$NOTES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')

# Average connections per pattern
if [[ "$NOTE_COUNT" -gt 0 ]]; then
  AVG_LINKS=$(echo "scale=1; $LINK_COUNT / $NOTE_COUNT" | bc)
else
  AVG_LINKS="0"
fi

# Topic count
TOPIC_COUNT=$(grep -ohP '^\s*-\s*"\[\[([^\]]+)\]\]"' "$NOTES_DIR"/*.md 2>/dev/null | sort -u | wc -l | tr -d ' ')

# Link density
if [[ "$NOTE_COUNT" -gt 1 ]]; then
  POSSIBLE=$((NOTE_COUNT * (NOTE_COUNT - 1)))
  DENSITY=$(echo "scale=4; $LINK_COUNT / $POSSIBLE" | bc)
else
  DENSITY="N/A"
fi
```

### 1b. Health Metrics

```bash
# Orphan count (patterns with zero incoming links)
ORPHAN_COUNT=0
for f in "$NOTES_DIR"/*.md; do
  NAME=$(basename "$f" .md)
  grep -q '^type: moc' "$f" 2>/dev/null && continue
  INCOMING=$(grep -rl "\[\[$NAME\]\]" "$NOTES_DIR"/ 2>/dev/null | grep -v "$f" | wc -l | tr -d ' ')
  [[ "$INCOMING" -eq 0 ]] && ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
done

# Dangling link count
DANGLING_COUNT=$(grep -ohP '\[\[([^\]]+)\]\]' "$NOTES_DIR"/*.md 2>/dev/null | sort -u | while read -r link; do
  NAME=$(echo "$link" | sed 's/\[\[//;s/\]\]//')
  [[ ! -f "$NOTES_DIR/$NAME.md" ]] && echo "$NAME"
done | wc -l | tr -d ' ')

# Schema compliance (% of patterns with required fields: description, topics)
MISSING_DESC=$(grep -rL '^description:' "$NOTES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$TOTAL_FILES" -gt 0 ]]; then
  COMPLIANT=$((TOTAL_FILES - MISSING_DESC))
  COMPLIANCE=$(echo "scale=0; $COMPLIANT * 100 / $TOTAL_FILES" | bc)
else
  COMPLIANCE="N/A"
fi

# Domain guide coverage
COVERED=0
for f in "$NOTES_DIR"/*.md; do
  NAME=$(basename "$f" .md)
  grep -q '^type: moc' "$f" 2>/dev/null && continue
  if grep -rl '^type: moc' "$NOTES_DIR"/*.md 2>/dev/null | xargs grep -l "\[\[$NAME\]\]" >/dev/null 2>&1; then
    COVERED=$((COVERED + 1))
  fi
done
if [[ "$NOTE_COUNT" -gt 0 ]]; then
  COVERAGE=$(echo "scale=0; $COVERED * 100 / $NOTE_COUNT" | bc)
else
  COVERAGE="N/A"
fi
```

### 1c. Pipeline Metrics

```bash
# Inbox items (captures/)
INBOX_COUNT=$(find captures/ -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

# Queue pending
QUEUE_FILE=""
if [[ -f "ops/queue/queue.yaml" ]]; then
  QUEUE_FILE="ops/queue/queue.yaml"
  QUEUE_PENDING=$(grep -c 'status: pending' "$QUEUE_FILE" 2>/dev/null || echo 0)
  QUEUE_DONE=$(grep -c 'status: done' "$QUEUE_FILE" 2>/dev/null || echo 0)
elif [[ -f "ops/queue/queue.json" ]]; then
  QUEUE_FILE="ops/queue/queue.json"
  QUEUE_PENDING=$(grep -c '"status": "pending"' "$QUEUE_FILE" 2>/dev/null || echo 0)
  QUEUE_DONE=$(grep -c '"status": "done"' "$QUEUE_FILE" 2>/dev/null || echo 0)
else
  QUEUE_PENDING=0
  QUEUE_DONE=0
fi

# Processed ratio
TOTAL_CONTENT=$((NOTE_COUNT + INBOX_COUNT))
if [[ "$TOTAL_CONTENT" -gt 0 ]]; then
  PROCESSED_PCT=$(echo "scale=0; $NOTE_COUNT * 100 / $TOTAL_CONTENT" | bc)
else
  PROCESSED_PCT="N/A"
fi
```

### 1d. Growth Metrics

```bash
WEEK_AGO=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d 2>/dev/null)
if [[ -n "$WEEK_AGO" ]]; then
  THIS_WEEK_NOTES=$(grep -rl "^created: " "$NOTES_DIR"/*.md 2>/dev/null | while read -r f; do
    CREATED=$(grep '^created:' "$f" | head -1 | awk '{print $2}')
    [[ "$CREATED" > "$WEEK_AGO" || "$CREATED" == "$WEEK_AGO" ]] && echo "$f"
  done | wc -l | tr -d ' ')
else
  THIS_WEEK_NOTES="?"
fi
```

### 1e. System Metrics

```bash
# Self space
if [[ -d "self/" ]]; then
  SELF_FILES=$(find self/ -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  SELF_STATUS="enabled ($SELF_FILES files)"
else
  SELF_STATUS="disabled"
fi

# Methodology notes
METHODOLOGY_COUNT=$(ls -1 ops/methodology/*.md 2>/dev/null | wc -l | tr -d ' ')

# Observations pending
OBS_PENDING=$(grep -rl '^status: pending' ops/observations/ 2>/dev/null | wc -l | tr -d ' ')

# Tensions pending
TENSION_PENDING=$(grep -rl '^status: open\|^status: pending' ops/tensions/ 2>/dev/null | wc -l | tr -d ' ')

# Sessions captured
SESSION_COUNT=$(ls -1 ops/sessions/*.md 2>/dev/null | wc -l | tr -d ' ')
```

---

## Step 2: Format Output

### Full Output (default)

```
--=={ stats }==--

  Knowledge Graph
  ===============
  Patterns:      [NOTE_COUNT]
  Connections:   [LINK_COUNT] (avg [AVG_LINKS] per pattern)
  Domain Guides: [MOC_COUNT] (covering [COVERAGE]% of patterns)
  Topics:        [TOPIC_COUNT]

  Health
  ======
  Orphans:  [ORPHAN_COUNT]
  Dangling: [DANGLING_COUNT]
  Schema:   [COMPLIANCE]% compliant

  Pipeline
  ========
  Processed:  [==============      ] [PROCESSED_PCT]%
  Captures:   [INBOX_COUNT] items
  Queue:      [QUEUE_PENDING] pending tasks

  Growth
  ======
  This week:    +[THIS_WEEK_NOTES] patterns, +[THIS_WEEK_LINKS] connections
  Graph density: [DENSITY]

  System
  ======
  Self space:      [SELF_STATUS]
  Methodology:     [METHODOLOGY_COUNT] learned patterns
  Observations:    [OBS_PENDING] pending
  Tensions:        [TENSION_PENDING] open
  Sessions:        [SESSION_COUNT] captured

  Generated by Ars Contexta v1.6
```

### Interpretation Notes

| Condition | Note |
|-----------|------|
| ORPHAN_COUNT > 0 | "[N] orphan patterns — run `/graph health` for details" |
| DANGLING_COUNT > 0 | "[N] dangling links — run `/graph health` to identify broken links" |
| COMPLIANCE < 90 | "Schema compliance below 90% — some patterns missing required fields" |
| OBS_PENDING >= 10 | "[N] pending observations — consider running /rethink" |
| TENSION_PENDING >= 5 | "[N] open tensions — consider running /rethink" |
| DENSITY < 0.02 | "Graph density is low — connections are thin. Run /connect to strengthen the network" |
| PROCESSED_PCT < 50 | "More content in captures/ than in patterns/ — consider processing backlog" |

---

## Step 3: Shareable Format (--share flag)

```markdown
## My iOS/Swift Knowledge Graph

- **[NOTE_COUNT]** patterns with **[LINK_COUNT]** connections (avg [AVG_LINKS] per pattern)
- **[MOC_COUNT]** domain guides covering [COVERAGE]% of patterns
- Schema compliance: [COMPLIANCE]%
- This week: +[THIS_WEEK_NOTES] patterns, +[THIS_WEEK_LINKS] connections
- Graph density: [DENSITY]

*Built with [Ars Contexta](https://github.com/arscontexta) v1.6*
```

---

## Step 4: Trend Analysis (when history exists)

If previous /stats runs are logged in `ops/stats-history.yaml`, compare current metrics against the last snapshot:

```
  Trend (vs last check):
    Patterns:    [N] (+[delta] since [date])
    Connections: [N] (+[delta])
    Density:     [N] ([up/down/stable])
    Orphans:     [N] ([improved/worsened/stable])
```

If no history exists, skip trend analysis.

---

## Edge Cases

### Empty Vault (0 patterns)

```
--=={ stats }==--

  Your knowledge graph is new. Start capturing to see it grow.

  Knowledge Graph
  ===============
  Patterns:      0
  Connections:   0
  Domain Guides: 0

  Generated by Ars Contexta v1.6
```

### No Queue System

Skip the Pipeline section entirely.

### No ops/derivation-manifest.md

Use universal vocabulary. All metrics work identically.

### Very Large Vault (500+ patterns)

The orphan and domain guide coverage checks may be slow for large vaults. If patterns/ has >200 files:
1. Run orphan detection with a simpler heuristic
2. Note: "Metrics approximate for large vault. Run /graph health for precise analysis."

### Platform-Specific Date Commands

macOS uses `date -v-7d`, Linux uses `date -d '7 days ago'`. The script tries both. If neither works, report "?" for growth metrics instead of failing.
