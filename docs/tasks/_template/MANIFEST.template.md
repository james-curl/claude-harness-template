---
status: ready # ready | in-progress | done | blocked
wave: wave-NN-{{name}}
plan: { { plan-name } }
total_tasks: 0
last_updated: YYYY-MM-DD
---

# Wave {{NN}} — {{Wave Name}}

> One-line statement of what this wave delivers. Links to the parent plan.

**Parent plan:** [`docs/plans/{{plan-name}}/PLAN.md`](../../plans/{{plan-name}}/PLAN.md)

## Progress

| Task         | Status | Depends on | Commit | Notes |
| ------------ | ------ | ---------- | ------ | ----- |
| T1-types     | ready  | -          | -      |       |
| C1-component | ready  | T1         | -      |       |
| F1-feature   | ready  | C1         | -      |       |
| I1-wiring    | ready  | F1         | -      |       |

Status values: `ready`, `in-progress`, `done`, `blocked`, `skipped`.

## Notes

Per-wave context that doesn't belong in individual task files. Architectural decisions specific to this wave, sequencing rationale, gotchas discovered during execution.
