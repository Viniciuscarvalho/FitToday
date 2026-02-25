#!/usr/bin/env bash
# stale-patterns.sh — Find patterns older than 30 days with fewer than 2 outgoing links
# Run from FitToday/ root: bash ops/queries/stale-patterns.sh

CUTOFF=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d 2>/dev/null || echo "2000-01-01")

echo "=== Stale Patterns (created > 30 days ago, < 2 links) ==="
echo "  Cutoff date: $CUTOFF"
echo ""

COUNT=0
for f in patterns/*.md; do
  [[ -f "$f" ]] || continue
  grep -q '^type: moc' "$f" 2>/dev/null && continue

  CREATED=$(grep '^created:' "$f" 2>/dev/null | head -1 | awk '{print $2}')
  [[ -z "$CREATED" ]] && continue
  [[ "$CREATED" > "$CUTOFF" ]] && continue

  LINKS=$(grep -oP '\[\[[^\]]+\]\]' "$f" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$LINKS" -lt 2 ]]; then
    NAME=$(basename "$f" .md)
    echo "  [[${NAME}]] — created: $CREATED, links: $LINKS"
    COUNT=$((COUNT + 1))
  fi
done

echo ""
echo "  Total stale: $COUNT"
echo "  Suggestion: Run /update on these patterns to add connections."
