---
name: spec
description: Author or update feature specifications and PRDs in docs/specs/ using Spec-Driven Development. Captures problem statements, user stories, checkable acceptance criteria (R1..Rn), constraints, and non-goals. Automatically scaffolds the docs/ directory structure if missing. Use at the start of any new project or feature, whenever the user says "build an app", "create a feature", "spec out", "scope", "write a brief", "write a PRD", "capture requirements", or before building functionality.
---

# Spec (Spec-Driven Development)

## Why this exists

Agent sessions are ephemeral; durable specifications are not. Spec-Driven
Development anchors software engineering in clear, checkable requirements before
code is written. Downstream skills depend on it: `architect` designs the system
to fulfill the spec, `design-system` satisfies UI requirements, `review` judges
diffs against acceptance criteria, and `remember` captures architectural decisions.

A vague or missing spec leads to speculative coding, scope creep, and architectural
drift. Invest the effort here first.

## Docs-as-Code Layout

All skills share a Docs-as-Code contract in the repository:

```
docs/
├── specs/                          # Feature Specs & PRDs (owned by spec)
│   ├── _template.md
│   └── <feature-slug>.md           # e.g., auth-oauth.md, billing.md
├── architecture/                   # System Blueprint & Contracts (owned by architect & design-system)
│   ├── system-overview.md
│   └── design-system.md
├── adr/                            # Architectural Decision Records (owned by remember & architect)
│   ├── 0000-template.md
│   └── 0001-<decision-title>.md
├── learnings.md                    # Curated gotchas & runbook (curated by remember)
└── handoff.md                      # Active session handoff (git-ignored or branch-scoped)
```

Each feature gets its own dedicated specification in `docs/specs/<feature-slug>.md`.
Using individual feature files ensures multiple developers and autonomous agents
can draft and merge features simultaneously with **zero git merge conflicts**.

If the `docs/` structure does not exist yet, scaffold the directories and stub
the templates.

## Process

### 0. Auto-scaffold if missing

If `docs/` or `docs/specs/` does not exist in the project, automatically create:
- `docs/specs/`
- `docs/architecture/`
- `docs/adr/`
- `docs/learnings.md`
- `.gitattributes` (with `docs/learnings.md merge=union` and `docs/specs/*.md merge=union`)

### 1. Inventory what already exists

Before asking the user questions, discover what the repository already knows:

- Read `README.md`, existing specs in `docs/specs/`, architecture docs, and package manifests (`package.json`, `Cargo.toml`, `pyproject.toml`, etc.).
- Skim existing models, schemas, and routes if code already exists.
- Review existing ADRs in `docs/adr/` to understand past architectural boundaries.

### 2. High-leverage scoping interview

Ask the user only what cannot be inferred from the codebase, focusing on high-leverage decisions:

- **Problem & Persona**: Who is using this and what exact pain point does it solve?
- **Core Capabilities (v1)**: The 3–5 primary user workflows required for v1.
- **Constraints & Non-Goals**: Hard technical requirements, third-party constraints, and explicit non-goals (things deliberately out of scope for v1).

*Autonomous Mode*: If running non-interactively without user input, infer conservatively from the request and codebase, and explicitly flag every inference as an `OPEN QUESTION:` rather than assuming.

### 3. Write the Specification (`docs/specs/<feature-slug>.md`)

Write a concise, structured markdown file using this format:

```markdown
# Spec: [Feature Name]

**Status**: [Draft | In Review | Approved | Implemented]
**Author**: [Name / Agent]
**Date**: [YYYY-MM-DD]

## 1. Overview & Problem Statement
- **What**: One paragraph explaining what this feature is.
- **Who**: The user/persona and the problem being solved.
- **Why**: The motivation and expected outcome.

## 2. Requirements & Acceptance Criteria

### R1: [Primary User Capability]
- **Story**: As a [user], I want to [action] so that [benefit].
- **Acceptance Criteria**:
  - [ ] Given [precondition], when [action], then [expected outcome].
  - [ ] [Concrete checkable condition]

### R2: [Secondary Capability / Edge Case]
- **Story**: ...
- **Acceptance Criteria**:
  - [ ] ...

## 3. Constraints & Non-Goals
- **Non-Goals (v1)**:
  - [Deliberately excluded scope 1]
  - [Deliberately excluded scope 2]
- **Technical Constraints**:
  - [Stack, performance, or regulatory constraint]

## 4. Open Questions
- [ ] `OPEN QUESTION`: [Any unresolved dependency, scope question, or blocker]
```

### 4. Quality Standards for Specs

- **Numbered Requirements (`R1`, `R2`, ...)**: Always number requirements so subsequent ADRs, commit messages, PRs, and `review` steps can reference them directly (e.g. "Satisfies R1 acceptance criteria").
- **Concrete Acceptance Criteria**: Avoid vague statements like "fast" or "user-friendly". Write observable, checkable criteria (e.g., "Returns 401 Unauthorized when Bearer token is expired").
- **Explicit Non-Goals**: Clearly define what is *not* being built. Non-goals protect future agents from gold-plating or over-engineering.
- **Single Source of Truth**: State facts in their respective sections; avoid duplicating text across multiple documents.

### 5. Updating an Existing Spec

When requirements evolve mid-flight, update the specification directly in place. If an existing requirement is descoped or significantly altered, create an ADR or log a note to document the rationale.
