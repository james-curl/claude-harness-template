#!/bin/bash
# code-hygiene.sh — File size, comment quality, debug-statement bans
#
# Register: .claude/eval-rules.yaml  (code_hygiene:)
# Run:      ~/.claude/evals/runner.sh code-hygiene
#
# These map to generic global assertions and apply to almost any codebase.
# Usually adoptable as-is — tune the line ceiling and delete what you don't want.
# Global assertions are sourced by the runner before this file.

echo "Suite: code-hygiene"
echo ""

# ── No oversized files (whole tree) ──
# TODO: tune the ceiling. 600 is a reasonable default; lower it as you split files.
assert "HYG-001: no source file exceeds 600 lines" \
  assert_no_files_over_lines 600

# ── No robotic boilerplate comments added this commit ──
assert "HYG-002: no corporate/section-banner comments added" \
  assert_no_corporate_comments

# ── No stray debug statements added to non-trivial files ──
assert "HYG-003: no debug statements added to large files" \
  assert_no_debug_statements_in_large_files

report
