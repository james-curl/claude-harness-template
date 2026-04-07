#!/bin/bash
# pre-commit-typecheck.sh — PreToolUse hook that runs {{PKG_MANAGER}} typecheck before any git commit.
# This can take 10-20 seconds — that's acceptable for commit safety.
# Exit 2 = block the commit (typecheck failed). Exit 0 = allow.
#
# Test commands:
#   echo '{"tool_input":{"command":"git commit -m test"}}' | .claude/hooks/pre-commit-typecheck.sh; echo $?
#     → runs typecheck; exits 0 if clean, exits 2 with error output if not
#   echo '{"tool_input":{"command":"git status"}}' | .claude/hooks/pre-commit-typecheck.sh; echo $?
#     → expect exit 0 (not a commit command)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on git commit commands
if [[ ! "$COMMAND" =~ ^git\ commit ]]; then
  exit 0
fi

# Resolve the repo root so this hook works regardless of cwd
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  echo "pre-commit-typecheck: could not determine repo root" >&2
  exit 2
fi

echo "Running typecheck before commit (this may take ~15s)..." >&2

OUTPUT=$(cd "$REPO_ROOT" && {{PKG_MANAGER}} typecheck 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "Typecheck failed — commit blocked." >&2
  echo "" >&2
  echo "$OUTPUT" >&2
  echo "" >&2
  echo "Fix all type errors before committing." >&2
  exit 2
fi

exit 0
