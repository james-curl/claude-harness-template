# Claude Code Harness Template

A production-grade `.claude/` configuration for any project. Extracted from a real-world monorepo harness that evolved over months of daily Claude Code use.

Gives you deterministic guardrails (hooks), team agent scaffolds, and a CLAUDE.md template — all configured for your project with one command. Universal behavior (agent directives, skills, commands, evals) lives globally in `~/.claude/` and applies to every project automatically.

## Architecture: Global vs Project-Local

The harness uses a two-layer model. Understanding this is key to working with it.

```
~/.claude/                          ← Global layer (universal, all projects)
├── rules/agent-directives.md       ← How Claude behaves (phased execution, edit safety, etc.)
├── evals/                          ← Eval runner, assertions, autoresearch loop
├── commands/                       ← /autoresearch, /checkpoint, /save-memory, etc.
└── skills/                         ← /verify, /debug, /review, /freeze, /commit-push-pr, etc.

your-project/.claude/               ← Project layer (specific to this codebase)
├── hooks/                          ← Hard enforcement (block commits to main, secrets scan, etc.)
├── agents/                         ← Team mode roles (planner, implementer)
├── rules/                          ← Project-specific rules (data model, styling, API patterns)
├── commands/                       ← Project-specific commands
├── skills/                         ← Project-specific skills
├── evals/suites/                   ← Project-specific eval suites (use global assertions)
└── settings.json                   ← Hook wiring + permissions
```

**Global layer** — installed once per machine, applies everywhere. Agent directives, shared skills (`/verify`, `/debug`, `/review`, `/freeze`, `/plan-exit-review`, `/commit-push-pr`), shared commands (`/checkpoint`, `/save-memory`, `/memory-maintenance`, `/health-check`, `/prompt-audit`, `/autoresearch`), and the eval infrastructure.

**Project layer** — installed per project via this template. Hooks (hard enforcement that references project commands/paths), team agents (with project-specific placeholders), and a CLAUDE.md scaffold. Projects add their own rules, commands, skills, and eval suites here.

Claude Code loads both layers automatically — global rules/skills are always available, project-local ones extend or override them.

### Precedence: project-local wins, silently

When a file exists at the **same relative path** in both layers, **project-local always wins**. Claude Code does not warn about the collision. This is the harness's single biggest footgun.

Example: if `~/.claude/commands/verify.md` exists AND `your-project/.claude/commands/verify.md` exists, the project-local version is the one that runs when you type `/verify` inside that project. The global version is ignored for that session — no warning, no diff, no log line.

**Why this matters:** a project-local file that started as a copy of the global drifts over time. You fix a bug in the global, but projects that shadow it never see the fix. You add a new global skill, but if a project already shadows its directory-level scaffolding, it may not pick it up cleanly. This is "silent drift" — the project passively diverges from the canonical behavior you thought you were getting.

**Rule of thumb:** only keep a project-local file if it is _genuinely_ project-specific. If it is 99% the same as the global, delete the project copy and let the global win. If the project needs a small tweak, extend the global via a rule or add a separate project-specific file — do not copy-and-modify.

**Auditing for shadows:** run the `/audit-harness` command (installed globally) from any project root:

```bash
/audit-harness                                    # audit current directory
/audit-harness ~/Developer/my-project             # audit a specific project
/audit-harness ~/Developer/my-project audit.md    # also write report to a file
```

The audit lists every file under `.claude/{skills,commands,rules,agents}/` whose path collides with `~/.claude/`, classifies each as IDENTICAL (safe to delete) or DIFFERS (needs review), counts legitimate project-only files, and flags orphaned worktrees under `.claude/worktrees/`. Run it on any project where you suspect drift — or periodically as hygiene.

## Quick Start

```bash
cd ~/Developer/your-project
bash ~/Developer/claude-harness-template/install.sh
```

The installer checks for global prerequisites first, then detects new vs existing projects and handles both.

## Prerequisites

The template assumes global files are installed in `~/.claude/`. The installer warns if these are missing:

| File                                  | Purpose                                                                |
| ------------------------------------- | ---------------------------------------------------------------------- |
| `~/.claude/rules/agent-directives.md` | Universal agent behavior (phased execution, edit safety, verification) |
| `~/.claude/evals/runner.sh`           | Eval suite runner (project-local suites first, global fallback)        |
| `~/.claude/evals/assertions.sh`       | Reusable assertion library (auto-detects package manager)              |
| `~/.claude/evals/autoresearch.sh`     | Karpathy-style prompt improvement loop                                 |
| `~/.claude/commands/autoresearch.md`  | `/autoresearch` slash command                                          |

Skills and commands in `~/.claude/skills/` and `~/.claude/commands/` are also expected but not checked individually.

## Lifecycle

| Operation         | Command                              | When                                                                      |
| ----------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| **Install**       | `install.sh [/path]`                 | New or existing project — adds `.claude/` + CLAUDE.md + WORKFLOW.md       |
| **Full scaffold** | `install.sh --full-scaffold [/path]` | Also adds `docs/plans/` + `docs/tasks/` skeletons (project tracking)      |
| **Update**        | `install.sh --update [/path]`        | Sync latest template into a project (preserves CLAUDE.md + settings.json) |
| **Export**        | `export.sh /path/to/project`         | Push improvements from any project back to the template                   |

The typical flow: **evolve** your harness in a real project, **export** improvements back to the template, then **update** other projects from the template.

`--full-scaffold` is the right choice when you're starting a real multi-session project and want the project-tracking convention (`PROGRESS.md` + `MANIFEST.md`) wired in from day one. For a small one-off repo where you just want hooks and agents, the default install is enough.

## What Happens When You Run install.sh

### 1. Prerequisites check

The installer verifies global files exist. If any are missing, it warns and asks whether to continue.

### 2. Mode detection

- **New project** (no `.claude/`): copies everything, creates CLAUDE.md and settings.json
- **Existing project** (has `.claude/`): adds only missing files, never overwrites yours
- **Update** (`--update` flag): overwrites generic files with latest from template, preserves CLAUDE.md and settings.json

### 3. Configuration questionnaire

You're asked 7 questions:

```
Project name (e.g., MyApp): Acme
One-line project description: B2B SaaS dashboard
Package manager: 1) pnpm  2) npm  3) yarn  4) bun
Preflight/CI command name [preflight]: ci
Test runner command [npx vitest]: npx jest
Typecheck command [npx tsc --noEmit]: npx tsc --noEmit
Protected paths: prisma/ terraform/
```

Defaults are shown in brackets — press Enter to accept them.

Your answers are saved to `.claude/.harness-config` so that `--update` can skip the questionnaire on future runs.

### 4. File installation

Files are copied with `{{PLACEHOLDERS}}` replaced by your answers:

```
Hooks:
  add  pre-commit-branch.sh
  add  pre-commit-secrets.sh
  ...
Agents:
  add  planner.md
  add  implementer.md
Settings:
  add  settings.json
CLAUDE.md:
  add  CLAUDE.md
docs/WORKFLOW.md:
  add  docs/WORKFLOW.md (points at universal workflow at ~/Developer/claude-meta/docs/WORKFLOW.md)
```

If you passed `--full-scaffold`, an extra section appears:

```
Project tracking scaffold (--full-scaffold):
  add    docs/plans/README.md
  add    docs/plans/_template/PLAN.md
  add    docs/plans/_template/PROGRESS.md
  add    docs/plans/_template/DECISIONS.md
  add    docs/plans/_template/ISSUES.md
  add    docs/plans/_template/VERIFICATION.md
  add    docs/tasks/README.md
  add    docs/tasks/_template/MANIFEST.md
```

### 5. Global layer status

The installer reports which global files are present:

```
Global layer (from ~/.claude/):
  ✓ rules/agent-directives.md
  ✓ evals/runner.sh
  ✓ evals/assertions.sh
  ✓ evals/autoresearch.sh
  ✓ commands/autoresearch.md
```

### 6. Shadow scan

After installing, the installer scans the project's `.claude/{skills,commands,rules}/` against `~/.claude/` and warns about any name collisions. Each shadow is a fork that won't see global updates — the install doesn't fail, but you should know.

```
Shadow scan:
  ✓ no shadows (project files don't silently override global)
```

If shadows exist, you'll see one yellow warning per file. See [Precedence: project-local wins, silently](#precedence-project-local-wins-silently).

## What's Installed

After running the installer, your project has this structure:

```
your-project/
├── CLAUDE.md                              # Project instructions for Claude
├── docs/
│   ├── WORKFLOW.md                        # Project-specific workflow extensions
│   │                                      #   (points at universal workflow at
│   │                                      #    ~/Developer/claude-meta/docs/WORKFLOW.md)
│   ├── plans/                             # ── --full-scaffold only ──
│   │   ├── README.md                      #   When + how to scaffold a plan
│   │   └── _template/                     #   Drop-in skeletons (PLAN, PROGRESS,
│   │       ├── PLAN.md                    #     DECISIONS, ISSUES, VERIFICATION)
│   │       ├── PROGRESS.md                #   PROGRESS.md ships with YAML status
│   │       ├── DECISIONS.md               #     block + Dead Ends section
│   │       ├── ISSUES.md
│   │       └── VERIFICATION.md
│   └── tasks/                             # ── --full-scaffold only ──
│       ├── README.md                      #   Wave naming + manifest convention
│       └── _template/
│           └── MANIFEST.md                #   Wave manifest skeleton
└── .claude/
    ├── settings.json                      # Permissions + hook wiring
    ├── .harness-config                    # Saved answers (used by --update)
    ├── hooks/
    │   ├── pre-commit-branch.sh           # Blocks commits to main/master
    │   ├── pre-commit-secrets.sh          # Scans staged diff for leaked credentials
    │   ├── pre-commit-typecheck.sh        # Runs typecheck before every commit
    │   ├── pre-commit-lint.sh             # Runs lint before every commit
    │   ├── format-on-edit.sh              # Runs prettier after every Edit/Write
    │   ├── protect-paths.sh               # Blocks edits to sensitive paths
    │   ├── keep-going.sh                  # Nudges Claude when stopping with uncommitted work
    │   └── update-plans-reminder.sh       # Reminds to update PROGRESS.md after commits
    ├── agents/
    │   ├── planner.md                     # Opus model, read-only, architecture planning
    │   └── implementer.md                 # Sonnet model, write access, follows plans
    ├── rules/                             # Empty — add project-specific rules here
    ├── commands/                           # Empty — add project-specific commands here
    ├── skills/                            # Empty — add project-specific skills here
    └── evals/
        └── suites/                        # Empty — add project-specific eval suites here
```

Rules, commands, skills, and the eval infrastructure come from `~/.claude/` (global layer) and are available in every project without duplication.

## How Each Layer Works

### CLAUDE.md — Soft Guidance

The generated CLAUDE.md contains:

- **Architecture section** (blank — you fill this in with your stack and structure)
- **Hard Rules** (TypeScript strict, no hardcoded secrets)
- **Commands** (your build/test/lint/typecheck commands, already filled in)
- **Critical Agent Rules** (5 non-negotiable behaviors, referencing global agent-directives.md)
- **Git Workflow** (branch naming, PR conventions)
- **Long-Running Plans** (session protocol for multi-session work)

Claude reads this at the start of every conversation. Keep it under 150 lines — for every line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.

### Global Agent Directives — Universal Behavior

`~/.claude/rules/agent-directives.md` is loaded into every conversation in every project. It covers:

- Pre-work discipline (phased execution, plan vs build separation, delete before you build)
- Code quality (forced verification, no over-engineering, one source of truth)
- Context management (decay awareness, sub-agent swarming, file read budgets)
- Edit safety (re-read before edit, grep-based refactoring, destructive action safety)
- Self-correction (failure recovery, bug autopsy, fresh eyes pass)
- Execution style (one-word mode, autonomous bug fixing, file hygiene)

### Hooks — Hard Enforcement (100% compliance)

Hooks run deterministic scripts at specific points in Claude's workflow. Unlike CLAUDE.md instructions, hooks are enforced — Claude cannot skip them.

| Hook                       | When                  | What it does                                                  |
| -------------------------- | --------------------- | ------------------------------------------------------------- |
| `pre-commit-branch.sh`     | Before `git commit`   | Blocks commits to main/master (exit 2)                        |
| `pre-commit-secrets.sh`    | Before `git commit`   | Scans staged diff for API keys, passwords, connection strings |
| `pre-commit-typecheck.sh`  | Before `git commit`   | Runs your typecheck command, blocks commit on failure         |
| `pre-commit-lint.sh`       | Before `git commit`   | Runs your lint command, blocks commit on failure              |
| `protect-paths.sh`         | Before `Edit`/`Write` | Blocks edits to protected paths (migrations, .env, CI config) |
| `format-on-edit.sh`        | After `Edit`/`Write`  | Runs prettier on the edited file (non-blocking)               |
| `keep-going.sh`            | When Claude stops     | Nudges to continue if uncommitted changes exist               |
| `update-plans-reminder.sh` | After `git commit`    | Reminds to update PROGRESS.md if active plans exist           |

**How hooks are wired:** The `settings.json` maps each hook to a trigger event (`PreToolUse`, `PostToolUse`, `Stop`) with a matcher pattern (e.g., `Bash` for git commands, `Edit|Write` for file edits).

**Adding your own hooks:** Create a `.sh` file in `.claude/hooks/`, then add an entry to the `hooks` section of `settings.json`. Exit 0 to allow, exit 2 to block.

### Global Skills and Commands

These are available in every project via `~/.claude/`:

| Skill/Command         | What it does                                                         |
| --------------------- | -------------------------------------------------------------------- |
| `/verify`             | Build + typecheck + lint + tests, reports pass/fail per stage        |
| `/commit-push-pr`     | Commits, pushes, creates PR, provides squash-merge comment           |
| `/debug`              | Reproduce, isolate, hypothesize, verify, explain                     |
| `/review`             | Reviews changes for type safety, security, code quality, conventions |
| `/freeze`             | Declares paths as read-only for the session                          |
| `/plan-exit-review`   | Challenges scope, reviews architecture/quality/tests/performance     |
| `/checkpoint`         | Creates a git safety snapshot before autonomous work                 |
| `/save-memory`        | Saves facts/preferences/lessons to persistent memory files           |
| `/memory-maintenance` | Deduplicates, prunes, and promotes memory entries                    |
| `/health-check`       | Runs full CI suite and reports results                               |
| `/prompt-audit`       | Measures context budget usage and recommends optimizations           |
| `/autoresearch`       | Karpathy-style prompt improvement loop against eval suites           |

### Project-Specific Eval Suites

The eval infrastructure (runner, assertions, autoresearch) lives globally. Projects add their own test suites in `.claude/evals/suites/`:

```bash
#!/bin/bash
# .claude/evals/suites/my-check.sh

assert "TypeScript compiles" assert_typecheck_passes
assert "Lint is clean" assert_lint_passes
assert "Not on main branch" assert_branch_not_main

report
```

Run with: `~/.claude/evals/runner.sh my-check` (the runner checks project-local suites first).

### Agents — Team Definitions

For Claude Code's agent teams feature. Two agents are defined:

- **Planner** (Opus) — read-only tools (Read, Grep, Glob). Plans architecture, designs APIs, outputs specs. Never writes code.
- **Implementer** (Sonnet) — write tools (Edit, Write, test runner). Follows plans, writes code, runs tests.

## Existing Project: Manual Steps

When installing into a project that already has `.claude/settings.json`, the hooks need manual wiring. Open your `settings.json` and add the hooks block from the template:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/protect-paths.sh" }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/pre-commit-branch.sh" }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-commit-typecheck.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/pre-commit-lint.sh" }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-commit-secrets.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/format-on-edit.sh" }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/update-plans-reminder.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/keep-going.sh" }
        ]
      }
    ]
  }
}
```

Also review your CLAUDE.md and consider adding:

- A **Critical Agent Rules** section referencing agent-directives.md (loaded globally)
- Your build/test/lint commands so Claude knows how to verify its work

## Updating Projects from the Template

When the template improves, push those changes to projects that use it:

```bash
bash ~/Developer/claude-harness-template/install.sh --update ~/Developer/my-project
```

This overwrites generic files (hooks, agents) with the latest template versions, applying your project's saved configuration (from `.claude/.harness-config`).

**Always preserved (never overwritten):**

- `CLAUDE.md` — your project instructions
- `settings.json` — your permissions and hook wiring
- `docs/WORKFLOW.md` — your project-specific workflow extensions
- `docs/plans/README.md` and `docs/plans/_template/*.md` — preserved if you've customized them
- `docs/tasks/README.md` and `docs/tasks/_template/*.md` — preserved if you've customized them
- Anything inside `docs/plans/<your-plan-name>/` — your actual plan dirs are never touched

**After updating:**

1. Review changes: `cd ~/Developer/my-project && git diff .claude/`
2. If the template added new hooks, wire them into your `settings.json` manually
3. Commit: `git add .claude/ && git commit -m 'chore: update Claude Code harness'`

## Exporting Improvements Back to the Template

As you evolve your harness in a real project, export the generic parts back to the template so other projects benefit.

### Step 1: Add a manifest to your project

Create `.claude/harness-export.json` in your project:

```json
{
  "description": "Declares which .claude/ files are generic vs project-specific.",

  "hooks": {
    "generic": [
      "pre-commit-branch.sh",
      "pre-commit-secrets.sh",
      "pre-commit-typecheck.sh",
      "pre-commit-lint.sh",
      "format-on-edit.sh",
      "keep-going.sh",
      "update-plans-reminder.sh",
      "protect-paths.sh"
    ],
    "project_specific": []
  },

  "agents": {
    "generic": ["planner.md", "implementer.md"]
  },

  "substitutions": {
    "pnpm preflight": "{{PKG_MANAGER}} {{PREFLIGHT_CMD}}",
    "pnpm typecheck": "{{PKG_MANAGER}} typecheck",
    "pnpm lint": "{{PKG_MANAGER}} lint",
    "pnpm build": "{{PKG_MANAGER}} build",
    "pnpm test": "{{PKG_MANAGER}} test",
    "npx vitest": "{{TEST_RUNNER}}",
    "npx tsc --noEmit": "{{TYPECHECK_CMD}}",
    "MyApp": "{{PROJECT_NAME}}"
  }
}
```

The `substitutions` map reverses your project-specific strings back into `{{PLACEHOLDERS}}` so the exported files are generic again.

### Step 2: Run the export

```bash
bash ~/Developer/claude-harness-template/export.sh ~/Developer/my-project
```

### Step 3: Review and commit

```bash
cd ~/Developer/claude-harness-template
git diff                                    # review changes
git add -A && git commit -m 'chore: sync harness from MyProject'
```

### The full cycle

```
┌─────────────┐    export.sh     ┌──────────┐    install.sh --update    ┌─────────────┐
│  Project A   │ ──────────────> │ Template  │ ───────────────────────> │  Project B   │
│  (evolving)  │                 │   repo    │                          │  (updated)   │
└─────────────┘                  └──────────┘                           └─────────────┘
```

## Customizing After Install

### Add a project-specific rule

Create `.claude/rules/data-model.md`:

```markdown
# Data Model Rules

## Entity Types

- User: email (unique), role (admin|member), orgId (FK)
- Project: name, ownerId (FK), status (active|archived)

## Conventions

- All IDs are UUIDs
- Timestamps use ISO 8601
- Soft delete via deletedAt column
```

Rules are auto-loaded every conversation — keep them focused.

### Add a project-specific hook

Create `.claude/hooks/pre-commit-imports.sh`:

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ ! "$COMMAND" =~ ^git\ commit ]] && exit 0

# Check for direct lodash imports (should use project utils)
STAGED=$(git diff --cached --name-only -- 'src/' 2>/dev/null)
for file in $STAGED; do
  if grep -q "from 'lodash'" "$file" 2>/dev/null; then
    echo "Blocked: direct lodash import in $file. Use src/utils/ instead." >&2
    exit 2
  fi
done
exit 0
```

Then wire it in `settings.json` under `PreToolUse` with `"matcher": "Bash"`.

### Add a project-specific eval suite

Create `.claude/evals/suites/deploy-check.sh`:

```bash
#!/bin/bash
# Assertions are auto-sourced by the global runner

assert "Build succeeds" assert_build_passes
assert "No .env files staged" assert_no_env_staged
assert "On a feature branch" assert_branch_not_main

report
```

Run with: `~/.claude/evals/runner.sh deploy-check`

### Add a project-specific skill

Create `.claude/skills/deploy/SKILL.md`:

```markdown
---
name: deploy
description: "Deploy to staging or production."
user-invocable: true
---

# Deploy

## Usage

- `/deploy staging` — deploy to staging
- `/deploy production` — deploy to production (requires confirmation)

## Steps

1. Run /verify to ensure CI passes
2. ...your deployment steps...
```

### Modify protected paths

Edit `.claude/hooks/protect-paths.sh` and update the `PROTECTED_PATTERNS` array:

```bash
PROTECTED_PATTERNS=(
  "migrations/"
  ".env"
  ".github/workflows/"
  "docker-compose.yml"
  "prisma/schema.prisma"   # add your own
  "terraform/"              # add your own
)
```

## Placeholders Reference

These placeholders appear in template files and are replaced during install:

| Placeholder               | Example value      | Used in              |
| ------------------------- | ------------------ | -------------------- |
| `{{PROJECT_NAME}}`        | Acme               | CLAUDE.md, agents    |
| `{{PROJECT_DESCRIPTION}}` | B2B SaaS dashboard | CLAUDE.md            |
| `{{PKG_MANAGER}}`         | pnpm               | Hooks, settings.json |
| `{{PREFLIGHT_CMD}}`       | preflight          | CLAUDE.md            |
| `{{TEST_RUNNER}}`         | npx vitest         | Agents               |
| `{{TYPECHECK_CMD}}`       | npx tsc --noEmit   | Hooks, agents        |
| `{{UI_PACKAGE}}`          | MyApp/ui           | Agents               |

## Requirements

- macOS or Linux (uses `sed -i ''` on macOS — Linux users may need to adjust)
- `jq` (used by hooks to parse Claude's tool input)
- `prettier` (used by format-on-edit hook — fails silently if not installed)
- `perl` (used by export.sh for placeholder substitution — pre-installed on macOS/Linux)
- Git (hooks reference `git` commands)
- Global `~/.claude/` layer installed (agent directives, evals, shared skills/commands)
