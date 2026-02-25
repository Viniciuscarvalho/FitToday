---
_schema:
  entity_type: "domain-guide"
  applies_to: "patterns/*.md"
  required:
    - description
    - type
  enums:
    type:
      - moc
  constraints:
    description:
      max_length: 200
      format: "One sentence describing the domain area this guide covers"

description: ""
type: moc
---

# {domain-name}

Brief orientation — what this domain covers and how to use this guide.

## Core Patterns

- [[pattern]] — context explaining why this matters here
- [[pattern]] — what this adds to the domain

## Decisions

Key architectural or design decisions in this domain.

## Tensions

Unresolved conflicts — where patterns clash or trade-offs remain open.

## Open Questions

What is unexplored. Gaps in understanding, areas needing investigation.

---

Domains:
- [[index]]
