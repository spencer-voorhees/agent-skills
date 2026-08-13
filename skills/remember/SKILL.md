---
name: remember
description: Persist this session's decisions, learnings, and working state into the context package (docs/context/) so the next session starts with full context instead of amnesia. Use at the end of any working session, when the user says "wrap up", "save context", "remember this", or "checkpoint", after any significant decision or hard-won discovery mid-session, and proactively when a long session is approaching its context limit.
---

# Remember

## Why this exists

Everything not written down dies with the session: the reason a library was
rejected, the flag that fixed the flaky test, the half-finished refactor's
next step. The next session then re-decides, re-discovers, and re-breaks all
of it. This skill is the write-back step that turns session experience into
durable context — it's what makes the context package *compound* instead of
just persist.

## What to capture

Review the session and sort what happened into three buckets. If
`docs/context/` doesn't exist, create the three files below with a note to
run **context-package** properly later — capturing state still beats
losing it.

### 1. Decisions → 50-decisions.md (append-only)

Choices where a reasonable alternative lost: libraries picked or rejected,
approaches abandoned, scope cut or added, conventions established. One line
each, dated, alternative and reason included — the reason is what stops a
future session from silently reversing it:

```markdown
- 2026-08-13: Chose SQLite over Postgres — single-user app (R1), zero-ops
  constraint. Revisit only if multi-user lands in scope.
```

Never edit or delete old entries; the log is history. If a decision reverses
an earlier one, add a new entry that says so.

### 2. Learnings → 60-learnings.md (curated)

Things that cost real effort to discover and will bite again: gotchas, quirks
of the stack, commands that must run in a particular way, conventions that
exist for non-obvious reasons:

```markdown
- Tests must run with `--runInBand` — the SQLite file locks under parallel
  workers (cost ~1h to diagnose, 2026-08-13).
```

The bar: **would a fresh session plausibly lose 15+ minutes rediscovering
this?** If not, leave it out — a bloated learnings file stops being read,
and then it's all dead weight. Unlike the decision log, curate this file:
delete entries the codebase has outgrown.

### 3. Working state → 90-handoff.md (overwrite)

Rewrite this file completely each time — it describes *now*, not history:

```markdown
# Handoff — 2026-08-13

## Done this session
- [completed, verified work — with requirement IDs where relevant]

## In flight
- [started but unfinished, with exact state: what's written, what's not,
  any broken intermediate state the next session will find]

## Next steps
1. [most specific possible next action — file, function, command]

## Watch out
- [anything mid-flight that would confuse a fresh reader of the code]
```

The test: **a fresh session reading only the context package should resume
in under two minutes without asking anything.** Vague entries ("continue
auth work") fail it; specific ones ("wire `AuthGuard` into the three admin
routes in `routes/admin.ts` — pattern established in `routes/user.ts`") pass.

## Keep the package currently-true

If the session invalidated statements elsewhere in the package — a
requirement descoped, an architecture section now stale, a design token
renamed — update those files in place now and log the change as a decision.
Handing off a context package that contradicts the code is worse than
handing off nothing, because future sessions trust the package.

## Mid-session use

Big decision or expensive discovery mid-session? Write it down immediately —
a crashed session loses everything since the last write-back. Appending one
dated line takes seconds.
