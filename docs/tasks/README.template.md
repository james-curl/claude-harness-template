# Tasks

This directory tracks **wave-style execution** — many discrete tasks inside a single phase, processed by `/execute-wave`.

> Universal convention reference: `~/Developer/claude-meta/docs/plans-and-tasks.md`

## When to use a wave

Use a wave when you have a phase of work that breaks down into 5+ independent tasks with clear dependencies. The wave's `MANIFEST.md` is the contract between you and `/execute-wave`: it picks the next ready task, implements + verifies + commits, and updates the manifest in place.

If you only have a handful of tasks, a section in `PROGRESS.md` is enough.

## Layout

```
docs/tasks/<wave-name>/
+-- MANIFEST.md          Per-task status table (the contract)
+-- PRD-feature.md       Optional product spec for the wave
+-- T1-types.md          Individual task files
+-- C1-component.md
+-- F1-feature.md
+-- ...
```

## Scaffolding a new wave

```bash
mkdir -p docs/tasks/wave-01-my-feature
cp docs/tasks/_template/MANIFEST.md docs/tasks/wave-01-my-feature/
```

Then write task files (`T1-*.md`, `C1-*.md`, `F1-*.md`) with file paths, acceptance criteria, and dependencies.

## Wave naming convention

`wave-NN-<plan>-<slug>` — sortable, greppable. Example: `wave-01-trade-compliance-stubs`, `wave-02-trade-compliance-data-layer`.

## Status values

- `ready` — dependencies met, no one working on it
- `in-progress` — currently being executed
- `done` — completed and committed
- `blocked` — dependency not met or external blocker
- `skipped` — explicitly out of scope

## How `/execute-wave` reads it

1. Loads `MANIFEST.md`
2. Picks the lowest-ID task with status `ready` and all dependencies in `done`
3. Reads the task file, implements, runs verification, commits
4. Updates the row: status -> `done`, fills in commit hash
5. Loops until no ready tasks remain

The manifest is the contract. Don't let the code drift from what the manifest says is done.
