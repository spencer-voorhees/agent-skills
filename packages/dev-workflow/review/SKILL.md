---
name: review
description: Review pending changes against the project's specifications, architecture, and design system — auditing correctness, acceptance criteria alignment, architecture drift, duplicate code, design-system violations, and tests — producing ranked findings with file:line references. Use before any commit, PR, or merge, whenever the user says "review", "check this", "audit my code", "pre-commit check", "look over my changes", "is this ready to merge", or after completing a milestone or implementation task.
---

# Review (Pre-Commit & PR Diff Audit)

## Why this exists

Standard linters catch syntax errors, but agent-assisted workflows face unique risks:
- Silently re-implementing helper functions created in earlier sessions.
- Endpoints deviating from the documented API strategy.
- Hardcoded hex values bypassing semantic design tokens.
- Subtle drift from agreed-upon acceptance criteria in feature specs.

This skill audits pending git diffs against the durable Docs-as-Code ground truth
(`docs/specs/`, `docs/architecture/`, `docs/adr/`) before code is committed or merged.

## Scope

Default to reviewing current pending changes:
- `git diff` (staged and unstaged working tree), OR
- The feature branch diff against the default branch (`git diff main...HEAD`).
- If the user specifies a specific file or PR, review that explicit target. State the evaluated scope in your report header.

## The 6-Stage Audit Process

Perform these checks in strict order:

### 1. Correctness & Edge Cases
Identify verifiable logic bugs, unhandled null/undefined states, off-by-one errors,
unhandled Promise rejections, race conditions, and error leaks.
*Rule: Every correctness finding MUST include a concrete input or failure scenario that triggers the issue.*

### 2. Specification & Acceptance Criteria Alignment
Map changed files to the active feature spec in `docs/specs/<feature>.md`:
- Does the code satisfy the checkable acceptance criteria for `R1`, `R2`, ...?
- Did the change silently drop an edge case required by the spec?
- Did the change add unrequested features or speculative scope creep? (Unrequested scope is a finding, not a bonus).

### 3. Architecture & ADR Alignment
Check changes against `docs/architecture/system-overview.md` and `docs/adr/`:
- **Module Boundaries**: Are modules importing from forbidden layers (e.g. core domain importing UI or transport layers)?
- **API Strategy**: Do new endpoints follow established URL naming, payload shapes, and error envelope conventions?
- **ADRs**: Does the implementation contradict any accepted ADR in `docs/adr/`?

### 4. Code Duplication Search
For every newly created utility function, helper, or UI component, search the codebase
for existing equivalents (grep by concept and distinctive string patterns, not just identical names).
*Duplication is the signature failure of multi-session agent work. Prevent it before commit.*

### 5. Design System Compliance
If the diff touches UI code and `docs/architecture/design-system.md` exists:
- Check for hardcoded hex/RGB colors, arbitrary margins/paddings, or ad-hoc border radii.
- Check that newly built components exist in the component inventory and implement required states (hover, focus-visible, disabled, loading).

### 6. Test Verification
- Verify that tests exist for new functionality per the testing strategy in `docs/architecture/system-overview.md`.
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
- **Identify Doc Drift**: If the code is correct but the specification or architecture is outdated, flag that `docs/` needs an update via the **remember** skill.
