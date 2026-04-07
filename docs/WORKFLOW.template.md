# {{PROJECT_NAME}} — AI-Assisted Development Workflow

This page covers **{{PROJECT_NAME}}-specific** workflow extensions. The universal workflow (plan vs manifest mode, command chain, scenarios, manifest format, git rules) lives at:

> `~/Developer/claude-meta/docs/WORKFLOW.md`

Read that first. Everything below assumes you already know the universal commands (`/app-discovery`, `/evaluate-plan`, `/plan-to-tasks`, `/execute-wave`, `/checkpoint`, `/save-memory`, `/memory-maintenance`, `/audit-harness`).

## Project-specific commands

<!-- Add your project's slash commands here as you build them. Example shape:

### Discovery & audit

| Command            | What it does                                       | Output                  |
| ------------------ | -------------------------------------------------- | ----------------------- |
| `/ux-audit`        | Heuristic audit of {{PROJECT_NAME}} screens        | Scorecard + fixes       |
| `/screenshot-review [screen]` | Reviews a specific screen's quality     | Issues + concrete fixes |

### Build commands

| Command       | What it does                                              |
| ------------- | --------------------------------------------------------- |
| `/new-thing`  | Generates a new {{PROJECT_NAME}} thing from a PRD         |

-->

## CI pipeline

<!-- Document your CI here. Example:

GitHub Actions runs on every PR to `main`:

```
Build → Typecheck → Lint → Unit tests
```

Config: `.github/workflows/ci.yml`

Run the same checks locally before pushing:

```bash
{{PKG_MANAGER}} {{PREFLIGHT_CMD}}
```

-->

## File locations

| What                                 | Where                                |
| ------------------------------------ | ------------------------------------ |
| Project instructions                 | `CLAUDE.md`                          |
| Convention rules (auto-loaded)       | `.claude/rules/*.md`                 |
| Project slash commands               | `.claude/commands/*.md`              |
| Project skills                       | `.claude/skills/*/SKILL.md`          |
| Agent configs (planner, implementer) | `.claude/agents/*.md`                |
| PRDs                                 | `docs/prds/`                         |
| Plans                                | `docs/plans/[plan-name]/`            |
| Task files                           | `docs/tasks/[wave-name]/`            |
| Manifests                            | `docs/tasks/[wave-name]/MANIFEST.md` |

Universal commands and skills (e.g. `/app-discovery`, `/execute-wave`) live in `~/.claude/commands/` and `~/.claude/skills/` — see the universal WORKFLOW.md for the full list.

## Project-specific scenarios

<!-- Add 1-2 worked examples of multi-step workflows that are common in this project. Example:

### "Fix issues from a screenshot review"

```
/screenshot-review my-screen
  → 5 issues identified

/plan-to-tasks fix the 5 issues
  → writes 5 tasks, MANIFEST.md

/execute-wave docs/tasks/screen-fixes/MANIFEST.md
  → implements and commits each fix

/review     → clean
{{PKG_MANAGER}} {{PREFLIGHT_CMD}}   → green
gh pr create
```

-->
