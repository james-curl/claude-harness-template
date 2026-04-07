#!/bin/bash
# setup.sh — Interactive setup for Claude Code harness template.
# Run this after copying the template into your project.
# It replaces {{PLACEHOLDERS}} in all template files with your values.

set -euo pipefail

# Colors
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
GREEN='\033[32m'
CYAN='\033[36m'

echo -e "${BOLD}Claude Code Harness Setup${RESET}"
echo "Answer a few questions to configure the harness for your project."
echo ""

# ── Gather inputs ──────────────────────────────────────────────────

read -rp "Project name (e.g., MyApp): " PROJECT_NAME
read -rp "One-line project description: " PROJECT_DESCRIPTION

echo ""
echo -e "${DIM}Package manager:${RESET}"
echo "  1) pnpm  2) npm  3) yarn  4) bun"
read -rp "Choice [1]: " PKG_CHOICE
case "${PKG_CHOICE:-1}" in
  1) PKG_MANAGER="pnpm" ;;
  2) PKG_MANAGER="npm" ;;
  3) PKG_MANAGER="yarn" ;;
  4) PKG_MANAGER="bun" ;;
  *) PKG_MANAGER="pnpm" ;;
esac

read -rp "Preflight/CI command name [preflight]: " PREFLIGHT_CMD
PREFLIGHT_CMD="${PREFLIGHT_CMD:-preflight}"

read -rp "Test runner command (e.g., npx vitest, npx jest) [npx vitest]: " TEST_RUNNER
TEST_RUNNER="${TEST_RUNNER:-npx vitest}"

read -rp "Typecheck command (e.g., npx tsc --noEmit) [npx tsc --noEmit]: " TYPECHECK_CMD
TYPECHECK_CMD="${TYPECHECK_CMD:-npx tsc --noEmit}"

echo ""
echo -e "${DIM}Protected paths (Claude cannot edit these):${RESET}"
echo -e "${DIM}Default: migrations/ .env .github/workflows/ docker-compose.yml${RESET}"
read -rp "Additional paths (space-separated, or press Enter for defaults only): " EXTRA_PATHS

# Build protected paths array for protect-paths.sh
DEFAULT_PATHS=("migrations/" ".env" ".github/workflows/" "docker-compose.yml")
PROTECTED_PATHS=("${DEFAULT_PATHS[@]}")
if [ -n "${EXTRA_PATHS:-}" ]; then
  read -ra EXTRA_ARRAY <<< "$EXTRA_PATHS"
  PROTECTED_PATHS+=("${EXTRA_ARRAY[@]}")
fi

# ── Confirm ────────��───────────────────────────────────────────────

echo ""
echo -e "${BOLD}Configuration:${RESET}"
echo "  Project:      $PROJECT_NAME"
echo "  Description:  $PROJECT_DESCRIPTION"
echo "  Pkg manager:  $PKG_MANAGER"
echo "  Preflight:    $PKG_MANAGER $PREFLIGHT_CMD"
echo "  Test runner:  $TEST_RUNNER"
echo "  Typecheck:    $TYPECHECK_CMD"
echo "  Protected:    ${PROTECTED_PATHS[*]}"
echo ""
read -rp "Apply? [Y/n]: " CONFIRM
if [[ "${CONFIRM:-Y}" =~ ^[Nn] ]]; then
  echo "Aborted."
  exit 0
fi

# ── Apply substitutions ─────��─────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Find all template files (md, json, sh) excluding setup.sh itself, .git, and node_modules
FILES=$(find "$SCRIPT_DIR" \
  -type f \( -name "*.md" -o -name "*.json" -o -name "*.sh" \) \
  ! -name "setup.sh" \
  ! -path "*/.git/*" \
  ! -path "*/node_modules/*")

for file in $FILES; do
  # Use | as sed delimiter to avoid conflicts with paths
  sed -i '' \
    -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    -e "s|{{PROJECT_DESCRIPTION}}|$PROJECT_DESCRIPTION|g" \
    -e "s|{{PKG_MANAGER}}|$PKG_MANAGER|g" \
    -e "s|{{PREFLIGHT_CMD}}|$PREFLIGHT_CMD|g" \
    -e "s|{{TEST_RUNNER}}|$TEST_RUNNER|g" \
    -e "s|{{TYPECHECK_CMD}}|$TYPECHECK_CMD|g" \
    "$file" 2>/dev/null || true
done

# Rebuild protect-paths.sh with the configured protected paths
PROTECT_SCRIPT="$SCRIPT_DIR/.claude/hooks/protect-paths.sh"
if [ -f "$PROTECT_SCRIPT" ]; then
  # Build the PROTECTED_PATTERNS array lines
  PATTERNS_BLOCK=""
  for path in "${PROTECTED_PATHS[@]}"; do
    PATTERNS_BLOCK+="  \"$path\"\n"
  done

  # Replace the placeholder block between markers
  sed -i '' '/^# ---PROTECTED_PATHS_START---$/,/^# ---PROTECTED_PATHS_END---$/{
    /^# ---PROTECTED_PATHS_START---$/!{/^# ---PROTECTED_PATHS_END---$/!d;}
  }' "$PROTECT_SCRIPT"

  # Insert the paths after the start marker
  ESCAPED_BLOCK=$(printf '%s' "$PATTERNS_BLOCK" | sed 's/[&/\]/\\&/g')
  sed -i '' "/^# ---PROTECTED_PATHS_START---$/a\\
$(echo -e "$PATTERNS_BLOCK")" "$PROTECT_SCRIPT"
fi

# Rename CLAUDE.template.md if it exists
if [ -f "$SCRIPT_DIR/CLAUDE.template.md" ]; then
  mv "$SCRIPT_DIR/CLAUDE.template.md" "$SCRIPT_DIR/CLAUDE.md"
  echo -e "${GREEN}Renamed CLAUDE.template.md → CLAUDE.md${RESET}"
fi

# Rename settings.template.json if it exists
if [ -f "$SCRIPT_DIR/.claude/settings.template.json" ]; then
  mv "$SCRIPT_DIR/.claude/settings.template.json" "$SCRIPT_DIR/.claude/settings.json"
  echo -e "${GREEN}Renamed settings.template.json → settings.json${RESET}"
fi

# Make all hooks executable
chmod +x "$SCRIPT_DIR"/.claude/hooks/*.sh 2>/dev/null || true

echo ""
echo -e "${GREEN}${BOLD}Harness configured for $PROJECT_NAME.${RESET}"
echo ""
echo "Next steps:"
echo "  1. Review CLAUDE.md and fill in the Architecture section"
echo "  2. Add project-specific rules in .claude/rules/"
echo "  3. git add .claude/ CLAUDE.md && git commit -m 'chore: add Claude Code harness'"
echo ""
echo -e "${DIM}Tip: Run /verify in Claude Code to check your setup.${RESET}"
