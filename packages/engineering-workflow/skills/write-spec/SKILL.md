---
name: write-spec
description: Write or update a bounded feature specification, implementation brief, or PRD with observable acceptance criteria, constraints, non-goals, and open questions. Use when the user asks to define, scope, specify, or clarify a meaningful change before implementation. Do not require a formal spec for a small, already-clear edit, and do not scaffold repository documentation unless that setup is requested.
---

# Write Spec

## Outcome

Produce a clear contract for downstream design, implementation, and review without
imposing a documentation system on the repository. A durable specification is useful
when requirements will be reviewed, implemented across sessions, or referenced later;
a short planning response may be enough for a small or exploratory request.

## Choose the destination

If the user requested a file, resolve its destination in this order:

1. Use the path explicitly requested by the user.
2. Follow repository instructions such as `AGENTS.md`.
3. Follow an existing, unambiguous requirements convention discovered in the repo.
4. If none exists, ask where to save the spec rather than creating a new documentation
   tree. In a non-interactive run, return the draft in the task output and identify that
   no repository destination was established.

Do not scaffold documentation directories, modify ignore or merge rules, or establish
repository policy as a side effect of writing a spec.

## Process

### 1. Inventory what already exists

Before asking the user questions, discover what the repository already knows:

- Read `AGENTS.md`, `README.md`, existing requirement and architecture artifacts, and
  package manifests (`package.json`, `Cargo.toml`, `pyproject.toml`, etc.).
- Skim existing models, schemas, and routes if code already exists.
- Review existing decision records to understand past architectural boundaries.

### 2. High-leverage scoping interview

Ask the user only what cannot be inferred from the codebase, focusing on high-leverage decisions:

- **Problem & Persona**: Who is using this and what exact pain point does it solve?
- **Core Capabilities (v1)**: The 3–5 primary user workflows required for v1.
- **Constraints & Non-Goals**: Hard technical requirements, third-party constraints, and explicit non-goals (things deliberately out of scope for v1).

*Autonomous Mode*: If running non-interactively without user input, infer conservatively from the request and codebase, and explicitly flag every inference as an `OPEN QUESTION:` rather than assuming.

### 3. Write the specification

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

- **Numbered Requirements (`R1`, `R2`, ...)**: Number requirements in formal specs so
  subsequent ADRs, commits, pull requests, and `review-code` findings can reference them.
- **Concrete Acceptance Criteria**: Avoid vague statements like "fast" or "user-friendly". Write observable, checkable criteria (e.g., "Returns 401 Unauthorized when Bearer token is expired").
- **Explicit Non-Goals**: Clearly define what is *not* being built. Non-goals protect future agents from gold-plating or over-engineering.
- **Single Source of Truth**: State facts in their respective sections; avoid duplicating text across multiple documents.

### 5. Updating an Existing Spec

When requirements evolve mid-flight, update the established specification directly in
place. If a requirement is descoped or significantly altered, preserve the rationale in
the repository's existing decision system when that history has durable value.
