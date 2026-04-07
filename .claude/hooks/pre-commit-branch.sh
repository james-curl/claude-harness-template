#!/bin/bash
# pre-commit-branch.sh — PreToolUse hook that blocks git commits to main or master.
# Exit 2 = block the commit. Exit 0 = allow.
#
# Test commands:
#   echo '{"tool_input":{"command":"git commit -m test"}}' | .claude/hooks/pre-commit-branch.sh; echo $?
#     → expect exit 2 if current branch is main/master, exit 0 otherwise
#   echo '{"tool_input":{"command":"git status"}}' | .claude/hooks/pre-commit-branch.sh; echo $?
#     → expect exit 0 (not a commit command)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on git commit commands
if [[ ! "$COMMAND" =~ ^git\ commit ]]; then
  exit 0
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "Blocked: cannot commit directly to '$BRANCH'." >&2
  echo "Create a branch first: git checkout -b feature/your-description" >&2
  exit 2
fi

exit 0
