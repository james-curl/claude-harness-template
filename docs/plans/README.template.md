# Plans

This directory tracks **multi-session efforts** at the strategic level. Each plan is a directory with its own status, decisions log, and session log.

> Universal convention reference: `~/Developer/claude-meta/docs/plans-and-tasks.md`

## When to scaffold a plan

| Work size                                     | Use                                  |
| --------------------------------------------- | ------------------------------------ |
| Single-session task, <2 hours, <=3 files      | TodoWrite (in-conversation only)     |
| Multi-session feature, 3+ phases or 10+ files | Plan directory here                  |
| Many tasks inside a phase                     | Wave manifest (`docs/tasks/<wave>/`) |

If you're not sure, start with TodoWrite. Promote to a plan directory when you realize you'll need to come back tomorrow.

## Layout

```
docs/plans/<plan-name>/
+-- PLAN.md          The what and how (the spec)
+-- PROGRESS.md      Phase-by-phase checklist + session log (ground truth for status)
+-- DECISIONS.md     Decision log with rationale (prevents re-debating)
+-- ISSUES.md        Problems found and resolutions
+-- VERIFICATION.md  Evidence trail (test output, screenshots, grep results)
```

Not every plan needs all five. Start with `PLAN.md` + `PROGRESS.md` and add the others as needed.

## Scaffolding a new plan

Copy the template:

```bash
mkdir -p docs/plans/my-new-plan
cp docs/plans/_template/*.md docs/plans/my-new-plan/
```

Then edit the YAML frontmatter at the top of `PROGRESS.md` to set the plan's name, phase, and `next_action`.

## Session protocol

**Start of session:**

1. Read `PROGRESS.md` (frontmatter + most recent session log)
2. Read the tail of `ISSUES.md` (recent problems)
3. Read the tail of `DECISIONS.md` (recent trade-offs)

**During the session:**

- Update `PROGRESS.md` after each commit or logical milestone
- Append to `ISSUES.md` if you hit a problem
- Append to `DECISIONS.md` if you make a non-trivial trade-off

**End of session:**

- Update `PROGRESS.md` session log with what happened
- Update `next_action` in the frontmatter so resuming is one-line clear
- Commit support files alongside the code changes

## Why bother

Six months from now you'll come back to a half-done plan and the only context you'll have is whatever's in these files. Write for that future-you.
