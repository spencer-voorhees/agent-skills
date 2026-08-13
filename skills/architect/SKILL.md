---
name: architect
description: Design the technical architecture for a project from its context package — stack selection, module boundaries, data model, and API strategy — written to docs/context/30-architecture.md so implementation sessions build from a plan instead of improvising. Use before starting implementation of any new app or major feature, and whenever the user says "architect", "plan the technical approach", "choose the stack", "design the API", "design the data model", or asks how the system should be structured.
---

# Architect

## Why this exists

The most expensive failures in agent-built projects are the quiet ones: an
API strategy that was never defined, so every endpoint invents its own
conventions; module boundaries that were never drawn, so everything imports
everything. This skill front-loads those decisions into one document that
every implementation session reads before writing code.

## Prerequisites

Read the entire context package first: `docs/context/00-brief.md`,
`10-requirements.md`, `20-constraints.md`, plus `50-decisions.md` and
`60-learnings.md` if they have content. The architecture must satisfy the
requirements within the constraints — if you find yourself designing
something the brief doesn't need, stop.

If `docs/context/` doesn't exist, build it first using the
**context-package** skill. Don't architect from a verbal description; the
whole point is that the plan derives from durable, agreed-upon context.

If the repo already has code, read its structure before proposing anything.
An architecture that ignores the existing codebase is a rewrite proposal, not
an architecture — and rewrites need explicit user sign-off.

## Decision principles

- **Boring technology wins.** Choose the most mainstream tool that satisfies
  the constraints. Novel tech needs a stated justification tied to a
  requirement, not taste.
- **Fewest moving parts.** Every service, queue, or database you add is
  something every future session must understand and keep running. Default
  to one process and one datastore until a requirement forces more.
- **Every choice gets a one-line why.** Future sessions (and the user) need
  to distinguish load-bearing decisions from arbitrary ones, or they'll
  re-litigate the former and treat the latter as sacred.
- **Design for the requirements you have.** Speculative flexibility
  ("we might need multi-tenancy someday") is scope creep wearing a hard hat.
  Note genuine future concerns in one line under Risks instead of designing
  for them.

## Output: 30-architecture.md

Write `docs/context/30-architecture.md` with this structure:

```markdown
# Architecture

## Stack
| Layer | Choice | Why |
|---|---|---|
| ...   | ...    | one line |

## System overview
[A short mermaid diagram of the major pieces and how they talk,
plus 2–3 sentences of prose.]

## Module map
[The directory layout you intend, with one line per module saying what it
owns and what it must not know about. This is the boundary contract that
the review skill enforces later.]

## Data model
[Entities, key fields, and relationships. Concrete enough to write the
schema from.]

## API strategy
[The conventions every endpoint/interface follows: style (REST/RPC/etc.),
URL and naming patterns, error response shape, auth mechanism, versioning
stance. This section exists so no endpoint ever invents its own rules.]

## Cross-cutting concerns
- **Errors**: [how failures propagate and get reported]
- **Logging**: [what gets logged, where]
- **Testing**: [test types used, where they live, the command to run them]
- **Config/secrets**: [how configuration is supplied]

## Build & run
[Exact commands to install, run in dev, test, and build. An agent in a
fresh session should be able to start working from these alone.]

## Milestones
1. [Smallest end-to-end slice that proves the architecture — walking skeleton]
2. [Next coherent chunk, referencing requirement IDs like R1, R2]
3. ...

## Risks & open questions
- [anything unresolved, with what would resolve it]
```

The test for "done" is: **an agent with only the context package and an empty
repo could start building milestone 1 without asking a single question.**
If a section wouldn't survive that test, it's not specific enough yet.

## Record the decisions

Append the genuinely contested choices (ones where a reasonable alternative
lost) to `docs/context/50-decisions.md`, dated, with the alternative and the
reason it lost. One line each. Uncontested defaults don't need entries.

## Revising an existing architecture

When requirements shift or a milestone reveals a bad call, update
`30-architecture.md` in place so it stays currently-true, and log the change
in `50-decisions.md`. Flag any revision that invalidates already-written code
to the user before rewriting that code.
