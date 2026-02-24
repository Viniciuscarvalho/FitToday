---
_schema:
  entity_type: "pattern-note"
  applies_to: "patterns/*.md"
  required:
    - description
  optional:
    - type
    - category
    - applies_to
    - status
    - created
    - modified
    - superseded_by
  enums:
    type:
      - insight
      - pattern
      - decision
      - standard
      - anti-pattern
      - question
      - tension
    category:
      - architecture
      - swiftui
      - concurrency
      - testing
      - standards
      - debugging
      - build-deploy
    status:
      - preliminary
      - active
      - archived
      - superseded
  constraints:
    description:
      max_length: 200
      format: "One sentence adding context beyond the title — scope, mechanism, or implication"
    domains:
      format: "Array of wiki links to domain guides"

description: ""
type: pattern
category:
status: active
created:
---

# {prose-as-title — express the pattern as a complete thought}

{Content: explain the pattern, the reasoning behind it, and when it applies. Show WHY, not just HOW.}

---

Related Patterns:
- [[related pattern]] — relationship context (extends, contradicts, enables, foundation)

Domains:
- [[relevant-domain-guide]]
