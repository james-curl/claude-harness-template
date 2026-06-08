#!/bin/bash
# security.sh — Secret hygiene + project authz/boundary invariants
#
# Register: .claude/eval-rules.yaml  (security:)
# Run:      ~/.claude/evals/runner.sh security
#
# The global runner sources ~/.claude/evals/assertions.sh BEFORE this file,
# so every assert_* function is already in scope — do NOT source assertions
# here (a local copy would drift from the global one; see README "silent drift").

echo "Suite: security"
echo ""

# ── Active — secret hygiene (generic, adoptable as-is) ──
assert "SEC-001: no inline secrets in shell/config added this commit" \
  assert_no_inline_shell_secrets

assert "SEC-002: no .env files staged" \
  assert_no_env_staged

# ── TODO: project-specific authz/boundary invariants ──
# Replace these examples with your real rules, then delete this block's TODOs.
# Pattern: assert "<ID>: <human description>" <assertion_fn> <args...>
#
#   assert "SEC-003: every API route is classified" \
#     assert_all_procedures_classified "src/api"
#
#   assert "SEC-004: sensitive mutations re-fetch caller role" \
#     assert_sensitive_procedures_reauth "src/api"
#
# Gated example — skips with PENDING until the guarded code lands:
#   assert_gated "service-v2" "apps/api-v2/src/index.ts" \
#     "SEC-005: outbound fetch only via helper" \
#     assert_outbound_fetch_only "apps/api-v2/src"

report
