#!/usr/bin/env bash
# orphan-patterns.sh — Find patterns with zero incoming links
# Run from FitToday/ root: bash ops/queries/orphan-patterns.sh

echo "=== Orphan Patterns (zero incoming links) ==="
echo ""

COUNT=0
for f in patterns/*.md; do
  [[ -f "$f" ]] || continue
  NAME=$(basename "$f" .md)
  grep -q '^type: moc' "$f" 2>/dev/null && continue

  INCOMING=$(grep -rl "\[\[$NAME\]\]" patterns/ 2>/dev/null | grep -v "$f" | wc -l | tr -d ' ')
  if [[ "$INCOMING" -eq 0 ]]; then
    TYPE=$(grep '^type:' "$f" 2>/dev/null | head -1 | awk '{print $2}')
    echo "  [[${NAME}]] (${TYPE:-no type})"
    COUNT=$((COUNT + 1))
  fi
done

echo ""
echo "  Orphans: $COUNT"
[[ "$COUNT" -gt 0 ]] && echo "  Suggestion: Run /connect on orphaned patterns or add them to a domain guide."
