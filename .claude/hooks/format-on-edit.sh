#!/bin/bash
# format-on-edit.sh — PostToolUse hook that runs prettier on edited files.
# Uses || true so it never blocks Claude (non-critical).
# Silently skips files that prettier can't handle (binaries, unknown types).

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# No file path — nothing to format
if [ -z "$FILE" ]; then
  exit 0
fi

# Only format files prettier understands
case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md|*.html|*.yaml|*.yml)
    npx prettier --write "$FILE" 2>/dev/null || true
    ;;
esac

exit 0
