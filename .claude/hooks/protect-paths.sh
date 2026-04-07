#!/bin/bash
# protect-paths.sh — PreToolUse hook that blocks edits to sensitive paths.
# Exit 2 = block the edit (Claude sees the error and adjusts).
# Exit 0 = allow the edit.
#
# Test commands:
#   echo '{"tool_input":{"file_path":"migrations/001.sql"}}' | .claude/hooks/protect-paths.sh; echo $?
#     → expect exit 2 (blocked)
#   echo '{"tool_input":{"file_path":"apps/web/src/features/sales/SalesPage.tsx"}}' | .claude/hooks/protect-paths.sh; echo $?
#     → expect exit 0 (allowed)
#   echo '{"tool_input":{"file_path":".env.local"}}' | .claude/hooks/protect-paths.sh; echo $?
#     → expect exit 2 (blocked)

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# No file path in input — allow (not a file edit)
if [ -z "$FILE" ]; then
  exit 0
fi

# Protected path patterns
PROTECTED_PATTERNS=(
  "migrations/"
  ".env"
  ".github/workflows/"
  "docker-compose.yml"
  "docker-compose.yaml"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    echo "Protected path: cannot edit '$FILE' (matches '$pattern'). Ask the user for confirmation first." >&2
    exit 2
  fi
done

exit 0
