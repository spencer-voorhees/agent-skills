---
name: deliver-change
description: Coordinate an end-to-end engineering change from requirements through architecture, design, implementation, verification, review, and durable documentation. Use when the user explicitly asks to deliver a substantial feature, bug fix, or refactor through the complete workflow. Select only the stages the change actually needs; do not impose full ceremony on a small or already-scoped task.
---

# Deliver Change

Coordinate the workflow while preserving one clear contract and one coherent final
result. This skill routes work; the specialist skills define how each stage is done.

## Establish scope

Inspect repository instructions, the current working tree, existing requirements,
architecture, design-system context, and relevant implementation before selecting
stages. Preserve existing changes and user decisions.

Choose the minimum useful path:

| Condition | Skill |
|---|---|
| Requirements are materially ambiguous | `write-spec` |
| Consequential system boundaries or migrations are unresolved | `design-architecture` |
| A new or substantially redesigned interface needs visual direction | `frontend-design` |
| Reusable tokens, themes, variants, or components must evolve | `maintain-design-system` |
| The change is sufficiently scoped to build | `implement-spec` |
| An independent readiness assessment is requested | `review-code` |
| A durable decision, learning, or handoff should be recorded | `capture-decisions` |
| Repeated attempts have stalled | `debug-systematically` |

Do not require documentation artifacts that the repository does not use. A clear local
bug fix may need only implementation and verification. A greenfield feature may need
the complete sequence.

## Maintain the contract

- Carry acceptance criteria and explicit non-goals through implementation and review.
- Treat existing repository conventions as constraints unless changing them is approved.
- Resolve contradictions between specs, architecture, design, and code rather than
  silently choosing one.
- Keep design-system changes reusable and feature compositions local.
- Keep verification proportional to behavior and risk.
- Do not authorize commits, pushes, deployments, or unrelated external actions.

## Finish

Report the behavior delivered, important decisions, files or areas changed, verification
evidence, unresolved risks, and any intentionally deferred work. Do not claim a stage
was completed when its observable output or verification is missing.
