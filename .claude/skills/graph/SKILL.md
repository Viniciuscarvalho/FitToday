---
name: graph
description: Interactive knowledge graph analysis. Routes natural language questions to graph scripts, interprets results in domain vocabulary, and suggests concrete actions. Triggers on "/graph", "/graph health", "/graph triangles", "find synthesis opportunities", "graph analysis".
version: "1.0"
generated_from: "arscontexta-v1.6"
user-invocable: true
context: fork
model: sonnet
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "[operation] [target] — operations: health, triangles, bridges, clusters, hubs, siblings, forward, backward, query"
---

## Runtime Configuration (Step 0 — before any processing)

Read these files to configure domain-specific behavior:

1. **`ops/derivation-manifest.md`** — vocabulary mapping, platform hints
   - Use `vocabulary.notes` for the patterns folder name
   - Use `vocabulary.note` / `vocabulary.note_plural` for pattern type references
   - Use `vocabulary.topic_map` / `vocabulary.topic_map_plural` for domain guide references
   - Use `vocabulary.cmd_reflect` for connection-finding command name
   - Use `vocabulary.cmd_reweave` for backward-pass command name

2. **`ops/config.yaml`** — for graph thresholds (domain guide size limits, orphan thresholds)

If no derivation file exists, use universal terms (patterns, domain guides, etc.).

---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse the operation from arguments:
- If arguments match a known operation: route to that operation
- If arguments are a natural language question: map to the closest operation (see Interactive Mode)
- If no arguments: enter interactive mode

**START NOW.** Route to the appropriate operation.

---

## Philosophy

**The graph IS the knowledge. This skill makes it visible.**

Individual patterns are valuable, but their connections create compound value. /graph reveals the structural properties of those connections — where the graph is dense, where it is sparse, where it is fragile, and where synthesis opportunities hide.

Every operation produces two things: **findings** (what the analysis reveals) and **actions** (what to do about it). Never dump raw data. Always interpret results with pattern descriptions and domain context. Always suggest specific next steps.

---

## Operations

### /graph health

Full graph health report: density, orphans, dangling links, coverage.

**Step 1: Collect raw metrics**

```bash
# Count total patterns (excluding domain guides)
NOTES_DIR="patterns"
TOTAL=$(ls -1 "$NOTES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
MOC_COUNT=$(grep -rl '^type: moc' "$NOTES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
NOTE_COUNT=$((TOTAL - MOC_COUNT))

# Count all wiki links
LINK_COUNT=$(grep -ohP '\[\[[^\]]+\]\]' "$NOTES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')

# Calculate link density
echo "Density: $LINK_COUNT / ($NOTE_COUNT * ($NOTE_COUNT - 1))"

# Find orphan patterns (zero incoming links)
for f in "$NOTES_DIR"/*.md; do
  NAME=$(basename "$f" .md)
  INCOMING=$(grep -rl "\[\[$NAME\]\]" "$NOTES_DIR"/ 2>/dev/null | grep -v "$f" | wc -l | tr -d ' ')
  [[ "$INCOMING" -eq 0 ]] && echo "ORPHAN: $NAME"
done

# Find dangling links (links to non-existent files)
grep -ohP '\[\[([^\]]+)\]\]' "$NOTES_DIR"/*.md 2>/dev/null | sort -u | while read -r link; do
  NAME=$(echo "$link" | sed 's/\[\[//;s/\]\]//')
  [[ ! -f "$NOTES_DIR/$NAME.md" ]] && echo "DANGLING: $NAME"
done

# Domain guide coverage: % of patterns appearing in at least one domain guide
COVERED=0
for f in "$NOTES_DIR"/*.md; do
  NAME=$(basename "$f" .md)
  grep -q '^type: moc' "$f" 2>/dev/null && continue
  if grep -rl '^type: moc' "$NOTES_DIR"/*.md 2>/dev/null | xargs grep -l "\[\[$NAME\]\]" >/dev/null 2>&1; then
    COVERED=$((COVERED + 1))
  fi
done
echo "Coverage: $COVERED / $NOTE_COUNT"
```

If graph helper scripts exist in `ops/scripts/graph/`, use them instead of inline analysis.

**Step 2: Interpret and present**

```
--=={ graph health }==--

  patterns: [N] (plus [M] domain guides)
  Connections: [N] (avg [X] per pattern)
  Graph density: [0.XX]
  Domain guide coverage: [N]% of patterns appear in at least one domain guide

  Orphans ([N]):
    - [[orphan name]] — [description from YAML]
    → Suggestion: Run /connect to find connections

  Dangling Links ([N]):
    - [[missing name]] — referenced from [[source pattern]]
    → Suggestion: Create the pattern or remove the link

  Domain Guide Sizes:
    - [[guide name]]: [N] patterns [OK | WARN: approaching split threshold | WARN: consider merging]

  Overall: [HEALTHY | NEEDS ATTENTION | FRAGMENTED]
```

**Density benchmarks:**

| Density | Interpretation |
|---------|---------------|
| < 0.02 | Sparse — patterns exist but connections are thin |
| 0.02-0.06 | Healthy — growing network with meaningful connections |
| 0.06-0.15 | Dense — well-connected, watch for over-linking |
| > 0.15 | Very dense — verify connections are genuine, not noise |

### /graph triangles

Find synthesis opportunities — open triadic closures where A links to B and A links to C, but B does not link to C.

**Step 1: Build adjacency data**

```bash
for f in "$NOTES_DIR"/*.md; do
  NAME=$(basename "$f" .md)
  LINKS=$(grep -oP '\[\[([^\]]+)\]\]' "$f" 2>/dev/null | sed 's/\[\[//;s/\]\]//' | sort -u)
  echo "FROM:$NAME"
  echo "$LINKS" | while read -r target; do
    [[ -n "$target" ]] && echo "  TO:$target"
  done
done
```

**Step 2: Find open triangles**

For each pattern A with outgoing links to B and C:
1. Check if B links to C (in either direction)
2. Check if C links to B (in either direction)
3. If neither link exists: this is an open triangle (synthesis opportunity)

**Step 3: Evaluate and rank**

For each open triangle:
1. Read descriptions of BOTH unlinked patterns
2. Assess: is there a genuine conceptual relationship that the common parent suggests?
3. Rank by potential value: how surprising and useful would the connection be?

**Step 4: Present top findings**

```
--=={ graph triangles }==--

  Found [N] synthesis opportunities — pairs of patterns that share
  a common reference but do not reference each other:

  1. [[pattern B]] and [[pattern C]]
     Common parent: [[pattern A]]
     B: "[description]"
     C: "[description]"
     → These may benefit from a connection because [specific reasoning]
     → Action: Run /connect on [[pattern B]] to evaluate

  [Show top 10. If more exist: "[N] more triangles found. Show all? (yes/no)"]
```

**Filter out trivial triangles:** Skip pairs where both are in the same domain guide, or where one is a domain guide itself.

### /graph bridges

Identify structurally critical patterns whose removal would disconnect graph regions.

**Step 1: Build adjacency list**

Build a bidirectional adjacency list from all wiki links in patterns/.

**Step 2: Find bridge nodes**

A bridge pattern is one where removing it would split a connected component into two or more components.

**Step 3: Present findings**

```
--=={ graph bridges }==--

  Found [N] bridge patterns — structurally critical nodes whose
  removal would disconnect graph regions:

  1. [[bridge pattern]] — connects [N] patterns on one side to [M] on the other
     Description: "[description]"
     Cluster A: [[pattern1]], [[pattern2]], ...
     Cluster B: [[pattern3]], [[pattern4]], ...
     → Risk: If this pattern becomes stale, [N+M] patterns lose their connection path
     → Action: Consider adding parallel connections between the clusters

  [If no bridges: "No bridge patterns found. The graph has redundant paths between
   all connected regions. This is healthy."]
```

### /graph clusters

Discover connected components and topic boundaries.

**Step 1: Build adjacency list**

Build a bidirectional adjacency list from all wiki links.

**Step 2: Find connected components**

Use BFS/DFS to find all connected components.

**Step 3: Present findings**

```
--=={ graph clusters }==--

  Found [N] connected components:

  Cluster 1: [size] patterns
    Key nodes: [[pattern1]] (8 links), [[pattern2]] (6 links)
    Topics: [[domain-guide A]], [[domain-guide B]]
    Cross-cluster links: [N]
    → This cluster is [well-connected | isolated | a hub]

  Isolated patterns ([N]):
    - [[isolated pattern]] — [description]
    → Action: Run /connect to find connections
```

### /graph hubs

Rank patterns by influence — most-linked-to (authorities) and most-linking-from (hubs).

**Step 1: Count links**

```bash
# Authority score: incoming links per pattern
for f in "$NOTES_DIR"/*.md; do
  NAME=$(basename "$f" .md)
  INCOMING=$(grep -rl "\[\[$NAME\]\]" "$NOTES_DIR"/ 2>/dev/null | grep -v "$f" | wc -l | tr -d ' ')
  echo "AUTH:$INCOMING:$NAME"
done | sort -t: -k2 -rn | head -10

# Hub score: outgoing links per pattern
for f in "$NOTES_DIR"/*.md; do
  NAME=$(basename "$f" .md)
  OUTGOING=$(grep -oP '\[\[[^\]]+\]\]' "$f" 2>/dev/null | wc -l | tr -d ' ')
  echo "HUB:$OUTGOING:$NAME"
done | sort -t: -k2 -rn | head -10
```

**Step 2: Present findings**

```
--=={ graph hubs }==--

  Top Authorities (most-linked-to):
    1. [[pattern]] — [N] incoming links — "[description]"
    ...

  Top Hubs (most-linking-from):
    1. [[pattern]] — [N] outgoing links — "[description]"
    ...

  Synthesizers (high on both — structurally important):
    1. [[pattern]] — [N] in / [M] out — "[description]"
    ...
```

### /graph siblings [[topic]]

Find unconnected patterns within a domain guide.

**Step 1: Read the specified domain guide**

Find and read the domain guide matching the argument. Extract all patterns linked in Core Ideas.

**Step 2: Check pairwise connections**

For each pair of patterns in the domain guide, check if A links to B or B links to A.

**Step 3: Present findings**

```
--=={ graph siblings: [[topic]] }==--

  Domain guide [[topic]] has [N] patterns.
  Found [M] unconnected sibling pairs:

  Likely connections:
    1. [[pattern A]] and [[pattern B]]
       A: "[description]"
       B: "[description]"
       → [Why these likely relate]

  → Action: Run /connect on the "likely" pairs
```

### /graph forward [[pattern]] [depth]

N-hop forward traversal from a pattern. Default depth: 2.

```
--=={ forward traversal: [[pattern]] (depth [N]) }==--

  [[root pattern]] — "[description]"
    ├── [[link 1]] — "[description]"
    │   ├── [[link 1a]] — "[description]"
    │   └── [[link 1b]] — "[description]"
    └── [[link 2]] — "[description]"

  Reached [N] patterns in [depth] hops.
  Dead ends (no outgoing links): [[pattern X]], [[pattern Y]]
  Cycles detected: [[pattern]] → ... → [[pattern]] (skipped)
```

### /graph backward [[pattern]] [depth]

N-hop backward traversal to a pattern. Default depth: 2.

```bash
NAME="[pattern name]"
grep -rl "\[\[$NAME\]\]" "$NOTES_DIR"/*.md 2>/dev/null
```

```
--=={ backward traversal: [[pattern]] (depth [N]) }==--

  [[root pattern]] — "[description]"
    ├── [[referrer 1]] — "[description]"
    │   └── [[referrer 1a]] — "[description]"
    └── [[referrer 2]] — "[description]"

  [N] patterns lead to [[root pattern]] within [depth] hops.
```

### /graph query [field] [value]

Schema-level YAML query across patterns.

```bash
rg "^{field}:.*{value}" "$NOTES_DIR"/*.md -l 2>/dev/null
```

```
--=={ graph query: {field} = {value} }==--

  Found [N] patterns:

  1. [[pattern name]] — "[description]"
  2. [[pattern name]] — "[description]"
  ...
```

---

## Interactive Mode

If no arguments provided, ask: "What would you like to know about your knowledge graph?"

| User Says | Maps To |
|-----------|---------|
| "Where should I look for connections?" | triangles |
| "What are my most important patterns?" | hubs |
| "Are there isolated areas?" | clusters |
| "How healthy is my graph?" | health |
| "What bridges my topics?" | bridges |
| "What connects to [[X]]?" | backward [[X]] |
| "Where does [[X]] lead?" | forward [[X]] |
| "Show me patterns about [topic]" | query topics [[topic]] |
| "What needs connecting in [topic]?" | siblings [[topic]] |

---

## Output Rules

- **Never dump raw data.** Always interpret results with pattern descriptions and context.
- **Always suggest actions.** "Run /connect on these pairs" or "Consider adding a bridge pattern about X."
- **Use domain vocabulary** for all labels and descriptions — pattern, domain guide, etc.
- **For large result sets,** summarize top findings (max 10) and offer to show more.
- **Include density benchmarks** for context.

---

## Edge Cases

### Small Vault (<10 patterns)

Report metrics but contextualize: "With [N] patterns, graph analysis provides limited insight. Graph operations become more valuable as the knowledge graph grows."

### No Graph Scripts Available

If `ops/scripts/graph/` does not exist, implement the analysis inline using grep, file reads, and bash loops as shown in each operation's steps.

### Empty Patterns Directory

Report: "No patterns found in patterns/. Start by capturing content to build your knowledge graph."

### Pattern Not Found (for forward/backward/siblings)

1. Search for partial matches: `ls "$NOTES_DIR"/*{query}*.md 2>/dev/null`
2. If matches found: "Did you mean: [[match1]], [[match2]]?"
3. If no matches: "Pattern '[[name]]' not found. Check the name and try again."
