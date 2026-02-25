#!/usr/bin/env bash
# type-distribution.sh — Count iOS patterns by type
# Run from FitToday/ root: bash ops/queries/type-distribution.sh

echo "=== Pattern Type Distribution ==="
echo ""
for TYPE in architecture swiftui concurrency standards testing debugging build-deploy; do
  COUNT=$(grep -rl "^type: $TYPE" patterns/ 2>/dev/null | wc -l | tr -d ' ')
  echo "  $TYPE: $COUNT"
done
TOTAL=$(ls -1 patterns/*.md 2>/dev/null | wc -l | tr -d ' ')
MOCS=$(grep -rl '^type: moc' patterns/ 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "  Total patterns: $((TOTAL - MOCS)) (plus $MOCS domain guides)"
