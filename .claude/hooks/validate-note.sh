#!/usr/bin/env bash
# validate-note.sh — Validate pattern schema when a file in patterns/ is written
# Non-blocking: warns but does not prevent the write. Runs on PostToolUse(Write).

set -euo pipefail
cd "$(dirname "$0")/../.." 2>/dev/null || exit 0

# Only run inside the FitToday vault
[[ -f ".arscontexta" ]] || exit 0

# TOOL_INPUT_FILE_PATH is set by Claude Code for PostToolUse hooks
WRITTEN_FILE="${TOOL_INPUT_FILE_PATH:-}"

# Only validate files written to patterns/
[[ -z "$WRITTEN_FILE" ]] && exit 0
[[ "$WRITTEN_FILE" == patterns/*.md ]] || exit 0
[[ -f "$WRITTEN_FILE" ]] || exit 0

FILENAME=$(basename "$WRITTEN_FILE")
WARNINGS=()

# Check for YAML frontmatter
if ! grep -q '^---' "$WRITTEN_FILE" 2>/dev/null; then
  WARNINGS+=("WARN: No YAML frontmatter in $FILENAME")
fi

# Check required field: description
if ! grep -q '^description:' "$WRITTEN_FILE" 2>/dev/null; then
  WARNINGS+=("WARN: Missing 'description' field in $FILENAME")
else
  # Check description is not empty
  DESC=$(grep '^description:' "$WRITTEN_FILE" | head -1 | sed 's/^description: *//')
  [[ -z "$DESC" || "$DESC" == '""' || "$DESC" == "''" ]] && WARNINGS+=("WARN: Empty description in $FILENAME")
fi

# Check required field: type
if ! grep -q '^type:' "$WRITTEN_FILE" 2>/dev/null; then
  # Only warn if not a moc
  if ! grep -q '^type: moc' "$WRITTEN_FILE" 2>/dev/null; then
    WARNINGS+=("WARN: Missing 'type' field in $FILENAME")
  fi
fi

# Warn if type is not one of the expected values (non-blocking)
VALID_TYPES="architecture|swiftui|concurrency|standards|testing|debugging|build-deploy|moc|methodology"
if grep -q '^type:' "$WRITTEN_FILE" 2>/dev/null; then
  TYPE_VAL=$(grep '^type:' "$WRITTEN_FILE" | head -1 | sed 's/^type: *//')
  if ! echo "$TYPE_VAL" | grep -qE "^($VALID_TYPES)$"; then
    WARNINGS+=("WARN: Unexpected type '$TYPE_VAL' in $FILENAME — expected: architecture|swiftui|concurrency|standards|testing|debugging|build-deploy")
  fi
fi

# Print warnings if any
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo ""
  echo "=== Pattern Validation: $FILENAME ==="
  for w in "${WARNINGS[@]}"; do
    echo "  $w"
  done
  echo "  Run /verify $FILENAME to check in detail."
  echo "==="
fi

exit 0
