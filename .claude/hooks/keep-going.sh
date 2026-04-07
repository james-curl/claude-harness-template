#!/bin/bash
# keep-going.sh — Stop hook for {{PROJECT_NAME}} project.
# 1. Nudges Claude to continue if uncommitted changes exist
# 2. Fires macOS notification when stopping
#
# Exit 0 always — the message itself guides behavior.
#
# Test:
#   echo '{"reason":"task_complete"}' | .claude/hooks/keep-going.sh; echo $?
#     → expect exit 0

INPUT=$(cat)

# Check if there are uncommitted changes (sign of in-progress work)
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  # There are uncommitted changes — nudge to continue
  echo "You have uncommitted changes. If you're not done with the current task, continue working. If you are done, commit your changes before stopping." >&2
fi

exit 0
