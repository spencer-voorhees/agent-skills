---
name: review-code
description: Perform a read-only review of a specified diff, branch, pull request, file, or completed change, producing prioritized findings with concrete failure scenarios and file-line evidence. Check correctness, requirement alignment, architecture, security, duplication, design-system use, and regression evidence as relevant. Use when the user explicitly asks for code review, an audit, or merge-readiness assessment.
---

# Review Code

## Why this exists

Standard linters catch syntax errors, but agent-assisted workflows face unique risks:
- Silently re-implementing helper functions created in earlier sessions.
- Endpoints deviating from the documented API strategy.
- Hardcoded hex values bypassing semantic design tokens.
- Subtle drift from agreed-upon acceptance criteria in feature specs.

This skill audits pending changes against the codebase and any applicable durable
requirements, architecture, decisions, and design-system contracts found through
repository instructions or established conventions.

## Scope

Default to reviewing current pending changes:
- `git diff` (staged and unstaged working tree), OR
- The feature branch diff against the default branch (`git diff main...HEAD`).
- If the user specifies a specific file or PR, review that explicit target. State the evaluated scope in your report header.

For changes that add or alter behavior, read
[`references/test-review.md`](references/test-review.md) before assessing test
coverage. Review is read-only unless the user separately requests fixes.

## The 6-Stage Audit Process

Perform these checks in strict order:

### 1. Correctness & Edge Cases
Identify verifiable logic bugs, unhandled null/undefined states, off-by-one errors,
unhandled Promise rejections, race conditions, and error leaks.
*Rule: Every correctness finding MUST include a concrete input or failure scenario that triggers the issue.*

### 2. Specification & Acceptance Criteria Alignment
Find the active requirement source, if one exists, and map changed files to it:
- Does the code satisfy the checkable acceptance criteria for `R1`, `R2`, ...?
- Did the change silently drop an edge case required by the spec?
- Did the change add unrequested features or speculative scope creep? (Unrequested scope is a finding, not a bonus).

### 3. Architecture & ADR Alignment
Check changes against applicable architecture documents and decision records:
- **Module Boundaries**: Are modules importing from forbidden layers (e.g. core domain importing UI or transport layers)?
- **API Strategy**: Do new endpoints follow established URL naming, payload shapes, and error envelope conventions?
- **Decisions**: Does the implementation contradict an accepted decision?

### 4. Code Duplication Search
For every newly created utility function, helper, or UI component, search the codebase
for existing equivalents (grep by concept and distinctive string patterns, not just identical names).
*Duplication is the signature failure of multi-session agent work. Prevent it before commit.*

### 5. Design System Compliance
If the diff touches UI code and a design-system contract or shared component library exists:
- Check for hardcoded hex/RGB colors, arbitrary margins/paddings, or ad-hoc border radii.
- Check that newly built components exist in the component inventory and implement required states (hover, focus-visible, disabled, loading).

### 6. Test Verification
- Verify that tests exist for new functionality according to any established testing
  strategy and the behavior's risk.
- Run the test suite (`npm test`, `pytest`, `cargo test`, etc.). Do not assume code works without test execution.

---

## Report Format

Generate a clean, prioritized markdown report:

```markdown
## Review: [Scope of Review]

**Verdict**: [ ✅ Ship It | ⚠️ Fix Blockers First | ❓ Needs Discussion ]

### Blockers
1. `src/services/auth.ts:45` — **[Issue Summary]**
   - **Problem**: [Concrete explanation and failure scenario]
   - **Fix**: [Actionable code suggestion]

### Should Fix
1. `src/components/Card.tsx:18` — **Hardcoded Color**
   - **Problem**: Uses `#1E293B` directly instead of `var(--bg-surface)`.
   - **Fix**: Replace with `var(--bg-surface)`.

### Consider
1. `src/utils/format.ts:12` — [Optional style or performance optimization]

### Checked & Clean
- [x] Correctness: Core logic and error handlers verified.
- [x] Spec Alignment: Implements R1 & R2 acceptance criteria without scope creep.
- [x] Architecture: Module boundaries and API conventions respected.
- [x] Duplication: No duplicate helpers found in codebase.
- [x] Design System: Semantic tokens used exclusively.
- [x] Tests: Test suite ran and passed (12/12 tests green).
```

## Boundaries

- **Report, Don't Silently Rewrite**: Present findings to the user with clear rationale. Only apply fixes when requested.
- **Identify Doc Drift**: If the code is correct but durable documentation is outdated,
  flag the specific update; use `capture-decisions` only when the user asks to record it.
