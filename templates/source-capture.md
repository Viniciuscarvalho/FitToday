---
_schema:
  entity_type: "source-capture"
  applies_to: "captures/*.md"
  required:
    - description
  optional:
    - source_type
    - research_prompt
    - generated
  enums:
    source_type:
      - conversation
      - code-review
      - debugging
      - documentation
      - skill-reference
      - web-search
      - manual
  constraints:
    description:
      max_length: 200
      format: "Brief note about what this source contains and why it matters"

description: ""
source_type:
generated:
---

# {brief description of the source}

{Raw content, notes, links, or quick captures. Processing happens later.}
