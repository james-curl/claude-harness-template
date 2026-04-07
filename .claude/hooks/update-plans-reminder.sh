#!/bin/bash
# update-plans-reminder.sh — PostToolUse hook (Bash) that reminds Claude to
# update plan tracking files after git commits, and to sync planning files
# after git pulls.
# Exit 0 always — advisory only, never blocks.
#
# Test:
#   echo '{"tool_input":{"command":"git commit -m test"}}' | .claude/hooks/update-plans-reminder.sh; echo $?
#     → expect reminder on stderr + exit 0
#   echo '{"tool_input":{"command":"git pull"}}' | .claude/hooks/update-plans-reminder.sh; echo $?
#     → expect sync reminder on stderr + exit 0

INPUT=$(cat)

# Trigger on git commit or git pull commands
IS_COMMIT=false
IS_PULL=false

if echo "$INPUT" | grep -q "git commit"; then
  IS_COMMIT=true
elif echo "$INPUT" | grep -q "git pull"; then
  IS_PULL=true
else
  exit 0
fi

# Check if any active plans exist
HAS_PLANS=false
if ls docs/plans/*/PROGRESS.md 1>/dev/null 2>&1; then
  HAS_PLANS=true
fi

HAS_MANIFESTS=false
if ls docs/tasks/wave-*/MANIFEST.md 1>/dev/null 2>&1; then
  HAS_MANIFESTS=true
fi

if [ "$IS_COMMIT" = true ]; then
  if [ "$HAS_PLANS" = true ] || [ "$HAS_MANIFESTS" = true ]; then
    echo "Post-commit: check if PROGRESS.md, ROADMAP.md, or MANIFEST.md need a status update." >&2
  fi
elif [ "$IS_PULL" = true ]; then
  echo "New commits pulled. Run /sync-status to update planning files." >&2
fi

exit 0
