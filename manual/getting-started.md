---
description: First session guide for the FitToday iOS/Swift knowledge system
type: manual
generated_from: "arscontexta-v0.8.0"
---

# Getting Started

Welcome. This guide walks you through your first session — from orientation to creating your first iOS/Swift pattern and connecting it to the knowledge graph.

## What to Expect in Your First Session

When you start Claude Code in the FitToday project, the system automatically orients. You'll see a brief summary showing:
- How many patterns exist in `patterns/`
- How many captures are waiting in `captures/`
- Pending tasks in the queue
- Any overdue reminders

On a fresh vault, everything will be zero. That's normal. Your goal for this first session is to capture one real insight.

## Your First Pattern

A pattern in this system is a single, composable iOS/Swift insight expressed as a proposition. Not "my notes on MVVM" — more like "MVVM with @Observable removes the need for @StateObject in iOS 17." That's a pattern: specific, testable, transferable.

**Step 1: Identify something you know**

Think of one concrete thing you've learned about iOS/Swift development that you'd want to remember six months from now. Examples:
- An architecture decision for FitToday
- A SwiftUI pattern that solved a specific UI problem
- A concurrency lesson from async/await migration
- A testing pattern for @Observable ViewModels

**Step 2: Capture it**

Use the template in `templates/pattern-note.md`. Create a file in `patterns/` with a title that is the insight itself:

```
patterns/observable-eliminates-manual-objectwill-change.md
```

Fill in the required fields:
```yaml
---
description: "@Observable removes the boilerplate of ObservableObject and eliminates manual objectWillChange calls"
type: architecture
topics: []
---
```

The `description` field should be a single sentence that adds context beyond the title. If the title is already self-explanatory, the description can zoom out to say why this matters.

**Step 3: Extract from a source (optional)**

If you have a source — an article, WWDC session, documentation page, or code file — use `/extract` to mine it for patterns:

```
/extract captures/wwdc23-observation-framework.md
```

The system will extract structured patterns across 7 categories: architecture decisions, SwiftUI patterns, concurrency patterns, standards, testing patterns, debugging insights, and build/deploy.

## How Connections Work

Patterns link to each other using wiki links: `[[pattern-name]]`. These are the edges of your knowledge graph.

**Domain guides** (MOCs) are index files that organize related patterns. For example, `patterns/architecture.md` links to all architecture-related patterns and provides navigational context.

**Topics footer**: Every pattern should have a `topics:` array pointing to the relevant domain guides:

```yaml
topics:
  - "[[architecture]]"
  - "[[swiftui]]"
```

After creating patterns, run `/connect` to have the system analyze relationships and update domain guides:

```
/connect patterns/observable-eliminates-manual-objectwill-change.md
```

## The Orient-Work-Persist Session Rhythm

Every session follows the same three-beat structure:

**Orient** (start of session):
- Check the session orientation summary
- Read `ops/tasks.md` for pending work
- Review `self/goals.md` for active threads

**Work** (the session itself):
- Extract from sources, create patterns, connect insights
- Follow the task queue — `/next` recommends what to work on

**Persist** (end of session):
- Update `self/goals.md` with new threads
- Capture any methodology friction with `/remember`
- The Stop hook automatically writes a session record to `ops/sessions/`

## Where to Go Next

- [[skills]] — Full command reference for all 16 skills
- [[workflows]] — The complete processing pipeline explained
- [[configuration]] — How to tune the system for your workflow

---

Topics:
- [[manual]]
