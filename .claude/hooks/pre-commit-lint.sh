#!/bin/bash
# pre-commit-lint.sh — PreToolUse hook that runs {{PKG_MANAGER}} lint before any git commit.
# Exit 2 = block the commit (lint failed). Exit 0 = allow.
#
# Test commands:
#   echo '{"tool_input":{"command":"git commit -m test"}}' | .claude/hooks/pre-commit-lint.sh; echo $?
#     → runs lint; exits 0 if clean, exits 2 with error output if not
#   echo '{"tool_input":{"command":"git status"}}' | .claude/hooks/pre-commit-lint.sh; echo $?
#     → expect exit 0 (not a commit command)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on git commit commands
if [[ ! "$COMMAND" =~ ^git\ commit ]]; then
  exit 0
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "pre-commit-lint: could not determine repo root" >&2
  exit 2
fi

echo "Running lint before commit..." >&2

OUTPUT=$(cd "$REPO_ROOT" && {{PKG_MANAGER}} lint 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "Lint failed — commit blocked." >&2
  echo "" >&2
  echo "$OUTPUT" >&2
  echo "" >&2
  echo "Fix all lint errors before committing." >&2
  exit 2
fi

exit 0
