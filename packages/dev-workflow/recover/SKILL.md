---
name: recover
description: Break out of a stuck loop by halting the current approach, auditing assumptions against direct runtime evidence, and re-grounding in project specs and architecture before choosing a minimal discriminating step. Use when repeated attempts at the same problem keep failing, the same error keeps recurring, progress has stalled, or the user says "you're stuck", "you're going in circles", "stop and think", "take a step back", "debug this systematically", or when debugging persistent errors.
---

# Recover (Scientific Debugging & Loop Breaker)

## Why this exists

A stuck agent's failure mode is rarely lack of effort—it is repeating one approach
with superficial variations while a flawed underlying assumption steers every attempt
into the same obstacle. Repeated edits on top of failed attempts pollute the codebase
and obscure the root cause.

The path out is to **halt generation, clear workspace debris, and audit beliefs against evidence**.

---

## When to Invoke This Skill

Do not wait for the user to intervene. Trigger this skill automatically whenever:
- The same error has survived **3 consecutive fix attempts**.
- You find yourself oscillating edits in the same file between previously failed states.
- You cannot explain concretely why your *next* attempt will succeed when prior attempts failed.

---

## The Recovery Protocol

### 1. Halt & Clear the Workspace

Stop attempting new fixes immediately.
1. Run `git status` and `git diff` to inspect accumulated changes.
2. If speculative, unverified edits have cluttered the working tree, **revert to the last known-clean state**. Debugging on top of broken debris creates phantom bugs.

### 2. Formulate the Stuck Report

In a temporary scratchpad, explicitly write out:

```markdown
## Goal
[What observable outcome defines success? Re-derive this from docs/specs/, not from a sub-task that might be a wrong turn.]

## Failed Attempts
1. [What was tried] → [Exact error message or observed outcome]
2. [What was tried] → [Exact error message or observed outcome]

## Underlying Assumptions
- [Assumption 1: e.g., "The auth header is present in the request"]
- [Assumption 2: e.g., "The database migration ran successfully"]
- [Assumption 3: e.g., "Library X supports option Y in v2.0"]
```

*Writing this down exposes the loop:* most stuck cycles dissolve once you notice that 5 failed attempts were actually one assumption dressed in five different syntax costumes.

### 3. Audit Assumptions Against Direct Evidence

For every assumption, ask: **What empirical evidence proves this is true?**
"It should work this way" is not evidence. Verify load-bearing beliefs firsthand:
- Print the actual runtime value or inspected object.
- Inspect the actual file or environment variable on disk.
- Read the official library documentation or source code.
- Run the failing sub-command in complete isolation.

### 4. Re-Ground in Project Context

Re-read the project's durable documentation:
- **`docs/specs/`**: Is the sub-task you are struggling with even required for acceptance criteria?
- **`docs/architecture/system-overview.md`**: Does the approach violate an architectural constraint or module boundary?
- **`docs/adr/`**: Was a similar approach already evaluated and rejected?
- **`docs/learnings.md`**: Is this exact gotcha already documented with a known workaround?

### 5. Choose the Smallest Discriminating Step

Formulate the next action to **produce information rather than guessing a fix**:
- Create a 5-line isolated reproduction script.
- Execute a single unit test with verbose logging.
- Add an assertion to check a boundary condition.

*A step whose failure teaches you nothing is simply another lap around the stuck loop.*

### 6. Constructive Escalation

If two evidence-driven attempts fail after the audit, or if the blocker requires external user input (credentials, access, or product trade-offs):
- Stop and present the **Stuck Report** to the user: Goal, tested hypotheses, verified facts, and recommended next choices.
- Turning "I'm stuck" into a structured diagnostic report allows the user to unblock you in a single response.

---

## Post-Recovery Wrap-up

Once the issue is resolved:
1. Record the gotcha in `docs/learnings.md` (Symptom $\rightarrow$ Root Cause $\rightarrow$ Fix) so no future session wastes time on it.
2. If resolving the blocker required changing an architectural pattern, invoke **remember** to document the decision in `docs/adr/`.
