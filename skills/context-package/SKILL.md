---
name: context-package
description: Build or update the project's context package — the docs/context/ markdown files that act as the durable source of truth for what is being built, for whom, and under what constraints. Every other workflow skill (architect, design-system, review, remember) reads from this package. Use this at the start of any new project or feature, whenever the user wants to "spec out", "scope", "write a brief", "write a PRD", "capture requirements", or "set up context" — and whenever another workflow skill finds no docs/context/ directory.
---

# Context Package

## Why this exists

Agent sessions are ephemeral; the context package is not. It is a small set of
markdown files in `docs/context/` that captures what the project is, what it
must do, and what it must not do. Downstream skills depend on it: `architect`
designs from it, `design-system` styles from it, `review` judges diffs against
it, and `remember` appends to it. A vague or missing context package makes
every one of those steps worse, so invest the effort here first.

## The package layout

```
docs/context/
├── 00-brief.md          # what, who, why, success criteria
├── 10-requirements.md   # features, user stories, acceptance criteria
├── 20-constraints.md    # stack constraints, non-goals, budgets
├── 30-architecture.md   # owned by the architect skill
├── 40-design-system.md  # owned by the design-system skill
├── 50-decisions.md      # append-only decision log (fed by remember)
├── 60-learnings.md      # conventions and gotchas (fed by remember)
└── 90-handoff.md        # session handoff state (fed by remember)
```

This skill owns files 00, 10, and 20. Never overwrite 30–90 — other skills
own those. Create `50-decisions.md`, `60-learnings.md`, and `90-handoff.md`
as empty stubs (a title line and a sentence describing their purpose) so the
package is complete from day one.

## Process

### 1. Inventory what already exists

Before asking the user anything, gather what the repo already knows:

- Read `README.md`, any existing docs, `package.json`/`pyproject.toml`/etc.
- If `docs/context/` already exists, read all of it — you are updating, not
  starting over.
- Skim the code structure if there is code: the directory layout and
  dependencies often answer constraint questions.

### 2. Interview for the gaps

Ask the user only what you genuinely cannot infer, and keep it to the few
highest-leverage questions. Good questions target:

- Who uses this and what problem it solves for them (drives the brief)
- The 3–5 things it must do in v1 (drives requirements)
- Hard constraints: required stack, platforms, integrations, deadlines,
  things explicitly out of scope (drives constraints)

If you are running autonomously and cannot ask, infer conservatively from the
repo and the request, and mark every guess as an open question rather than
presenting it as fact.

### 3. Write the files

Keep each file short, factual, and skimmable. Every statement should be
something a future agent can act on. No filler prose, no marketing language.
State each fact in exactly one place — if requirements repeat the brief,
future edits will let them drift apart.

Mark anything unresolved as `OPEN QUESTION:` on its own line. An honest open
question is far more useful than an invented requirement, because downstream
skills treat these files as ground truth.

#### 00-brief.md template

```markdown
# Brief: [Project name]

**What**: one paragraph — what this is.
**Who**: the user(s) and the problem being solved for them.
**Why now**: the motivation or trigger for building it.

## Success criteria
- [observable outcome that means this worked]

## Out of scope (v1)
- [things deliberately not being built]
```

#### 10-requirements.md template

```markdown
# Requirements

## R1: [Feature name]
[User story or one-sentence description.]
**Acceptance**: [how we know it's done — concrete, checkable]

## R2: ...
```

Number requirements (R1, R2, …) so other skills and commit messages can
reference them precisely.

#### 20-constraints.md template

```markdown
# Constraints

## Stack
- [required/forbidden technologies, and why if known]

## Non-goals
- [things this project should never grow into]

## Budgets & limits
- [performance, cost, timeline, hosting limits — only if real]
```

### 4. Confirm and close

Summarize the package back to the user in a few sentences, listing the open
questions explicitly. If a downstream step is the obvious next move (usually
`architect`), say so.

## Updating an existing package

When requirements change mid-project, edit the package rather than letting
the conversation be the only record. Update the affected statements in place,
and note the change with a dated line in `50-decisions.md` (e.g.
"2026-08-13: Dropped R4 offline mode — descoped for v1"). The package should
always read as *currently true*, while the decision log preserves history.
