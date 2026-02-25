#!/usr/bin/env bash
# session-capture.sh — Capture session state when Claude stops
# Writes a session record to ops/sessions/. Runs on Stop.

set -euo pipefail
cd "$(dirname "$0")/../.." 2>/dev/null || exit 0

# Only run inside the FitToday vault
[[ -f ".arscontexta" ]] || exit 0

mkdir -p ops/sessions

TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
SESSION_FILE="ops/sessions/${TIMESTAMP}.md"
TODAY=$(date +%Y-%m-%d)
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Count patterns modified today (use git for accuracy)
PATTERNS_TODAY=$(git diff --name-only HEAD 2>/dev/null | grep '^patterns/' | wc -l | tr -d ' ')

# Write session record
cat > "$SESSION_FILE" << EOF
---
session: $TIMESTAMP
date: $TODAY
captured: $NOW
mined: false
---

# Session $TIMESTAMP

## Patterns Modified Today
$(git diff --name-only HEAD 2>/dev/null | grep '^patterns/' | head -20 | sed 's/^/- /' || echo "- (none)")

## Queue State
$(if [[ -f "ops/queue/queue.json" ]]; then
  PENDING=$(grep -c '"status": "pending"' ops/queue/queue.json 2>/dev/null || echo 0)
  DONE=$(grep -c '"status": "done"' ops/queue/queue.json 2>/dev/null || echo 0)
  echo "- Pending: $PENDING"
  echo "- Done: $DONE"
else
  echo "- No queue file"
fi)

## Captures State
$(CAPTURES=$(find captures/ -name "*.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
echo "- Items in captures/: $CAPTURES")

## Notes

(Populate with session observations, friction, or discoveries)
EOF

# Keep only last 30 sessions (clean up older ones)
ls -t ops/sessions/*.md 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null || true

exit 0
