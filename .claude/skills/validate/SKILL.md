---
name: validate
description: Schema validation for patterns. Checks against domain-specific templates. Validates required fields, enum values, description quality, and link health. Non-blocking — warns but doesn't prevent capture. Triggers on "/validate", "/validate [pattern]", "check schema", "validate pattern", "validate all".
user-invocable: true
allowed-tools: Read, Grep, Glob
context: fork
model: sonnet
---

## Runtime Configuration (Step 0 — before any processing)

Read these files to configure domain-specific behavior:

1. **`ops/derivation-manifest.md`** — vocabulary mapping, platform hints
   - Use `vocabulary.notes` for the notes folder name
   - Use `vocabulary.note` / `vocabulary.note_plural` for note type references
   - Use `vocabulary.topic_map` for domain guide references
   - Use `vocabulary.templates` for the templates folder path

2. **`ops/config.yaml`** — processing depth
   - `processing.depth`: deep | standard | quick

If these files don't exist, use universal defaults.

**Processing depth adaptation:**

| Depth | Validation Behavior |
|-------|---------------------|
| deep | Full schema validation. All checks enabled including composability analysis and cross-reference verification |
| standard | Full validation — all checks enabled |
| quick | Basic schema validation only — required fields, YAML validity, enum values |

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- If target contains a pattern name: validate that specific pattern
- If target contains `--handoff`: output RALPH HANDOFF block at end
- If target is "all" or "patterns": validate all patterns in patterns/ directory
- If target is empty: ask which pattern to validate

**Execute these steps:**

### Step 1: Locate Template

Determine which template applies to the target pattern:

1. Check the pattern's location — patterns in patterns/ use the standard pattern template
2. Check the `type` field in frontmatter — specialized types may have dedicated templates
3. Look for a templates directory (check `templates/` or domain-specific path from derivation manifest)
4. If the template has a `_schema` block, read it — this is the authoritative schema definition

If no template is found, use the default schema checks below.

### Step 2: Read Target Pattern

Read the target pattern's full YAML frontmatter. Parse:
- All YAML fields and their values
- The body content (for link scanning)
- The footer section (for Domains and Relevant Patterns)

### Step 3: Run Schema Checks

Run ALL validation checks. Each check produces PASS, WARN, or FAIL.

**START NOW.**

---

## Schema Checks

### Required Fields (FAIL if missing)

| Check | Rule | How to Verify |
|-------|------|---------------|
| `description` | Must exist and be non-empty | Check YAML frontmatter for `description:` field with non-empty value |
| Domains | Must link to at least one domain guide | Check for `domains:` in YAML or `Domains:` section in footer. Must contain at least one wiki link |

A missing required field is a hard failure. The pattern cannot pass validation without these.

### Description Quality (WARN if weak)

| Check | Rule | How to Verify |
|-------|------|---------------|
| Length | Should be ~50-200 characters | Count characters in description value |
| New information | Must add context beyond the title | Compare description text against filename/title — if semantically equivalent, WARN |
| No trailing period | Convention: descriptions don't end with periods | Check last character |
| Single sentence | Should be one coherent statement | Check for sentence-ending punctuation mid-description |

**How to check "adds new info":** Read the title (filename without .md). Read the description. If the description merely restates the title using different words, it fails this check. A good description adds one of:
- **Mechanism** — how or why the claim works
- **Scope** — what boundaries the claim has
- **Implication** — what follows from the claim
- **Context** — where the claim applies

**Examples:**

Bad (restates title):
- Title: `observable macro replaces observableobject in swift`
- Description: "The @Observable macro is used instead of ObservableObject for view model observation"

Good (adds mechanism):
- Title: `observable macro replaces observableobject in swift`
- Description: "Eliminates manual @Published declarations and reduces boilerplate, while enabling compiler-enforced observation without inheriting from NSObject"

### YAML Validity (FAIL if broken)

| Check | Rule | How to Verify |
|-------|------|---------------|
| Frontmatter delimiters | Must start with `---` on line 1 and close with `---` | Read first line and scan for closing delimiter |
| Valid YAML | Must parse without errors | Check for common YAML errors: unquoted colons in values, mismatched quotes, bad indentation |
| No duplicate keys | Each YAML key appears only once | Scan for repeated field names |
| No unknown fields | Fields not in the template schema | Compare against `_schema.required` and `_schema.optional` if available — unknown fields get WARN |

### Domain-Specific Enum Checks (WARN if invalid)

If the pattern has fields with enumerated values, check them against the template's `_schema.enums` block:

| Field | Expected | Severity |
|-------|----------|----------|
| `type` | architecture, swiftui, concurrency, standards, testing, debugging, build-deploy | WARN |
| `status` | active, superseded, experimental | WARN |
| Custom domain fields | Values from template enum | WARN |

If a field has a value not in the enum list, report the invalid value and list the valid options.

### Link Health (WARN per broken link)

| Check | Rule | How to Verify |
|-------|------|---------------|
| Body wiki-links | Each `[[link]]` should point to an existing file | Extract all `[[...]]` patterns from body, check each against file tree |
| Domains links | Domain guide referenced in Domains must exist | Verify each domain guide wiki link resolves |
| Relevant Patterns links | Each pattern in `relevant_notes` must exist | Verify each wiki link in relevant_notes resolves |
| Backtick exclusion | Wiki links inside backticks are examples, not real links | Skip `[[...]]` patterns inside single or triple backtick blocks |

**How to verify link resolution:** For each `[[link text]]`, check if a file named `link text.md` exists anywhere in the vault. Wiki links resolve by filename, not path.

### Relevant Patterns Format (WARN if incorrect)

| Check | Rule | Severity |
|-------|------|----------|
| Format | Array with context: `["[[pattern]] -- relationship"]` | WARN |
| Context phrase present | Each entry should include `--` or `—` followed by relationship description | WARN |
| Relationship type | Standard types: extends, foundation, contradicts, enables, example | INFO |
| No bare links | `["[[pattern]]"]` without context is a bare link — useless for navigation | WARN |

### Composability (WARN if fails)

| Check | Rule | How to Verify |
|-------|------|---------------|
| Title test | Can you complete "This pattern argues that [title]"? | Read the title as a sentence fragment — does it make a claim? |
| Specificity | Is the claim specific enough to disagree with? | Could someone reasonably argue the opposite? |
| Prose fitness | Would `since [[title]]` read naturally in another pattern? | Check if the title works as an inline wiki link |

**Topic labels vs claims:**
- "swiftui navigation" — topic label, not a claim, FAILS composability
- "router pattern avoids navigationview deprecation issues" — claim, PASSES composability

## Batch Mode

When validating all patterns (target is "all" or "patterns"):

1. Discover all .md files in patterns/ directory
2. Optionally include additional directories (e.g., self/memory/) if they exist
3. Run all schema checks on each pattern
4. Produce summary report:
   - Total patterns checked
   - PASS / WARN / FAIL counts
   - Top issues grouped by check type
   - Patterns needing immediate attention (FAIL items)
   - Pattern analysis: are certain check types failing systematically?

**Batch output format:**

```
## Validation Summary

Checked: N patterns
- PASS: M (X%)
- WARN: K (Y%)
- FAIL: J (Z%)

### FAIL Items (immediate attention)
| Pattern | Check | Detail |
|---------|-------|--------|
| [[pattern]] | description | Missing |
| [[pattern]] | domains | No domains footer |

### Top WARN Patterns
- Description restates title: N patterns
- Missing context phrases in relevant_notes: N patterns
- Enum value not in template: N patterns

### Patterns Needing Attention
1. [[pattern]] — 2 FAIL, 1 WARN
2. [[pattern]] — 1 FAIL, 3 WARN
```

## Output Format (Single Pattern)

```
=== VALIDATION: [[pattern title]] ===

PASS:
- description: present, 147 chars, adds mechanism beyond title
- domains: ["[[architecture]]"] — exists
- yaml: well-formed, valid delimiters
- composability: title works as prose ("This pattern argues that [title]")

WARN:
- relevant_notes: bare link without context phrase for [[pattern-x]]
- type: "observation" not in template enum (valid: architecture, swiftui, concurrency, standards, testing, debugging, build-deploy)

FAIL:
- (none)

Overall: PASS (2 warnings)
===
```

If WARN or FAIL items exist, include:

```
### Suggested Fixes
- **relevant_notes**: Add context phrase — e.g., `["[[pattern-x]] -- extends this by adding..."]`
- **type**: Change to valid enum value or propose adding "observation" to template
```

## Handoff Mode (--handoff flag)

When invoked with `--handoff`, output this structured format at the END:

```
=== RALPH HANDOFF: validate ===
Target: [[pattern title]]

Work Done:
- Validated against [template name] schema
- Checks run: N
- Status: PASS | WARN | FAIL

Findings:
- PASS: [list]
- WARN: [list or "none"]
- FAIL: [list or "none"]

Files Modified:
- [task file path] (Validate section updated, if applicable)

Learnings:
- [Friction]: [description] | NONE
- [Surprise]: [description] | NONE
- [Methodology]: [description] | NONE
- [Process gap]: [description] | NONE

Queue Updates:
- Mark: validate done for this task
=== END HANDOFF ===
```

## Task File Update

When a task file is in context (pipeline execution), update the `## Validate` section:

```markdown
## Validate
**Validated:** [UTC timestamp]

Schema check against [template name]:
- description: PASS (147 chars, adds mechanism beyond title)
- domains: PASS (["[[architecture]]"])
- yaml: PASS (well-formed)
- type: not specified (optional)
- relevant_notes: WARN (bare link for [[pattern-x]])
- composability: PASS

Overall: PASS (1 warning)
```

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| PASS | Meets requirement fully | None needed |
| WARN | Optional issue or soft violation | Consider fixing, not blocking |
| FAIL | Required field missing or invalid format | Must fix before verification passes |
| INFO | Informational observation | No action needed |

**FAIL blocks pipeline completion.** A pattern with any FAIL-level issue should NOT be marked done in the queue. It stays at `current_phase: "verify"` (or "validate" if run standalone) for re-validation after fixes.

**WARN does not block.** Warnings are quality signals, not gates. A pattern can proceed through the pipeline with warnings.

## Critical Constraints

**never:**
- block pattern creation based on validation failures (validation is a quality check, not a gate)
- auto-fix issues without reporting them first
- skip checks because the pattern "looks fine"
- report PASS without actually running the check
- ignore `_schema` blocks in templates when they exist

**always:**
- check ALL schema requirements, not a subset
- report specific field values in FAIL/WARN messages (not just "description is weak")
- suggest concrete fixes for every WARN and FAIL
- use template `_schema` as the authoritative source when available
- fall back to default checks gracefully when no template exists
- log patterns when running batch validation (recurring issues signal systematic problems)
