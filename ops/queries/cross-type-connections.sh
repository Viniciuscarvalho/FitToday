#!/usr/bin/env bash
# cross-type-connections.sh — Find patterns that link across different iOS domains
# Surfaces integration points between architecture, SwiftUI, concurrency, etc.
# Run from FitToday/ root: bash ops/queries/cross-type-connections.sh

echo "=== Cross-Domain Pattern Connections ==="
echo "  (Patterns with links to patterns of a different type)"
echo ""

declare -A TYPE_MAP

# Build type map
for f in patterns/*.md; do
  [[ -f "$f" ]] || continue
  NAME=$(basename "$f" .md)
  TYPE=$(grep '^type:' "$f" 2>/dev/null | head -1 | awk '{print $2}')
  TYPE_MAP["$NAME"]="$TYPE"
done

# Find cross-type links
FOUND=0
for f in patterns/*.md; do
  [[ -f "$f" ]] || continue
  NAME=$(basename "$f" .md)
  SRC_TYPE="${TYPE_MAP[$NAME]:-unknown}"
  [[ "$SRC_TYPE" == "moc" ]] && continue

  while IFS= read -r link; do
    TARGET=$(echo "$link" | sed 's/\[\[//;s/\]\]//')
    TARGET_TYPE="${TYPE_MAP[$TARGET]:-unknown}"
    if [[ -n "$TARGET_TYPE" && "$TARGET_TYPE" != "unknown" && "$TARGET_TYPE" != "moc" && "$SRC_TYPE" != "$TARGET_TYPE" ]]; then
      echo "  [[${NAME}]] ($SRC_TYPE) → [[${TARGET}]] ($TARGET_TYPE)"
      FOUND=$((FOUND + 1))
    fi
  done < <(grep -oP '\[\[[^\]]+\]\]' "$f" 2>/dev/null || true)
done

echo ""
echo "  Cross-domain links found: $FOUND"
[[ "$FOUND" -gt 0 ]] && echo "  These are integration points — review them to ensure connections are intentional."
