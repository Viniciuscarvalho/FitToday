---
engine_version: "0.2.0"
research_snapshot: "2026-02-10"
generated_at: "2026-02-23T00:00:00Z"
platform: claude-code
kernel_version: "1.0"

dimensions:
  granularity: moderate
  organization: flat
  linking: explicit+implicit
  processing: heavy
  navigation: 3-tier
  maintenance: condition-based
  schema: moderate
  automation: full

active_blocks:
  - wiki-links
  - atomic-notes
  - mocs
  - processing-pipeline
  - semantic-search
  - schema
  - maintenance
  - self-evolution
  - methodology-knowledge
  - session-rhythm
  - templates
  - ethical-guardrails
  - helper-functions
  - graph-analysis
  - self-space

coherence_result: passed

vocabulary:
  notes: "patterns"
  inbox: "captures"
  archive: "archived"
  ops: "ops"

  note: "pattern"
  note_plural: "patterns"

  description: "context"
  topics: "domains"
  relevant_notes: "related patterns"

  topic_map: "domain guide"
  hub: "hub"

  reduce: "extract"
  reflect: "connect"
  reweave: "update"
  verify: "verify"
  validate: "validate"
  rethink: "rethink"

  cmd_reduce: "/extract"
  cmd_reflect: "/connect"
  cmd_reweave: "/update"
  cmd_verify: "/verify"
  cmd_rethink: "/rethink"

  extraction_categories:
    - name: "architecture-decisions"
      what_to_find: "Why X over Y, constraints, trade-offs, implications for the project"
      output_type: "pattern"
    - name: "swiftui-patterns"
      what_to_find: "View composition, state management, navigation, @Observable usage"
      output_type: "pattern"
    - name: "concurrency-patterns"
      what_to_find: "async/await, actors, sendable, task groups, @MainActor usage"
      output_type: "pattern"
    - name: "standards"
      what_to_find: "Coding standards, naming conventions, project rules, API guidelines"
      output_type: "pattern"
    - name: "testing-patterns"
      what_to_find: "XCTest approaches, spies, stubs, mocks, fixtures, coverage strategies"
      output_type: "pattern"
    - name: "debugging-insights"
      what_to_find: "Solutions to tricky bugs, gotchas, common pitfalls"
      output_type: "pattern"
    - name: "build-deploy"
      what_to_find: "App Store Connect, signing, CI/CD, TestFlight distribution"
      output_type: "pattern"

platform_hints:
  context: fork
  allowed_tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Task", "WebSearch", "WebFetch"]
  semantic_search_tool: null

personality:
  warmth: clinical
  opinionatedness: neutral
  formality: formal
  emotional_awareness: task-focused
---
