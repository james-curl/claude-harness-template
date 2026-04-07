# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Architecture

<!-- Describe your project structure, key directories, tech stack -->

## Hard Rules

- TypeScript strict mode, no `any` types
- All secrets via environment variables — never hardcode credentials
<!-- Add project-specific hard rules here -->

## Commands

- `{{PKG_MANAGER}} dev` — start dev server
- `{{PKG_MANAGER}} test` — run tests (watch mode)
- `{{PKG_MANAGER}} test --run` — run tests once
- `{{PKG_MANAGER}} typecheck` — typecheck all packages
- `{{PKG_MANAGER}} build` — build all packages
- `{{PKG_MANAGER}} lint` — lint all packages
- `{{PKG_MANAGER}} {{PREFLIGHT_CMD}}` — full CI check (build + typecheck + lint + tests)

## Critical Agent Rules

These 5 rules are non-negotiable. Full directives in @.claude/rules/agent-directives.md.

1. **Forced Verification** — never report "done" without running `{{PKG_MANAGER}} typecheck` and `{{PKG_MANAGER}} lint`. Fix all errors.
2. **Context Decay** — after 10+ messages, re-read any file before editing. Your memory is stale.
3. **Edit Integrity** — re-read before every edit, verify after. The Edit tool fails silently on stale context.
4. **Phased Execution** — max 5 files per phase. Verify, get approval, then next phase.
5. **Senior Dev Override** — if architecture is flawed, fix it. Don't do band-aids.

## Git Workflow

- **Always work on a branch** — never commit directly to main
- Branch naming: `feature/short-name`, `fix/short-name`, `docs/short-name`
- Push branch, create PR via `gh pr create`, squash-merge via GitHub
- One logical change per PR
- Run `{{PKG_MANAGER}} {{PREFLIGHT_CMD}}` before raising a PR

## Key References (read on-demand, not auto-loaded)

- docs/WORKFLOW.md — {{PROJECT_NAME}}-specific workflow (build commands, file locations, CI). Points to the universal workflow at `~/Developer/claude-meta/docs/WORKFLOW.md` for the command chain, scenarios, manifest format, and git rules
  <!-- Add more paths to reference docs as you create them -->
  <!-- - .claude/reference/api-patterns.md -->
  <!-- - .claude/reference/testing.md -->

## Domain-Specific Rules

Global rules (auto-loaded via @.claude/rules/):

- Agent directives — @.claude/rules/agent-directives.md
  <!-- Add more rules files as you create them -->
  <!-- - Data model — @.claude/rules/data-model.md -->
  <!-- - Styling — @.claude/rules/styling-patterns.md -->

## Execution Workflow

Workflow lives in two places (read on demand, not auto-loaded):

- **Universal workflow** — `~/Developer/claude-meta/docs/WORKFLOW.md`. Plan vs manifest mode, command chain (`/app-discovery → /evaluate-plan → /plan-to-tasks → /execute-wave`), manifest format, git rules. Applies to every project.
- **Project overrides** — `docs/WORKFLOW.md`. Project-specific commands, build helpers, file locations, scenario examples.

Read both when starting multi-step planning work. For a quick single-session fix, use plan mode without slash commands.

## Long-Running Plans

When a plan spans multiple sessions (3+ phases, 10+ files), scaffold tracking files in `docs/plans/<plan-name>/`:

```
docs/plans/<plan-name>/
+-- PLAN.md          — Full plan (the what and how)
+-- PROGRESS.md      — Phase-by-phase checklist + session log
+-- DECISIONS.md     — Design decisions with rationale
+-- ISSUES.md        — Problems found and resolutions
```

**Session protocol:**

- Start: read PROGRESS.md
- During: update PROGRESS.md after each commit
- End: update session log, commit support files with code changes
