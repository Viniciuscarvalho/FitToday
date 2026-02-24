---
name: next
description: Surface the most valuable next action by combining task stack, queue state, inbox pressure, health, and goals. Recommends one specific action with rationale. Triggers on "/next", "what should I do", "what's next".
version: "1.0"
generated_from: "arscontexta-v1.6"
user-invocable: true
context: fork
model: sonnet
allowed-tools: Read, Grep, Glob, Bash
---

## Runtime Configuration (Step 0 — before any processing)

Read these files to configure domain-specific behavior:

1. **`ops/derivation-manifest.md`** — vocabulary mapping, domain context
   - Use `vocabulary.notes` for the patterns folder name
   - Use `vocabulary.inbox` for the captures folder name
   - Use `vocabulary.note` for the pattern type name in output
   - Use `vocabulary.topic_map` for domain guide references
   - Use `vocabulary.cmd_reduce` for extract command
   - Use `vocabulary.cmd_reflect` for connection-finding command
   - Use `vocabulary.cmd_reweave` for backward-pass command
   - Use `vocabulary.rethink` for rethink command name

2. **`ops/config.yaml`** — thresholds, processing preferences
   - `self_evolution.observation_threshold` (default: 10)
   - `self_evolution.tension_threshold` (default: 5)

If these files don't exist, use universal defaults and generic command names.

## EXECUTE NOW

**INVARIANT: /next recommends, it does not execute.** Present one recommendation with rationale. The user decides what to do. This prevents cognitive outsourcing where the system makes all work decisions and the user becomes a rubber stamp.

**Execute these steps IN ORDER:**

---

### Step 1: Read Vocabulary

Read `ops/derivation-manifest.md` (or fall back to `ops/derivation.md`) for domain vocabulary mapping. All output must use domain-native terms.

---

### Step 2: Reconcile Maintenance Queue

Before collecting state, evaluate all maintenance conditions and reconcile the queue.

**Read queue file** (`ops/queue/queue.json` or `ops/queue.yaml`). If `schema_version` < 3, migrate:
- Add `maintenance_conditions` section with default thresholds
- Add `priority` field to existing tasks (default: "pipeline")
- Set `schema_version: 3`

**For each condition in maintenance_conditions:**

1. **Evaluate the condition:**

| Condition | Evaluation Method |
|-----------|------------------|
| orphan_notes | For each pattern in patterns/, count incoming [[links]]. Zero = orphan. |
| dangling_links | Extract all [[links]], verify targets exist as files. Missing = dangling. |
| inbox_pressure | Count *.md in captures/. |
| observation_accumulation | Count status: pending in ops/observations/. |
| tension_accumulation | Count status: pending or open in ops/tensions/. |
| pipeline_stalled | Queue tasks with status: pending unchanged across sessions. |
| unprocessed_sessions | Count files in ops/sessions/ without mined: true. |
| moc_oversize | For each domain guide, count linked patterns. |
| stale_notes | Patterns not modified in 30+ days with < 2 links. |
| low_link_density | Average link count across all patterns. |
| methodology_drift | Compare config.yaml modification time vs newest ops/methodology/ note modification time. |

2. **If condition exceeds threshold AND no pending task with this condition_key exists:**

```bash
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MAINT_MAX=$(jq '[.tasks[] | select(.id | startswith("maint-")) | .id | ltrimstr("maint-") | tonumber] | max // 0' ops/queue/queue.json)
NEXT_MAINT=$((MAINT_MAX + 1))

jq --arg id "maint-$(printf '%03d' $NEXT_MAINT)" \
   --arg priority "{priority}" \
   --arg key "{condition_key}" \
   --arg target "{description}" \
   --arg action "{recommended command}" \
   --arg ts "$TIMESTAMP" \
   '.tasks += [{"id": $id, "type": "maintenance", "priority": $priority, "status": "pending", "condition_key": $key, "target": $target, "action": $action, "auto_generated": true, "created": $ts}]' \
   ops/queue/queue.json > tmp.json && mv tmp.json ops/queue/queue.json
```

---

### Step 3: Collect Vault State

Gather all signals.

| Signal | How to Check | What to Record |
|--------|--------------|----------------|
| **Task stack** | Read `ops/tasks.md` | Top items, open count |
| **Queue state** | Read `ops/queue.yaml` or `ops/queue/queue.json` | Total pending, by phase |
| **Inbox pressure** | Count `*.md` files in captures/ | Count, age of oldest item |
| **Pattern count** | Count `*.md` in patterns/ | Total patterns |
| **Orphan patterns** | For each pattern, grep for `[[filename]]` across all files | Count, first 5 names |
| **Dangling links** | Extract all `[[links]]` from patterns/, verify each target | Count, first 5 targets |
| **Goals** | Read `self/goals.md` | Priority list, active research directions |
| **Observations** | Count files with `status: pending` in `ops/observations/` | Count |
| **Tensions** | Count files with `status: pending` or `status: open` in `ops/tensions/` | Count |
| **Sessions** | Check `ops/sessions/` for files without `mined: true` | Count of unmined sessions |
| **Recent /next** | Read `ops/next-log.md` (if exists) | Previous suggestions to avoid repetition |

**Signal collection commands:**

```bash
# Inbox pressure (captures/)
INBOX_COUNT=$(find captures/ -name "*.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
OLDEST_INBOX=$(find captures/ -name "*.md" -maxdepth 2 -exec stat -f "%m %N" {} \; 2>/dev/null | sort -n | head -1)

# Pattern count
NOTE_COUNT=$(ls -1 patterns/*.md 2>/dev/null | wc -l | tr -d ' ')

# Pending observations
OBS_COUNT=$(grep -rl '^status: pending' ops/observations/ 2>/dev/null | wc -l | tr -d ' ')

# Pending tensions
TENSION_COUNT=$(grep -rl '^status: pending\|^status: open' ops/tensions/ 2>/dev/null | wc -l | tr -d ' ')

# Unmined sessions
SESSION_COUNT=$(grep -rL '^mined: true' ops/sessions/*.md 2>/dev/null | wc -l | tr -d ' ')
```

---

### Step 4: Classify by Consequence Speed

| Speed | Signals | Threshold |
|-------|---------|-----------|
| **Session** | Inbox > 5 items, orphan patterns (any), dangling links (any), 10+ pending observations, 5+ pending tensions, unprocessed sessions > 3 | Immediate |
| **Multi-session** | Pipeline queue backlog > 10, stale patterns > 10, inbox items aging > 7 days, methodology captures > 5 in same category | Soon |
| **Slow** | Health check not run in 14+ days, domain guide oversized (>40 patterns), link density below 2.0 average | Background |

**Threshold rule:** 10+ pending observations OR 5+ pending tensions is ALWAYS session-priority. Recommend /rethink in this case.

**Signal interaction rules:**
- Task stack items ALWAYS override automated recommendations
- Multiple session-priority signals: pick the one with highest impact
- If inbox pressure AND queue backlog: recommend reducing inbox first

---

### Step 5: Generate Recommendation

Select the SINGLE most valuable action. The recommendation must be specific enough to execute immediately.

**Priority cascade:**

#### 1. Task Stack First

If `ops/tasks.md` has open items, recommend from the task stack.

#### 1.5. Session-Priority Maintenance Tasks

Read queue for maintenance tasks with `priority: "session"` and `status: "pending"`.

#### 2. Session-Priority Signals

| Signal | Recommendation | Rationale Template |
|--------|---------------|-------------------|
| Dangling links / orphans | /arscontexta:health or specific fix | "You have [N] orphan patterns invisible to traversal." |
| 10+ observations or 5+ tensions | /rethink | "[N] pending observations have accumulated." |
| Inbox > 5 items | /extract [specific file] | "Your captures folder has [N] items (oldest: [age])." |
| Unprocessed sessions > 3 | /remember --mine-sessions | "[N] sessions have uncaptured friction patterns." |

**When recommending inbox processing:** Choose the specific captures item that aligns best with current goals.

#### 3. Multi-Session Signals

| Signal | Recommendation | Rationale Template |
|--------|---------------|-------------------|
| Queue backlog > 10 | /ralph [N] | "[N] pipeline tasks are pending. Your newest patterns lack connections." |
| Stale patterns > 10 | /update [specific pattern] | "[N] patterns haven't been touched since [date]." |
| Research gaps | /extract [file aligned with goals] | "Your goals mention [topic] but your graph has few patterns there." |

#### 4. Slow Signals

| Signal | Recommendation |
|--------|---------------|
| No recent health check | /arscontexta:health |
| Domain guide oversized | Restructuring suggestion |
| Low link density | /update on lowest-density pattern |

#### 5. Everything Clean

```
next

  All signals healthy.
  Inbox: 0 | Queue: 0 pending | Orphans: 0 | Dangling: 0

  No urgent work detected.

  Suggested: Explore a new direction from goals.md
  or update older patterns to deepen the graph.
```

**Rationale is always mandatory.** Every recommendation must explain:
1. WHY this action over alternatives
2. What DEGRADES if this action is deferred
3. How it connects to goals (if applicable)

---

### Step 6: Deduplicate

Read `ops/next-log.md` (if it exists). Check the last 3 entries.

- If the same recommendation appeared in the last 2 entries, select the next-best action instead
- If the same recommendation is genuinely the highest priority (e.g., inbox pressure keeps growing), add an explicit note about the growing signal

---

### Step 7: Output

```
next

  State:
    Inbox: [count] items (oldest: [age])
    Queue: [count] pending ([phase breakdown])
    Orphans: [count] | Dangling: [count]
    Observations: [count] | Tensions: [count]

  Recommended: [specific command/action]

  Rationale: [2-3 sentences — why this action,
  how it connects to goals, what degrades if deferred]

  After that: [second priority, if relevant]
```

**Command specificity is mandatory.** Recommendations must be concrete invocations:

| Good | Bad |
|------|-----|
| `/extract captures/swift-concurrency.md` | "process some inbox items" |
| `/ralph 5` | "work on the queue" |
| `/rethink` | "review your observations" |
| `/update [[pattern title here]]` | "update some old patterns" |

---

### Step 8: Log the Recommendation

Append to `ops/next-log.md` (create if missing):

```markdown
## YYYY-MM-DD HH:MM

**State:** Inbox: [N] | Patterns: [N] | Orphans: [N] | Dangling: [N] | Stale: [N] | Obs: [N] | Tensions: [N] | Queue: [N]
**Recommended:** [action]
**Rationale:** [one sentence]
**Priority:** session | multi-session | slow
```

---

## Edge Cases

### Empty Vault (0-5 patterns)

```
next

  State:
    Patterns: [N] — early stage vault

  Recommended: Capture or /extract content
  Rationale: Your graph has [N] patterns. At this stage, adding
  content matters more than maintaining structure.
```

### No Goals File

```
  Recommended: Create ops/goals.md or self/goals.md
  Rationale: Without goals, /next can only recommend based on
  automated detection. Goals let the system align recommendations
  with what actually matters to you.
```

### No ops/derivation-manifest.md

Use universal vocabulary. Do not fail — /next should always produce a recommendation.

### Multiple Session-Priority Signals

When several signals are at session priority simultaneously, pick the one that unblocks the most downstream work.

---

## Anti-Patterns

| Anti-Pattern | Why It Is Wrong | What to Do Instead |
|-------------|----------------|-------------------|
| Recommending everything | Overwhelms the user | Pick ONE |
| Vague recommendations | No actionable starting point | Name the specific file or command |
| Ignoring task stack | User-set priorities exist for a reason | Always check ops/tasks.md first |
| Repeating the same rec | Nagging | Deduplicate via next-log.md |
| Cognitive outsourcing | Making all decisions for the user | Recommend and explain — never execute |
