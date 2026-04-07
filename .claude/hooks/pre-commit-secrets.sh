#!/bin/bash
# pre-commit-secrets.sh — PreToolUse hook that scans staged files for hardcoded secrets.
# Catches: API keys, passwords, connection strings, AWS keys, long base64 blobs.
# Skips: .env.example, *.md, *.sh, test fixtures.
# Exit 2 = block the commit. Exit 0 = allow.
#
# Test commands:
#   echo '{"tool_input":{"command":"git commit -m test"}}' | .claude/hooks/pre-commit-secrets.sh; echo $?
#     → scans staged diff; blocks if secrets detected
#   echo '{"tool_input":{"command":"git log"}}' | .claude/hooks/pre-commit-secrets.sh; echo $?
#     → expect exit 0 (not a commit command)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on git commit commands
if [[ ! "$COMMAND" =~ ^git\ commit ]]; then
  exit 0
fi

# Get the staged diff (added lines only, no context)
DIFF=$(git diff --cached -U0 2>/dev/null)

if [ -z "$DIFF" ]; then
  exit 0
fi

VIOLATIONS=""

# Helper: search the diff for a pattern and collect matches with file context
check_pattern() {
  local LABEL="$1"
  local PATTERN="$2"
  local MATCHES
  MATCHES=$(echo "$DIFF" | grep -n "$PATTERN" || true)
  if [ -n "$MATCHES" ]; then
    VIOLATIONS="$VIOLATIONS\n[$LABEL]\n$MATCHES\n"
  fi
}

# --- Secret patterns ---

# API_KEY, SECRET, PASSWORD, TOKEN followed by = and a value (not an env var reference)
# Env var references look like: API_KEY=${VAR} or API_KEY=$VAR or API_KEY=process.env.X
# We block lines where the value looks like a real literal (quoted string or bare word >=8 chars)
check_pattern "Hardcoded credential assignment" \
  '^\+.*\(API_KEY\|SECRET\|PASSWORD\|TOKEN\|PRIVATE_KEY\|ACCESS_KEY\)\s*=\s*["\x27][^$][^"'\'']\{7,\}'

# Hardcoded PostgreSQL/MySQL/MongoDB connection strings with embedded credentials
check_pattern "Hardcoded database connection string" \
  '^\+.*\(postgres\|postgresql\|mysql\|mongodb\):\/\/[^$][^@]*@'

# AWS access key IDs (always start with AKIA, 20 chars)
check_pattern "AWS access key" \
  '^\+.*AKIA[0-9A-Z]\{16\}'

# Long base64 blobs assigned to a variable (≥40 chars of base64 after an = sign)
# Intentionally conservative: only flags inside assignment contexts
check_pattern "Potential base64-encoded secret" \
  '^\+.*=\s*[A-Za-z0-9+/]\{40,\}=*[^A-Za-z0-9+/=]'

# --- Filter out known-safe files from the violations ---
# Check if violations only come from excluded file types
if [ -n "$VIOLATIONS" ]; then
  # Get staged file list to cross-check excluded extensions
  STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

  # Build a list of non-excluded staged files
  INCLUDED_FILES=""
  for FILE in $STAGED_FILES; do
    # Skip .env.example, markdown, shell scripts, test fixtures
    if [[ "$FILE" == *.env.example ]] || \
       [[ "$FILE" == *.md ]] || \
       [[ "$FILE" == *.sh ]] || \
       [[ "$FILE" == *__fixtures__* ]] || \
       [[ "$FILE" == */__mocks__/* ]] || \
       [[ "$FILE" == *.test.ts ]] || \
       [[ "$FILE" == *.test.tsx ]] || \
       [[ "$FILE" == *.spec.ts ]] || \
       [[ "$FILE" == *.spec.tsx ]]; then
      continue
    fi
    INCLUDED_FILES="$INCLUDED_FILES $FILE"
  done

  # If all staged files are excluded types, let it pass
  if [ -z "$INCLUDED_FILES" ]; then
    exit 0
  fi

  echo "Blocked: potential secrets detected in staged changes." >&2
  echo "" >&2
  echo -e "$VIOLATIONS" >&2
  echo "If this is a false positive, move the value to an environment variable" >&2
  echo "or Docker secret and reference it as process.env.VAR_NAME." >&2
  exit 2
fi

exit 0
