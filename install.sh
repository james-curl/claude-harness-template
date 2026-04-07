#!/bin/bash
# install.sh — Install or update the Claude Code harness in any project.
#
# Modes:
#   install.sh                    New project: copies .claude/, runs questionnaire.
#   install.sh                    Existing project: adds missing files only (safe merge).
#   install.sh --update           Existing project: overwrites generic files with latest
#                                 from template. Preserves CLAUDE.md & settings.json.
#   install.sh --full-scaffold    Also installs docs/plans/ + docs/tasks/ skeletons
#                                 (the project-tracking convention). Combine with
#                                 --update to upgrade an existing scaffold.
#   install.sh /path              Target a specific directory.
#   install.sh --update /path
#   install.sh --full-scaffold /path
#
# Usage:
#   cd ~/Developer/my-project && bash ~/Developer/claude-harness-template/install.sh
#   bash ~/Developer/claude-harness-template/install.sh --update ~/Developer/my-project
#   bash ~/Developer/claude-harness-template/install.sh --full-scaffold ~/Developer/new-project
#
# Prerequisites (global):
#   ~/.claude/rules/agent-directives.md   — universal agent behavior
#   ~/.claude/evals/                      — eval runner, assertions, autoresearch
#   ~/.claude/commands/autoresearch.md    — prompt improvement loop
#   ~/.claude/commands/checkpoint.md      — git safety snapshots
#   ~/.claude/commands/save-memory.md     — persist learnings
#   ~/.claude/skills/verify/              — build + typecheck + lint + tests
#   ~/.claude/skills/debug/               — structured debugging
#   ~/.claude/skills/review/              — code review
#   ~/.claude/skills/freeze/              — session-level read-only paths
#   ~/.claude/skills/plan-exit-review/    — scope challenge + plan review
#   ~/.claude/skills/commit-push-pr/      — full git workflow

set -euo pipefail

# ── Parse arguments ───────────────────────────────────────────────

UPDATE=false
FULL_SCAFFOLD=false
TARGET_ARG=""

for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=true ;;
    --full-scaffold) FULL_SCAFFOLD=true ;;
    *) TARGET_ARG="$arg" ;;
  esac
done

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${TARGET_ARG:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Colors
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BLUE='\033[34m'
RED='\033[31m'

# ── Check global prerequisites ───────────────────────────────────

MISSING_GLOBALS=()
[ -f "$HOME/.claude/rules/agent-directives.md" ] || MISSING_GLOBALS+=("~/.claude/rules/agent-directives.md")
[ -f "$HOME/.claude/evals/runner.sh" ]           || MISSING_GLOBALS+=("~/.claude/evals/runner.sh")
[ -f "$HOME/.claude/commands/autoresearch.md" ]   || MISSING_GLOBALS+=("~/.claude/commands/autoresearch.md")

if [ ${#MISSING_GLOBALS[@]} -gt 0 ]; then
  echo -e "${YELLOW}Warning: Missing global prerequisites:${RESET}"
  for m in "${MISSING_GLOBALS[@]}"; do
    echo -e "  ${RED}✗${RESET} $m"
  done
  echo ""
  echo -e "${DIM}The harness template relies on global files in ~/.claude/ for agent directives,${RESET}"
  echo -e "${DIM}eval infrastructure, and shared skills/commands. Install those first, or run${RESET}"
  echo -e "${DIM}the global installer if one is available.${RESET}"
  echo ""
  read -rp "Continue anyway? [y/N]: " CONTINUE
  if [[ ! "${CONTINUE:-N}" =~ ^[Yy] ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# ── Detect mode ───────────────────────────────────────────────────

HAS_CLAUDE_DIR=false
[ -d "$TARGET_DIR/.claude" ] && HAS_CLAUDE_DIR=true

if [ "$UPDATE" = true ]; then
  if [ "$HAS_CLAUDE_DIR" = false ]; then
    echo "Error: --update requires an existing .claude/ directory. Run without --update for first install." >&2
    exit 1
  fi
  MODE="update"
  echo -e "${BOLD}Updating Claude Code harness${RESET} (overwrite generic files, preserve project-specific)"
elif [ "$HAS_CLAUDE_DIR" = true ]; then
  MODE="existing"
  echo -e "${BOLD}Installing Claude Code harness${RESET} (existing project — add missing files only)"
else
  MODE="new"
  echo -e "${BOLD}Installing Claude Code harness${RESET} (new project)"
fi

echo -e "${DIM}Template: $TEMPLATE_DIR${RESET}"
echo -e "${DIM}Target:   $TARGET_DIR${RESET}"
echo ""

# ── Gather configuration ─────────────────────────────────────────
# Skip questionnaire on --update if a .harness-config exists

CONFIG_FILE="$TARGET_DIR/.claude/.harness-config"
SKIP_QUESTIONS=false

if [ "$MODE" = "update" ] && [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
  SKIP_QUESTIONS=true
  echo -e "${DIM}Using saved config from .claude/.harness-config${RESET}"
  echo "  Project:      $PROJECT_NAME"
  echo "  Pkg manager:  $PKG_MANAGER"
  echo "  Preflight:    $PKG_MANAGER $PREFLIGHT_CMD"
  echo "  Test runner:  $TEST_RUNNER"
  echo "  Typecheck:    $TYPECHECK_CMD"
  echo ""
  read -rp "Use these settings? [Y/n]: " USE_SAVED
  if [[ "${USE_SAVED:-Y}" =~ ^[Nn] ]]; then
    SKIP_QUESTIONS=false
  fi
fi

if [ "$SKIP_QUESTIONS" = false ]; then
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
  read -rp "Additional paths (space-separated, or Enter for defaults): " EXTRA_PATHS
fi

# ── Confirm ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Configuration:${RESET}"
echo "  Mode:         $MODE"
if [ "$FULL_SCAFFOLD" = true ]; then
  echo "  Scaffold:     full (.claude/ + docs/plans/ + docs/tasks/)"
else
  echo "  Scaffold:     .claude/ only ${DIM}(use --full-scaffold for project tracking)${RESET}"
fi
echo "  Project:      $PROJECT_NAME"
echo "  Pkg manager:  $PKG_MANAGER"
echo "  Preflight:    $PKG_MANAGER $PREFLIGHT_CMD"
echo "  Test runner:  $TEST_RUNNER"
echo "  Typecheck:    $TYPECHECK_CMD"
echo ""
read -rp "Apply? [Y/n]: " CONFIRM
if [[ "${CONFIRM:-Y}" =~ ^[Nn] ]]; then
  echo "Aborted."
  exit 0
fi

# ── Save config for future --update runs ──────────────────────────

mkdir -p "$TARGET_DIR/.claude"
cat > "$CONFIG_FILE" <<CONF
# Auto-generated by install.sh — used by --update to skip the questionnaire.
PROJECT_NAME="$PROJECT_NAME"
PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-}"
PKG_MANAGER="$PKG_MANAGER"
PREFLIGHT_CMD="$PREFLIGHT_CMD"
TEST_RUNNER="$TEST_RUNNER"
TYPECHECK_CMD="$TYPECHECK_CMD"
EXTRA_PATHS="${EXTRA_PATHS:-}"
CONF

# ── Helper: apply placeholder substitutions to a file ─────────────

apply_subs() {
  local file="$1"
  sed -i '' \
    -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    -e "s|{{PROJECT_DESCRIPTION}}|${PROJECT_DESCRIPTION:-}|g" \
    -e "s|{{PKG_MANAGER}}|$PKG_MANAGER|g" \
    -e "s|{{PREFLIGHT_CMD}}|$PREFLIGHT_CMD|g" \
    -e "s|{{TEST_RUNNER}}|$TEST_RUNNER|g" \
    -e "s|{{TYPECHECK_CMD}}|$TYPECHECK_CMD|g" \
    -e "s|{{UI_PACKAGE}}|$PROJECT_NAME/ui|g" \
    "$file" 2>/dev/null || true
}

# ── Helper: install a single file ─────────────────────────────────

install_file() {
  local src="$1"
  local dst="$2"
  local name
  name="$(basename "$dst")"

  if [ "$MODE" = "update" ]; then
    # Update mode: overwrite, show what changed
    mkdir -p "$(dirname "$dst")"
    if [ -f "$dst" ]; then
      cp "$src" "$dst"
      apply_subs "$dst"
      echo -e "  ${BLUE}update${RESET} $name"
    else
      cp "$src" "$dst"
      apply_subs "$dst"
      echo -e "  ${GREEN}add${RESET}    $name"
    fi
    return 0
  else
    # Install mode: skip existing
    if [ -f "$dst" ]; then
      echo -e "  ${DIM}skip${RESET}   $name (already exists)"
      return 1
    else
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      apply_subs "$dst"
      echo -e "  ${GREEN}add${RESET}    $name"
      return 0
    fi
  fi
}

ADDED=0
UPDATED=0
SKIPPED=0

# ── Create directories ────────────────────────────────────────────

mkdir -p "$TARGET_DIR/.claude"/{hooks,rules,agents,commands,skills,evals/suites}

# ── Install hooks ─────────────────────────────────────────────────

echo -e "${CYAN}Hooks:${RESET}"
for src in "$TEMPLATE_DIR"/.claude/hooks/*.sh; do
  [ -f "$src" ] || continue
  name="$(basename "$src")"
  dst="$TARGET_DIR/.claude/hooks/$name"
  if [ "$MODE" = "update" ] && [ -f "$dst" ]; then
    install_file "$src" "$dst" && ((UPDATED++))
  elif install_file "$src" "$dst"; then
    ((ADDED++))
  else
    ((SKIPPED++))
  fi
done

# ── Install agents ────────────────────────────────────────────────

echo -e "${CYAN}Agents:${RESET}"
for src in "$TEMPLATE_DIR"/.claude/agents/*.md; do
  [ -f "$src" ] || continue
  name="$(basename "$src")"
  dst="$TARGET_DIR/.claude/agents/$name"
  if [ "$MODE" = "update" ] && [ -f "$dst" ]; then
    install_file "$src" "$dst" && ((UPDATED++))
  elif install_file "$src" "$dst"; then
    ((ADDED++))
  else
    ((SKIPPED++))
  fi
done

# ── Install settings.json (never overwritten) ─────────────────────

echo -e "${CYAN}Settings:${RESET}"
if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
  echo -e "  ${DIM}skip${RESET}   settings.json (always preserved — merge hooks manually)"
  SKIPPED=$((SKIPPED + 1))
else
  cp "$TEMPLATE_DIR/.claude/settings.template.json" "$TARGET_DIR/.claude/settings.json"
  apply_subs "$TARGET_DIR/.claude/settings.json"
  echo -e "  ${GREEN}add${RESET}    settings.json"
  ADDED=$((ADDED + 1))
fi

# ── Install CLAUDE.md (never overwritten) ─────────────────────────

echo -e "${CYAN}CLAUDE.md:${RESET}"
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  echo -e "  ${DIM}skip${RESET}   CLAUDE.md (always preserved)"
  SKIPPED=$((SKIPPED + 1))
else
  cp "$TEMPLATE_DIR/CLAUDE.template.md" "$TARGET_DIR/CLAUDE.md"
  apply_subs "$TARGET_DIR/CLAUDE.md"
  echo -e "  ${GREEN}add${RESET}    CLAUDE.md"
  ADDED=$((ADDED + 1))
fi

# ── Install docs/WORKFLOW.md (never overwritten) ──────────────────

echo -e "${CYAN}docs/WORKFLOW.md:${RESET}"
if [ -f "$TARGET_DIR/docs/WORKFLOW.md" ]; then
  echo -e "  ${DIM}skip${RESET}   docs/WORKFLOW.md (always preserved)"
  SKIPPED=$((SKIPPED + 1))
else
  mkdir -p "$TARGET_DIR/docs"
  cp "$TEMPLATE_DIR/docs/WORKFLOW.template.md" "$TARGET_DIR/docs/WORKFLOW.md"
  apply_subs "$TARGET_DIR/docs/WORKFLOW.md"
  echo -e "  ${GREEN}add${RESET}    docs/WORKFLOW.md ${DIM}(points at universal workflow at ~/Developer/claude-meta/docs/WORKFLOW.md)${RESET}"
  ADDED=$((ADDED + 1))
fi

# ── Install docs/plans/ + docs/tasks/ scaffolds (--full-scaffold) ─

if [ "$FULL_SCAFFOLD" = true ]; then
  echo -e "${CYAN}Project tracking scaffold (--full-scaffold):${RESET}"

  # docs/plans/README.md
  if [ -f "$TARGET_DIR/docs/plans/README.md" ]; then
    echo -e "  ${DIM}skip${RESET}   docs/plans/README.md (already exists)"
    SKIPPED=$((SKIPPED + 1))
  else
    mkdir -p "$TARGET_DIR/docs/plans"
    cp "$TEMPLATE_DIR/docs/plans/README.template.md" "$TARGET_DIR/docs/plans/README.md"
    apply_subs "$TARGET_DIR/docs/plans/README.md"
    echo -e "  ${GREEN}add${RESET}    docs/plans/README.md"
    ADDED=$((ADDED + 1))
  fi

  # docs/plans/_template/*.md (5 files)
  mkdir -p "$TARGET_DIR/docs/plans/_template"
  for src in "$TEMPLATE_DIR"/docs/plans/_template/*.template.md; do
    [ -f "$src" ] || continue
    name="$(basename "$src" .template.md).md"
    dst="$TARGET_DIR/docs/plans/_template/$name"
    if [ -f "$dst" ]; then
      echo -e "  ${DIM}skip${RESET}   docs/plans/_template/$name (already exists)"
      SKIPPED=$((SKIPPED + 1))
    else
      cp "$src" "$dst"
      apply_subs "$dst"
      echo -e "  ${GREEN}add${RESET}    docs/plans/_template/$name"
      ADDED=$((ADDED + 1))
    fi
  done

  # docs/tasks/README.md
  if [ -f "$TARGET_DIR/docs/tasks/README.md" ]; then
    echo -e "  ${DIM}skip${RESET}   docs/tasks/README.md (already exists)"
    SKIPPED=$((SKIPPED + 1))
  else
    mkdir -p "$TARGET_DIR/docs/tasks"
    cp "$TEMPLATE_DIR/docs/tasks/README.template.md" "$TARGET_DIR/docs/tasks/README.md"
    apply_subs "$TARGET_DIR/docs/tasks/README.md"
    echo -e "  ${GREEN}add${RESET}    docs/tasks/README.md"
    ADDED=$((ADDED + 1))
  fi

  # docs/tasks/_template/MANIFEST.md
  mkdir -p "$TARGET_DIR/docs/tasks/_template"
  if [ -f "$TARGET_DIR/docs/tasks/_template/MANIFEST.md" ]; then
    echo -e "  ${DIM}skip${RESET}   docs/tasks/_template/MANIFEST.md (already exists)"
    SKIPPED=$((SKIPPED + 1))
  else
    cp "$TEMPLATE_DIR/docs/tasks/_template/MANIFEST.template.md" \
       "$TARGET_DIR/docs/tasks/_template/MANIFEST.md"
    apply_subs "$TARGET_DIR/docs/tasks/_template/MANIFEST.md"
    echo -e "  ${GREEN}add${RESET}    docs/tasks/_template/MANIFEST.md"
    ADDED=$((ADDED + 1))
  fi
fi

# ── Configure protect-paths.sh ────────────────────────────────────

PROTECT_SCRIPT="$TARGET_DIR/.claude/hooks/protect-paths.sh"
if [ -f "$PROTECT_SCRIPT" ] && grep -q "PROTECTED_PATHS_START" "$PROTECT_SCRIPT"; then
  DEFAULT_PATHS=("migrations/" ".env" ".github/workflows/" "docker-compose.yml")
  ALL_PATHS=("${DEFAULT_PATHS[@]}")
  if [ -n "${EXTRA_PATHS:-}" ]; then
    read -ra EXTRA_ARRAY <<< "${EXTRA_PATHS:-}"
    ALL_PATHS+=("${EXTRA_ARRAY[@]}")
  fi

  BLOCK=""
  for p in "${ALL_PATHS[@]}"; do
    BLOCK+="  \"$p\""$'\n'
  done

  perl -i -0pe "
    s/(# ---PROTECTED_PATHS_START---\n).*?(# ---PROTECTED_PATHS_END---)/\${1}${BLOCK}\${2}/s
  " "$PROTECT_SCRIPT" 2>/dev/null || true
fi

# ── Make hooks executable ─────────────────────────────────────────

chmod +x "$TARGET_DIR"/.claude/hooks/*.sh 2>/dev/null || true

# ── Summary ───────────────────────────────────────────────────────

echo ""
if [ "$MODE" = "update" ]; then
  echo -e "${GREEN}${BOLD}Done!${RESET} $UPDATED updated, $ADDED added, $SKIPPED preserved"
else
  echo -e "${GREEN}${BOLD}Done!${RESET} $ADDED added, $SKIPPED skipped (already existed)"
fi
echo -e "${DIM}Config saved to .claude/.harness-config (used by future --update runs)${RESET}"
echo ""

# ── Global layer info ─────────────────────────────────────────────

echo -e "${CYAN}Global layer (from ~/.claude/):${RESET}"
GLOBAL_ITEMS=(
  "rules/agent-directives.md"
  "evals/runner.sh"
  "evals/assertions.sh"
  "evals/autoresearch.sh"
  "commands/autoresearch.md"
)
for item in "${GLOBAL_ITEMS[@]}"; do
  if [ -e "$HOME/.claude/$item" ]; then
    echo -e "  ${GREEN}✓${RESET} $item"
  else
    echo -e "  ${RED}✗${RESET} $item ${DIM}(missing)${RESET}"
  fi
done
echo ""

# ── Shadow scan (project files that silently override global) ────

echo -e "${CYAN}Shadow scan:${RESET}"
SHADOW_COUNT=0

# Skills: project skill name == global skill name
if [ -d "$TARGET_DIR/.claude/skills" ] && [ -d "$HOME/.claude/skills" ]; then
  for skill_dir in "$TARGET_DIR/.claude/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    if [ -d "$HOME/.claude/skills/$skill_name" ]; then
      echo -e "  ${YELLOW}!${RESET} skill ${BOLD}$skill_name${RESET} shadows ~/.claude/skills/$skill_name/"
      SHADOW_COUNT=$((SHADOW_COUNT + 1))
    fi
  done
fi

# Commands: project command file name == global command file name
if [ -d "$TARGET_DIR/.claude/commands" ] && [ -d "$HOME/.claude/commands" ]; then
  for cmd_file in "$TARGET_DIR/.claude/commands"/*.md; do
    [ -f "$cmd_file" ] || continue
    cmd_name="$(basename "$cmd_file")"
    if [ -f "$HOME/.claude/commands/$cmd_name" ]; then
      echo -e "  ${YELLOW}!${RESET} command ${BOLD}${cmd_name%.md}${RESET} shadows ~/.claude/commands/$cmd_name"
      SHADOW_COUNT=$((SHADOW_COUNT + 1))
    fi
  done
fi

# Rules: project rule file name == global rule file name
if [ -d "$TARGET_DIR/.claude/rules" ] && [ -d "$HOME/.claude/rules" ]; then
  for rule_file in "$TARGET_DIR/.claude/rules"/*.md; do
    [ -f "$rule_file" ] || continue
    rule_name="$(basename "$rule_file")"
    if [ -f "$HOME/.claude/rules/$rule_name" ]; then
      echo -e "  ${YELLOW}!${RESET} rule ${BOLD}${rule_name%.md}${RESET} shadows ~/.claude/rules/$rule_name"
      SHADOW_COUNT=$((SHADOW_COUNT + 1))
    fi
  done
fi

if [ $SHADOW_COUNT -eq 0 ]; then
  echo -e "  ${GREEN}✓${RESET} no shadows ${DIM}(project files don't silently override global)${RESET}"
else
  echo ""
  echo -e "  ${DIM}Each shadow is a fork that won't see global updates. Either:${RESET}"
  echo -e "  ${DIM}  1. Delete the project copy if the global one suffices, or${RESET}"
  echo -e "  ${DIM}  2. Document why the project version is intentionally different${RESET}"
  echo -e "  ${DIM}     (e.g., in .claude/README.md). Run /audit-harness anytime to re-scan.${RESET}"
fi
echo ""

# ── Post-install guidance ─────────────────────────────────────────

if [ "$MODE" = "update" ]; then
  echo -e "${BOLD}Updated files:${RESET}"
  echo "  Review changes with: cd $TARGET_DIR && git diff .claude/"
  echo ""
  echo -e "${DIM}settings.json and CLAUDE.md are never overwritten.${RESET}"
  echo -e "${DIM}If the template added new hooks, wire them in settings.json manually.${RESET}"

elif [ "$MODE" = "existing" ] && [ $SKIPPED -gt 0 ]; then
  echo -e "${BOLD}Manual steps for existing project:${RESET}"
  echo ""
  if grep -q "hooks" "$TARGET_DIR/.claude/settings.json" 2>/dev/null; then
    echo "  1. Merge new hook wiring into your settings.json"
    echo "     Reference: $TEMPLATE_DIR/.claude/settings.template.json"
    echo ""
  fi
  echo "  2. Review your CLAUDE.md — consider adding:"
  echo "     - Critical Agent Rules section (see template)"
  echo "     - Agent directives are loaded globally from ~/.claude/rules/"
  echo ""
fi

echo -e "${BOLD}Next steps:${RESET}"
echo "  git add .claude/ CLAUDE.md"
echo "  git commit -m 'chore: $([ "$MODE" = "update" ] && echo "update" || echo "add") Claude Code harness'"
echo ""
echo -e "${DIM}Tip: Run /verify in Claude Code to test your setup.${RESET}"
