#!/bin/bash
# architecture.sh — Import boundaries and structural enforcement
#
# Register: .claude/eval-rules.yaml  (architecture:)
# Run:      ~/.claude/evals/runner.sh architecture
#
# Global assertions are sourced by the runner before this file — don't source
# them here.

echo "Suite: architecture"
echo ""

# ── TODO: enforce your import boundary ──
# assert_no_imports_from <banned-specifier> <dir> fails if any file under <dir>
# imports from <banned-specifier>. Classic use: features must import from your
# own UI wrapper, never the underlying primitives.
#
# Uncomment and fill in once you have a boundary to enforce:
#   assert "ARCH-001: features don't import banned primitives directly" \
#     assert_no_imports_from "TODO-banned-import-specifier" "src"
#
# This stub asserts nothing yet — replace the line below with a real rule.
assert "ARCH-000: eval-rules.yaml exists (replace with real boundary rules)" \
  assert_file_exists ".claude/eval-rules.yaml"

# ── TODO: structural rules ──
#   assert "ARCH-002: no legacy framework in new service" \
#     assert_no_imports_from "express" "apps/api-v2/src"
#
# Tooling-backed rules (author the assertion in a local assertions.sh ONLY if a
# generic global one doesn't exist):
#   assert "ARCH-003: dependency-cruiser passes" assert_dep_cruiser_passes
#   assert "ARCH-004: knip clean"               assert_knip_clean

report
