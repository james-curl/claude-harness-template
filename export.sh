#!/bin/bash
# export.sh — Export generic harness files from any project back to this template.
#
# Reads the source project's .claude/harness-export.json manifest to determine
# which files are generic (portable). Copies them here and applies placeholder
# substitutions so they're ready for install.sh to deploy elsewhere.
#
# Usage:
#   bash ~/Developer/claude-harness-template/export.sh ~/Developer/my-project
#   bash ~/Developer/claude-harness-template/export.sh  # uses cwd as source

set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="${1:-.}"
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"

MANIFEST="$SOURCE_DIR/.claude/harness-export.json"

# Colors
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'

if [ ! -f "$MANIFEST" ]; then
  echo "Error: No .claude/harness-export.json found in $SOURCE_DIR" >&2
  echo "" >&2
  echo "To use export, add a harness-export.json manifest to your project." >&2
  echo "See the template README for the manifest format." >&2
  exit 1
fi

echo -e "${BOLD}Exporting harness: $SOURCE_DIR → $TEMPLATE_DIR${RESET}"
echo ""

# ── Helper: read arrays from JSON manifest ──────────────────────

read_array() {
  local path="$1"
  jq -r "$path // [] | .[]" "$MANIFEST"
}

# ── Helper: apply placeholder substitutions ──────────────────────

apply_subs() {
  local file="$1"
  while IFS=$'\t' read -r key value; do
    [ -z "$key" ] && continue
    perl -pi -e "
      \$key = quotemeta('$key');
      \$val = '$value';
      s/\$key/\$val/g;
    " "$file" 2>/dev/null || true
  done < <(jq -r '.substitutions | to_entries[] | "\(.key)\t\(.value)"' "$MANIFEST")
}

COPIED=0
SKIPPED=0

# ── Export hooks ──────────────────────────────────────────────────

echo -e "${CYAN}Hooks:${RESET}"
for hook in $(read_array '.hooks.generic'); do
  src="$SOURCE_DIR/.claude/hooks/$hook"
  dst="$TEMPLATE_DIR/.claude/hooks/$hook"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    apply_subs "$dst"
    echo -e "  ${GREEN}export${RESET} $hook"
    ((COPIED++))
  else
    echo -e "  ${YELLOW}miss${RESET}   $hook (not found in source)"
    ((SKIPPED++))
  fi
done

# ── Export rules ──────────────────────────────────────────────────

echo -e "${CYAN}Rules:${RESET}"
for rule in $(read_array '.rules.generic'); do
  src="$SOURCE_DIR/.claude/rules/$rule"
  dst="$TEMPLATE_DIR/.claude/rules/$rule"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    apply_subs "$dst"
    echo -e "  ${GREEN}export${RESET} $rule"
    ((COPIED++))
  else
    echo -e "  ${YELLOW}miss${RESET}   $rule (not found in source)"
    ((SKIPPED++))
  fi
done

# ── Export agents ─────────────────────────────────────────────────

echo -e "${CYAN}Agents:${RESET}"
for agent in $(read_array '.agents.generic'); do
  src="$SOURCE_DIR/.claude/agents/$agent"
  dst="$TEMPLATE_DIR/.claude/agents/$agent"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    apply_subs "$dst"
    echo -e "  ${GREEN}export${RESET} $agent"
    ((COPIED++))
  else
    echo -e "  ${YELLOW}miss${RESET}   $agent (not found in source)"
    ((SKIPPED++))
  fi
done

# ── Export commands ────────────────────────────────────────────────

echo -e "${CYAN}Commands:${RESET}"
for cmd in $(read_array '.commands.generic'); do
  src="$SOURCE_DIR/.claude/commands/$cmd"
  dst="$TEMPLATE_DIR/.claude/commands/$cmd"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    apply_subs "$dst"
    echo -e "  ${GREEN}export${RESET} $cmd"
    ((COPIED++))
  else
    echo -e "  ${YELLOW}miss${RESET}   $cmd (not found in source)"
    ((SKIPPED++))
  fi
done

# ── Export skills (directory-based) ───────────────────────────────

echo -e "${CYAN}Skills:${RESET}"
for skill in $(read_array '.skills.generic'); do
  src="$SOURCE_DIR/.claude/skills/$skill"
  dst="$TEMPLATE_DIR/.claude/skills/$skill"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    find "$src" -type f | while read -r file; do
      rel="${file#$src/}"
      mkdir -p "$(dirname "$dst/$rel")"
      cp "$file" "$dst/$rel"
      apply_subs "$dst/$rel"
    done
    echo -e "  ${GREEN}export${RESET} $skill/"
    ((COPIED++))
  else
    echo -e "  ${YELLOW}miss${RESET}   $skill/ (not found in source)"
    ((SKIPPED++))
  fi
done

# ── Make hooks executable ─────────────────────────────────────────

chmod +x "$TEMPLATE_DIR"/.claude/hooks/*.sh 2>/dev/null || true

# ── Summary ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Export complete:${RESET} $COPIED exported, $SKIPPED missing"

# Show git diff if template repo is a git repo
if [ -d "$TEMPLATE_DIR/.git" ]; then
  echo ""
  CHANGES=$(cd "$TEMPLATE_DIR" && git diff --stat 2>/dev/null || true)
  if [ -n "$CHANGES" ]; then
    echo -e "${DIM}Changes in template repo:${RESET}"
    echo "$CHANGES"
    echo ""
    echo -e "${DIM}Review with: cd $TEMPLATE_DIR && git diff${RESET}"
    echo -e "${DIM}Commit with: cd $TEMPLATE_DIR && git add -A && git commit -m 'chore: sync harness from $(basename "$SOURCE_DIR")'${RESET}"
  else
    echo -e "${DIM}No changes detected in template repo.${RESET}"
  fi
fi
