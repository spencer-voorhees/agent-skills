---
name: debug-systematically
description: Diagnose a persistent or unclear failure by stopping speculative edits, inventorying evidence and failed hypotheses, verifying assumptions directly, and choosing the smallest discriminating experiment. Use when repeated fixes fail, the same error recurs, progress stalls, or the user asks for systematic debugging. Preserve all existing work and never discard changes without clear ownership and authorization.
---

# Debug Systematically

## Why this exists

A stuck agent's failure mode is rarely lack of effort—it is repeating one approach
with superficial variations while a flawed underlying assumption steers every attempt
into the same obstacle. Repeated edits on top of failed attempts pollute the codebase
and obscure the root cause.

The path out is to **halt speculative edits and audit beliefs against evidence**.

---

## When to Invoke This Skill

Do not wait for the user to intervene. Trigger this skill automatically whenever:
- The same error has survived **3 consecutive fix attempts**.
- You find yourself oscillating edits in the same file between previously failed states.
- You cannot explain concretely why your *next* attempt will succeed when prior attempts failed.

---

## The Recovery Protocol

### 1. Halt & Preserve the Workspace

Stop attempting new fixes immediately.
1. Run `git status` and `git diff` to inspect accumulated changes.
2. Preserve all existing changes. Identify edits introduced by failed attempts and
   isolate or revert only changes whose provenance is certain and whose removal is
   authorized. Otherwise show the relevant diff and ask before discarding anything.

### 2. Formulate the Stuck Report

In a temporary scratchpad, explicitly write out:

```markdown
## Goal
[What observable outcome defines success? Re-derive this from the user request and any
durable requirements, not from a sub-task that might be a wrong turn.]

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

Use repository instructions and established conventions to find relevant durable context:
- **Requirements**: Is the sub-task required by the acceptance criteria?
- **Architecture**: Does the approach violate a constraint or module boundary?
- **Decisions**: Was a similar approach already evaluated and rejected?
- **Runbooks or learnings**: Is this gotcha already documented with a workaround?

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
1. If the gotcha is costly and the repository has an authorized destination for
   learnings, record Symptom → Root Cause → Fix there. Otherwise mention it in the
   task output; do not introduce a new documentation location.
2. If resolving the blocker required a durable architectural decision, offer to use
   `capture-decisions` to record it.
