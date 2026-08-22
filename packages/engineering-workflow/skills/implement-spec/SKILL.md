---
name: implement-spec
description: Implement a bounded feature, bug fix, or refactor from an approved specification, issue, or clearly stated request. Reuse existing code and UI components, follow architecture and repository conventions, add proportionate tests, run relevant verification, and avoid unrelated cleanup. Use when the user asks to implement, build, fix, or code an already-scoped change. Do not use when requirements or consequential architecture remain unresolved.
---

# Implement Spec

Deliver the smallest coherent change that satisfies the agreed requirements and leaves
credible regression evidence.

## Establish the contract

Before editing:

1. Read repository instructions and inspect the current working tree without disturbing
   existing changes.
2. Identify the controlling requirement: a spec, issue, acceptance criteria, or the
   user's explicit request.
3. Read relevant architecture, ADRs, design-system guidance, and nearby implementation.
4. Resolve only ambiguities that materially change product behavior or architecture.

If the request is still exploratory, route to specification or architecture rather than
inventing a contract during implementation.

## Implement

- Map edits to requirements and avoid unrelated cleanup.
- Follow established module boundaries, naming, error handling, and public APIs.
- Search for existing utilities, components, and patterns before creating new ones.
- For UI work, reuse the design system and keep feature-specific compositions local.
- Preserve compatibility unless the approved change explicitly alters it.
- Make migrations and external side effects explicit and proportionate to the request.

## Test and verify

Read [`references/testing.md`](references/testing.md) whenever behavior changes. Add or
update tests at the cheapest level that credibly proves the behavior. Run focused checks
first, then broader build, type, lint, or test commands proportional to risk.

Never claim a check passed unless it ran successfully. Report skipped or blocked checks
and the reason.

## Finish

Review the final diff for scope, accidental changes, debug artifacts, duplicated code,
and requirement coverage. Summarize the delivered behavior and verification evidence.
Do not commit, push, open a pull request, or perform unrelated external actions unless
the user requests them.
