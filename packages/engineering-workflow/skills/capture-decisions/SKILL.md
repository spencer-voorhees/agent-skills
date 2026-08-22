---
name: capture-decisions
description: Record durable engineering decisions, costly operational learnings, or concise handoff context in the repository's established documentation system. Use when the user asks to document a decision, create an ADR, preserve an important learning, checkpoint unfinished work, or prepare a handoff. Do not write session artifacts automatically at the end of ordinary tasks.
---

# Capture Decisions

## Why this exists

Unrecorded decisions and hard-won insights vanish when an agent session ends.
Future sessions then repeat the same mistakes: re-litigating settled architecture,
re-discovering subtle framework bugs, or starting from scratch.

This skill provides a selective durable write-back mechanism. Capture only the artifact
the user requested or the task clearly requires: architectural decisions, costly
operational learnings, or concise handoff context.

## Choose the destination

Resolve each requested artifact destination in this order:

1. Use a path or external system explicitly requested by the user.
2. Follow repository instructions such as `AGENTS.md`.
3. Follow an existing, unambiguous convention for that artifact type.
4. If none exists, ask where to save it. In a non-interactive run, return the artifact
   in the task output and state that it was not persisted.

Do not create an ADR directory, learnings file, handoff file, ignore rule, or other
documentation policy merely because this skill ran.

---

## What to Capture

Review the relevant work and select the applicable bucket; do not generate all three by
default:

### 1. Architectural decisions

When a non-trivial choice was made, an alternative was rejected, or an architectural
pattern was established, add a record using the repository's established format and
naming scheme. File-per-decision ADRs are a good default only when the repository has
adopted that convention.

```markdown
# ADR: [Decision Title]

* **Status**: Accepted
* **Date**: [YYYY-MM-DD]
* **Deciders**: [Dev / Agent]
* **Related Spec**: [path or issue reference]

## Context & Problem Statement
[What problem needed solving? What constraints applied?]

## Considered Options
1. **[Chosen Option]**
2. **[Alternative Option A]**
3. **[Alternative Option B]**

## Decision Outcome
Chosen option: **[Chosen Option]**, because [reason the alternative lost].

### Consequences & Trade-offs
- [Positive outcome or capability gained]
- [Accepted cost or limitation]
```

File-per-decision records reduce merge contention and keep each decision independently
reviewable; they do not guarantee conflict-free merges.

---

### 2. Operational learnings

Record stack quirks, tooling gotchas, test workarounds, or non-obvious conventions
discovered during the session:

```markdown
## Tooling & Environment
- *2026-08-14*: Next.js build failed on dynamic API routes in serverless — fixed by exporting `dynamic = 'force-dynamic'` on all webhook handlers (cost ~30m to debug).
```

*The 15-Minute Rule*: **Would a fresh engineer or agent plausibly waste $\ge 15$ minutes rediscovering this?**
If yes, record it. If not, leave it out to keep the document concise and readable.
Periodically curate this file to delete workarounds for bugs that have been fixed upstream.

---

### 3. Session handoff or PR description

When a handoff is requested or work remains intentionally unfinished, generate a
structured session handoff in the resolved destination. This describes the *immediate
present* and can also be used directly as a PR description:

```markdown
# Handoff — [YYYY-MM-DD]

## Completed This Session
- [x] Implemented R1 OAuth token exchange in `src/api/auth.ts`.
- [x] Added unit tests in `tests/unit/auth.test.ts` (passing).

## In Flight & Work in Progress
- [ ] R2 refresh token rotation: schema migration complete, but endpoint handler is half-implemented in `src/api/refresh.ts`.

## Next Immediate Steps
1. Wire `rotateToken()` in `src/api/refresh.ts` to call repository layer.
2. Add integration test for expired token scenario.

## Watch Out & Gotchas
- The dev database schema requires running `npm run db:migrate` before testing `src/api/refresh.ts`.
```

Follow the repository's handoff policy. If it uses a local ignored handoff, verify the
ignore rule. If it intentionally versions handoffs, preserve that convention. Ask before
changing repository policy when that change is outside the requested work.

---

## Mid-Session Usage

If a major architectural decision is reached or an expensive gotcha is solved mid-session,
record it promptly only when a destination is already authorized. Otherwise preserve it
in the task output and ask before adding a new repository artifact.
