#!/usr/bin/env bash
# missing-description.sh — Find patterns missing or with empty description fields
# Run from FitToday/ root: bash ops/queries/missing-description.sh

echo "=== Patterns Missing Descriptions ==="
echo ""

COUNT=0
for f in patterns/*.md; do
  [[ -f "$f" ]] || continue
  grep -q '^type: moc' "$f" 2>/dev/null && continue

  if ! grep -q '^description:' "$f" 2>/dev/null; then
    NAME=$(basename "$f" .md)
    echo "  [[${NAME}]] — no description field"
    COUNT=$((COUNT + 1))
    continue
  fi

  DESC=$(grep '^description:' "$f" | head -1 | sed 's/^description: *//')
  if [[ -z "$DESC" || "$DESC" == '""' || "$DESC" == "''" ]]; then
    NAME=$(basename "$f" .md)
    echo "  [[${NAME}]] — empty description"
    COUNT=$((COUNT + 1))
  fi
done

echo ""
echo "  Missing: $COUNT patterns"
[[ "$COUNT" -gt 0 ]] && echo "  Suggestion: Run /verify [pattern] on each to add descriptions."
