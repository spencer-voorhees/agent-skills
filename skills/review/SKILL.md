---
name: review
description: Review pending changes against the project's context package — correctness, requirement alignment, architecture drift, duplicate code, and design-system violations — producing ranked findings with file:line references. Use before any commit, PR, or merge, whenever the user says "review", "check this", "look over my changes", or after completing a milestone or significant chunk of implementation work.
---

# Review

## Why this exists

A generic code review catches bugs. This review also catches the failures
specific to agent-driven development: code that quietly duplicates a helper
written three sessions ago, endpoints that ignore the API strategy, hardcoded
hex values where tokens exist, and features that drift from what the
requirements actually say. Those checks are only possible because the context
package records what "right" looks like — so read it first.

## Scope

Default to the current pending changes: `git diff` (staged + unstaged), or
the branch's diff against the default branch if the working tree is clean.
If the user names a target (a PR, a directory, specific files), review that
instead. State the scope you settled on in the report.

## Prerequisites

Read whichever context files exist: `10-requirements.md`,
`30-architecture.md`, `40-design-system.md`, `60-learnings.md`. Missing
files just disable their check — note that in the report rather than
failing. If there's no context package at all, fall back to a correctness
review and recommend running **context-package**.

## The checks, in order

Work through these in order — correctness problems make the later checks
moot, so establish them first.

### 1. Correctness
Bugs an honest reader can demonstrate: logic errors, unhandled failure
paths, race conditions, off-by-ones, broken edge cases. For each, describe
the concrete input or state that triggers the failure — a finding without a
failure scenario is a style opinion.

### 2. Requirement alignment
Map the change to the requirement(s) it serves (R1, R2, …). Flag behavior
that contradicts an acceptance criterion, silently narrows one, or
implements something no requirement asked for. Unrequested scope is a
finding, not a bonus.

### 3. Architecture drift
Check the change against `30-architecture.md`: module boundaries respected?
New endpoints following the API strategy (URL patterns, error shape, auth)?
Errors and logging handled per the cross-cutting rules? A justified
deviation isn't a defect — but it must be flagged so the doc or the code
gets fixed; a silent divergence poisons every future session that trusts
the doc.

### 4. Duplication
For each new function, helper, or component, search the codebase for an
existing equivalent before accepting it as new (grep for likely names and
distinctive strings — different sessions name the same idea differently, so
search by concept, not just literal name). Duplicates are the signature
failure of session-based work; nobody remembers writing the first copy.

### 5. Design-system violations
If `40-design-system.md` exists and the change touches UI: raw color/spacing
values where tokens exist, new one-off components duplicating inventory
entries, missing states (hover/disabled/loading) the inventory requires,
inventory not updated for genuinely new components.

### 6. Tests
Does the change carry the tests the architecture's testing section promises?
Do existing tests still pass? Run them if a test command is defined —
"looks right" is not evidence.

## Report format

```markdown
## Review: [scope]

**Verdict**: [ship it / fix blockers first / needs discussion]

### Blockers
1. `path/file.ts:42` — [what's wrong]. [Why it matters / failure scenario.]
   Fix: [concrete suggestion]

### Should fix
...

### Consider
...

### Checked and clean
[One line per check that passed, e.g. "No duplication found for the three
new helpers." — so silence is distinguishable from "didn't look".]
```

Rank findings by severity, not by file order. Every finding needs a
file:line, a why, and a suggested fix. A finding you can't tie to a
requirement, a doc, or a failure scenario is taste — leave it out or put it
under Consider, clearly framed as optional.

## Boundaries

Report findings; don't fix them unless the user asks. If a finding reveals
the *docs* are wrong rather than the code (an outdated requirement, a stale
architecture section), say so explicitly — updating the context package is
the fix, and the **remember** skill is the tool.
