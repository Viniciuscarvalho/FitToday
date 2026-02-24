---
description: Common issues and resolution patterns for the FitToday knowledge system
type: manual
generated_from: "arscontexta-v0.8.0"
---

# Troubleshooting

Common problems and how to fix them. Start with the issue that matches your situation.

## Orphan Patterns

**Symptom:** Patterns with no incoming links — nothing points to them from domain guides or other patterns.

**Detect:**
```bash
bash ops/queries/orphan-patterns.sh
```
Or: `/graph orphans`

**Fix:**
```
/connect [pattern-name]
```
This finds related patterns and updates domain guides to include the orphan. If no relationships exist, the pattern may be a candidate for the wrong vault or may need to be deleted.

**Prevention:** Always run `/connect` after `/extract`. The extraction pipeline chains to connect automatically when `processing.chaining` is set to `suggested` or `automatic`.

---

## Dangling Links

**Symptom:** A wiki link `[[pattern-name]]` points to a file that doesn't exist. Usually happens after renaming or deleting a pattern.

**Detect:**
```
/arscontexta:health
```
The health check includes a dangling-links pass.

**Fix:** Either:
1. Restore the missing pattern (check if it was accidentally deleted)
2. Find the new name and update the link
3. Remove the link if the referenced pattern no longer exists

**Prevention:** When renaming a pattern file, search for all references first:
```bash
grep -r "[[old-pattern-name]]" patterns/ ops/ self/
```
Update all references before renaming.

---

## Stale Patterns

**Symptom:** Patterns that are >30 days old with fewer than 2 outgoing links. These are often underconnected or were created before the surrounding knowledge existed.

**Detect:**
```bash
bash ops/queries/stale-patterns.sh
```

**Fix:**
```
/update [stale-pattern-name]
```
The update skill revisits old patterns, looks for newer related content, and adds connections. It also considers whether the pattern should be sharpened or split.

**Why this matters:** An isolated pattern is hard to discover. An iOS insight that connects to nothing won't surface when you need it. Link density is how the knowledge graph pays off.

---

## Missing Descriptions

**Symptom:** Patterns with no `description:` field or an empty description.

**Detect:**
```bash
bash ops/queries/missing-description.sh
```

**Fix:**
```
/verify [pattern-name]
```
Verify runs the cold-read test — it tries to predict what's in the pattern from the title alone. If it can't, that gap is your description.

**What a good description looks like:**
- Title: `observable-eliminates-manual-objectwill-change.md`
- Bad description: "Notes on @Observable"
- Good description: "@Observable in iOS 17 removes the need for ObservableObject and eliminates manual objectWillChange publisher calls, simplifying ViewModel implementation"

The description adds context beyond the title. It answers: why does this matter? When does it apply? What problem does it solve?

---

## Inbox Overflow

**Symptom:** `captures/` has accumulated many files and none are being processed.

**Detect:** Session-orient shows high captures count. Or: `ls captures/ | wc -l`

**Fix:**
```
/ralph 5     # process 5 items from the queue
/ralph 10    # or process more at once
```

If items aren't in the queue yet (they were dropped into `captures/` but not seeded):
```
/seed captures/[filename]   # seed one at a time
```

Or manually seed multiple:
```
/tasks        # check current queue state
/seed captures/file1.md
/seed captures/file2.md
/ralph 5
```

**Prevention:** Set a personal rule — don't let `captures/` grow past 5 files. The session-orient hook will warn you when it does.

---

## Pipeline Stalls

**Symptom:** Tasks are in the queue (`/tasks` shows pending items) but nothing is being processed.

**Fix:**
1. Check the queue directly:
   ```
   /tasks
   ```
2. If tasks are stuck in `in_progress` from a previous interrupted session, manually reset them:
   Look in `ops/queue/queue.json` for items with `status: in_progress` and change them to `status: pending`.
3. Run `/ralph` to process pending items.

---

## Methodology Drift

**Symptom:** The system is doing things differently than the methodology specifies, or skipping steps that should be mandatory. Common signs: extractions getting shallower over time, connections becoming less thorough, descriptions getting shorter.

**Detect:**
```
/rethink drift
```

**Fix:**
1. Run `/rethink` to triage accumulated observations and tensions
2. Review proposals — approve the ones that address the drift
3. Approved directives land in `ops/methodology/` and become canonical spec
4. If drift is structural (e.g., wrong dimension settings), use `/arscontexta:architect` for a research-backed fix

**Prevention:** Run `/remember` when you notice the system deviating from what you want. Don't wait for drift to accumulate — capture it as an observation in the moment.

---

## Skill Not Found After Setup

**Symptom:** After running `/setup`, skills like `/extract` or `/connect` aren't recognized.

**Cause:** Claude Code's skill index doesn't refresh mid-session. Skills created during `/setup` aren't available until Claude Code is restarted.

**Fix:** Quit and restart Claude Code. The skill index refreshes on startup.

---

## Schema Validation Warnings on New Patterns

**Symptom:** The `validate-note.sh` hook shows warnings after creating a pattern.

**What the hook checks:**
1. YAML frontmatter exists (file starts with `---`)
2. `description:` field is present and non-empty
3. `type:` field is one of the valid types: `architecture|swiftui|concurrency|standards|testing|debugging|build-deploy|moc|methodology`

**Fix:** Edit the pattern to add or correct the flagged field. Warnings are non-blocking — the write succeeds, but the pattern is flagged for cleanup.

---

## Common Mistakes

| Mistake | Correction |
|---------|------------|
| Creating a pattern without a `type:` field | Add `type: [architecture\|swiftui\|concurrency\|standards\|testing\|debugging\|build-deploy]` |
| Writing the description as a restatement of the title | Write what's significant, not what's obvious |
| Putting multiple insights in one pattern | Split into separate atomic patterns |
| Dropping sources in `captures/` without seeding | Run `/seed captures/[file]` to register with the queue |
| Linking to a pattern by filename instead of `[[wiki-link]]` syntax | Use `[[pattern-name]]` without the `.md` extension |
| Editing `ops/derivation.md` manually | derivation.md is an append-only record; let /rethink and /architect update it |

## See Also

- [[meta-skills]] — /rethink and /remember for drift and evolution
- [[configuration]] — Adjusting thresholds and pipeline behavior

---

Topics:
- [[manual]]
