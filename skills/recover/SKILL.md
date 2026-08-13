---
name: recover
description: Break out of a stuck loop by halting the current approach, auditing assumptions against direct evidence, and re-grounding in the context package before choosing a new smallest testable step. Use when repeated attempts at the same problem keep failing, the same error keeps coming back, progress has stalled, or the user says "you're stuck", "you're going in circles", "stop and think", or "take a step back".
---

# Recover

## Why this exists

A stuck agent's failure mode is rarely lack of effort — it's repeating one
approach with cosmetic variations while an early wrong assumption steers
every attempt into the same wall. More tries make it worse: each failed edit
mutates state and buries the original problem. The way out is to stop
generating attempts and start auditing beliefs.

## When to invoke this on yourself

Don't wait for the user to say "you're stuck". Trigger it yourself when any
of these are true:

- The same error has survived **3 attempts** to fix it.
- You're editing the same file back and forth between states you've
  already tried.
- You can't say concretely why the *next* attempt will succeed where the
  last one failed.

## The procedure

### 1. Stop. Assess the wreckage.

No more fix attempts. First, check what state the attempts have left behind:
run `git status` / `git diff` and look at what's been mutated. If the
working tree has accumulated speculative edits from failed attempts,
seriously consider reverting to the last known-good state — debugging on
top of debris means chasing problems you created while stuck. Note anything
worth keeping before you revert it.

### 2. Write the stuck report

In a scratch file (not the repo), write down:

```markdown
## Goal
[What success actually looks like — re-derive it from the original request,
not from your current sub-task, which may itself be a wrong turn.]

## Attempts
1. [what was tried] → [exact observed result — real error text, not memory]
2. ...

## Assumptions
- [every belief the attempts relied on: "the config is being loaded",
  "the error comes from X", "this API works like Y"]
```

Writing it out isn't ceremony — the loop lives in vague memory of what was
tried, and it usually dissolves under the act of listing the attempts and
noticing they were one idea in five costumes.

### 3. Audit the assumptions

For each assumption, ask: **what direct evidence do I have?** "It should
work that way" is not evidence. Verify the load-bearing ones firsthand:
read the actual file on disk, print the actual runtime value, read the
actual library source or docs, run the failing command in isolation. In a
genuine stuck loop, one of these beliefs is almost always false — the goal
of this step is to find which one.

### 4. Re-ground in the context package

Re-read the relevant parts of `docs/context/` — especially `20-constraints.md`,
`30-architecture.md`, and `60-learnings.md`. Check whether this exact gotcha
is already recorded, whether the approach fights a documented constraint,
and whether the sub-goal you've been grinding on even serves a requirement.
Sometimes the recovery is realizing the whole sub-task is optional.

### 5. Choose the smallest discriminating step

Pick the next action to **produce information, not to be the fix**: the
smallest test that proves which surviving hypothesis is true — a five-line
reproduction, one isolated command, one printed value. A step whose failure
teaches nothing is another lap of the loop.

### 6. Know when to escalate

After the audit, if two more evidence-driven attempts fail, or the blocker
needs something only the user has (credentials, intent, a judgment call, a
paid service) — stop and ask. Bring the stuck report: goal, attempts with
results, assumptions with verdicts, and your best-guess diagnosis. That
turns "I'm stuck" into a question the user can actually answer in one reply.
Asking with evidence after a real audit isn't failure; burning an hour
looping is.

## Afterward

Once unstuck, append the gotcha to `docs/context/60-learnings.md` (one dated
line: symptom → real cause → fix) so no future session pays for this again.
If the recovery reversed a documented decision or revealed a stale
architecture section, update the package per the **remember** skill.
