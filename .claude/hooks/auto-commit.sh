#!/usr/bin/env bash
# auto-commit.sh — Auto-commit new/modified patterns after writing
# Runs async on PostToolUse(Write) so it doesn't block the agent.

set -euo pipefail
cd "$(dirname "$0")/../.." 2>/dev/null || exit 0

# Only run inside the FitToday vault
[[ -f ".arscontexta" ]] || exit 0

# Only auto-commit if inside a git repo
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# TOOL_INPUT_FILE_PATH is set by Claude Code for PostToolUse hooks
WRITTEN_FILE="${TOOL_INPUT_FILE_PATH:-}"

# Only auto-commit pattern files and ops files
[[ -z "$WRITTEN_FILE" ]] && exit 0
[[ "$WRITTEN_FILE" == patterns/*.md ]] || \
[[ "$WRITTEN_FILE" == ops/methodology/*.md ]] || \
[[ "$WRITTEN_FILE" == ops/observations/*.md ]] || \
[[ "$WRITTEN_FILE" == ops/tensions/*.md ]] || \
[[ "$WRITTEN_FILE" == ops/queue/*.json ]] || \
[[ "$WRITTEN_FILE" == self/*.md ]] || exit 0

# Only commit if there are actual changes
git diff --quiet "$WRITTEN_FILE" 2>/dev/null && \
git diff --cached --quiet "$WRITTEN_FILE" 2>/dev/null && \
git ls-files --others --exclude-standard "$WRITTEN_FILE" 2>/dev/null | grep -q . || exit 0

# Stage the specific file
git add "$WRITTEN_FILE" 2>/dev/null || exit 0

# Determine commit message from file path
BASENAME=$(basename "$WRITTEN_FILE" .md)
if [[ "$WRITTEN_FILE" == patterns/* ]]; then
  MSG="chore: update pattern $BASENAME"
elif [[ "$WRITTEN_FILE" == ops/methodology/* ]]; then
  MSG="chore: update methodology note $BASENAME"
elif [[ "$WRITTEN_FILE" == ops/observations/* ]]; then
  MSG="chore: update observation $BASENAME"
elif [[ "$WRITTEN_FILE" == ops/tensions/* ]]; then
  MSG="chore: update tension $BASENAME"
elif [[ "$WRITTEN_FILE" == ops/queue/* ]]; then
  MSG="chore: update queue state"
elif [[ "$WRITTEN_FILE" == self/* ]]; then
  MSG="chore: update self/$BASENAME"
else
  MSG="chore: update $WRITTEN_FILE"
fi

git commit -m "$MSG" --no-gpg-sign 2>/dev/null || true

exit 0
