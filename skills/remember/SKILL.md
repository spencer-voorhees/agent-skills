---
name: remember
description: Persist session decisions as Architectural Decision Records (ADRs in docs/adr/), record operational gotchas in docs/learnings.md, and output clean session handoffs / PR descriptions so future sessions resume seamlessly without merge conflicts. Use at the end of any working session, when the user says "wrap up", "save context", "remember this", "checkpoint", after major architectural decisions, or before opening a PR.
---

# Remember (ADR Recording & Session Memory)

## Why this exists

Unrecorded decisions and hard-won insights vanish when an agent session ends.
Future sessions then repeat the same mistakes: re-litigating settled architecture,
re-discovering subtle framework bugs, or starting from scratch.

This skill provides the durable write-back mechanism, capturing:
1. **Architectural Decisions**: As immutable, git-safe ADR files in `docs/adr/`.
2. **Operational Gotchas**: As a curated runbook in `docs/learnings.md`.
3. **Session Handoff & PR Draft**: Clear next steps for the next session or PR reviewer.

---

## What to Capture

Review the session and sort what happened into three distinct buckets:

### 1. Architectural Decisions &rarr; `docs/adr/` (File-per-Decision)

When a non-trivial choice was made, an alternative was rejected, or an architectural
pattern was established, generate a new ADR file in `docs/adr/`:

`docs/adr/YYYY-MM-DD-<short-slug>.md` (or numbered `docs/adr/000X-<short-slug>.md`):

```markdown
# ADR: [Decision Title]

* **Status**: Accepted
* **Date**: [YYYY-MM-DD]
* **Deciders**: [Dev / Agent]
* **Related Spec**: [docs/specs/<feature>.md]

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

*Why file-per-decision?* Creating discrete markdown files ensures that multiple
developers or autonomous agents can merge branches into `main` simultaneously with
**zero git merge conflicts**.

---

### 2. Operational Learnings &rarr; `docs/learnings.md` (Curated)

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

### 3. Session Handoff & PR Description &rarr; `docs/handoff.md`

Generate a structured session handoff. This describes the *immediate present* and
can be used directly as a PR description:

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

*Multi-Developer Git Tip*: For team repositories with concurrent branches, add
`docs/handoff.md` to `.gitignore` or use branch-named handoffs
(`docs/handoffs/${GIT_BRANCH}.md`) so active local handoffs do not conflict on `main`.

---

## Mid-Session Usage

If a major architectural decision is reached or an expensive gotcha is solved mid-session,
record it immediately rather than waiting for the final prompt. Capturing context in
real time prevents lost insights if a context window resets.
