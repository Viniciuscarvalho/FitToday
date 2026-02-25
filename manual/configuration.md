---
description: How to adjust the FitToday knowledge system via ops/config.yaml and /arscontexta:architect
type: manual
generated_from: "arscontexta-v0.8.0"
---

# Configuration

The system has two configuration surfaces: `ops/config.yaml` for live operational settings and `ops/derivation.md` for the historical record of design decisions. Edit config.yaml to adjust behavior; consult derivation.md to understand why choices were made.

## ops/config.yaml

The primary configuration file. Edit it to change how the system behaves without re-running setup.

```yaml
dimensions:
  granularity: atomic      # How fine-grained patterns are
  organization: flat       # Folder structure approach
  linking: explicit+implicit  # Connection strategy
  processing: heavy        # Extraction depth
  navigation: 3-tier       # Navigation structure
  maintenance: condition-based  # Maintenance triggers
  schema: moderate         # Template field density
  automation: full         # Automation ceiling

features:
  semantic-search: false   # Set true if qmd is installed
  processing-pipeline: true
  sleep-processing: false

processing:
  depth: standard          # deep | standard | quick
  chaining: suggested      # manual | suggested | automatic
  extraction:
    selectivity: moderate  # strict | moderate | permissive
```

### Dimensions Explained

**granularity: atomic** — Each pattern contains one insight. Don't combine "actor isolation solves reentrancy" with "nonisolated methods are synchronous" into one pattern. If it can be split, split it.

**processing: heavy** — Full extraction pipeline, comprehensive coverage. The extractor will find every iOS/Swift insight in a source, not just the obvious ones. If you find extraction is too aggressive, change to `moderate`.

**processing.depth: standard** — Balanced pipeline with full phases. Change to `quick` for rapid catch-up processing of minor sources. Change to `deep` for important sources where maximum quality matters.

**processing.chaining: suggested** — Skills output the next step and add it to the queue, but don't auto-execute. You decide whether to follow the suggestion. Change to `automatic` to let the pipeline run end-to-end without prompts.

### Feature Flags

**semantic-search: false** — Implicit linking via vector search is disabled. Change to `true` after installing qmd:

```bash
npm install -g @tobilu/qmd
qmd init
qmd collection add . --name patterns --mask "patterns/**/*.md"
qmd update && qmd embed
```

Then update `.mcp.json` in the project root to include the qmd MCP server.

## Adjusting Pipeline Behavior

### Change extraction selectivity

If `/extract` is creating too many patterns from a source:
```yaml
processing:
  extraction:
    selectivity: strict   # only extract the clearest, most unambiguous insights
```

If it's missing things:
```yaml
processing:
  extraction:
    selectivity: permissive  # capture borderline insights too
```

### Change pipeline chaining

To have skills chain automatically without prompts:
```yaml
processing:
  chaining: automatic
```

To require manual confirmation at each phase:
```yaml
processing:
  chaining: manual
```

### Change processing depth per-session

You can override depth for a single invocation without changing config:
```
/extract --depth deep captures/important-architecture-doc.md
/ralph --depth quick   # batch catch-up with lighter processing
```

## Using /arscontexta:architect

For larger changes that require architectural reasoning, use the architect plugin instead of editing config directly:

```
/arscontexta:architect
```

The architect:
1. Reads your current health report and derivation history
2. Analyzes accumulated friction from `ops/observations/` and `ops/tensions/`
3. Proposes specific changes with research justification from the Ars Contexta knowledge base
4. Shows exactly what would change and why
5. Waits for approval before anything changes

Use `/arscontexta:architect` when:
- You want to change multiple dimensions together (architect checks coherence)
- You're not sure if a change will create constraint violations
- You want research-backed reasoning for a structural decision

Use `ops/config.yaml` directly when:
- You know exactly what to change
- The change is a single dimension or feature flag
- You're adjusting processing behavior, not vault structure

## Preset Overview

This system was generated from the **Experimental/iOS Development** configuration:

| Dimension | Position | Why |
|-----------|----------|-----|
| Granularity | Atomic | iOS insights are composable — one per pattern |
| Organization | Flat | patterns/ stays flat; domain guides provide navigation |
| Linking | Explicit + Implicit | Wiki links + future semantic search |
| Processing | Heavy | iOS/Swift sources are dense — comprehensive extraction |
| Navigation | 3-tier | patterns → domain guides → index |
| Maintenance | Condition-based | Triggers on counts, not calendar |
| Schema | Moderate | type, description, topics — enough without overhead |
| Automation | Full | All hooks, all automation from day one |

See `ops/derivation.md` for the full derivation rationale including which conversation signals drove each choice.

## ops/derivation.md vs ops/config.yaml

- **derivation.md** is the immutable record of why each choice was made. Don't edit it manually. The `/rethink` and `/refactor` skills append to it when the system evolves.
- **config.yaml** is the live operational config. Edit freely. It can drift from derivation.md; `/arscontexta:architect` detects and documents that drift.

## See Also

- [[meta-skills]] — /arscontexta:architect in detail
- [[troubleshooting]] — Configuration-related issues and fixes

---

Topics:
- [[manual]]
