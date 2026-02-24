#!/usr/bin/env bash
# session-orient.sh — Orient the agent at session start
# Reads vault state and surfaces urgent items. Runs on SessionStart.

set -euo pipefail
cd "$(dirname "$0")/../.." 2>/dev/null || exit 0

# Only run inside the FitToday vault
[[ -f ".arscontexta" ]] || exit 0

echo ""
echo "=== FitToday Knowledge System — Session Orient ==="
echo ""

# 1. Check overdue reminders
if [[ -f "ops/reminders.md" ]]; then
  TODAY=$(date +%Y-%m-%d)
  OVERDUE=$(grep -E '^\- \[ \] [0-9]{4}-[0-9]{2}-[0-9]{2}:' ops/reminders.md 2>/dev/null | while read -r line; do
    DATE=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    [[ "$DATE" < "$TODAY" || "$DATE" == "$TODAY" ]] && echo "$line"
  done || true)
  if [[ -n "$OVERDUE" ]]; then
    echo "REMINDERS DUE:"
    echo "$OVERDUE" | head -5
    echo ""
  fi
fi

# 2. Check queue for pending tasks
QUEUE_FILE=""
if [[ -f "ops/queue/queue.json" ]]; then
  QUEUE_FILE="ops/queue/queue.json"
  PENDING=$(grep -c '"status": "pending"' "$QUEUE_FILE" 2>/dev/null || echo 0)
  if [[ "$PENDING" -gt 0 ]]; then
    echo "QUEUE: $PENDING pending tasks — run /ralph to process"
  fi
fi

# 3. Check captures/ for unprocessed items
CAPTURES_COUNT=$(find captures/ -name "*.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
if [[ "$CAPTURES_COUNT" -gt 0 ]]; then
  echo "CAPTURES: $CAPTURES_COUNT items in captures/ — run /extract [file] to process"
fi

# 4. Check observation/tension thresholds
OBS_COUNT=$(grep -rl '^status: pending' ops/observations/ 2>/dev/null | wc -l | tr -d ' ')
TENSION_COUNT=$(grep -rl '^status: pending\|^status: open' ops/tensions/ 2>/dev/null | wc -l | tr -d ' ')
if [[ "$OBS_COUNT" -ge 10 ]]; then
  echo "OBSERVATIONS: $OBS_COUNT pending — run /rethink"
fi
if [[ "$TENSION_COUNT" -ge 5 ]]; then
  echo "TENSIONS: $TENSION_COUNT open — run /rethink"
fi

# 5. Count patterns
PATTERN_COUNT=$(ls -1 patterns/*.md 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Patterns: $PATTERN_COUNT | Captures: $CAPTURES_COUNT | Queue: ${PENDING:-0} pending"
echo "==="
echo ""
