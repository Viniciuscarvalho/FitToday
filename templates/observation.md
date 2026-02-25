---
_schema:
  entity_type: "observation"
  applies_to: "ops/observations/*.md"
  required:
    - description
    - category
    - observed
    - status
  enums:
    category:
      - friction
      - surprise
      - process-gap
      - methodology
    status:
      - pending
      - promoted
      - implemented
      - archived
  constraints:
    description:
      max_length: 200
      format: "What happened and what it suggests"

description: ""
category:
observed:
status: pending
---

# {the observation as a sentence}

What happened, why it matters, and what might change.
