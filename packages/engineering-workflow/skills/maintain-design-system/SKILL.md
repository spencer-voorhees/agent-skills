---
name: maintain-design-system
description: Establish, inspect, or evolve a project's reusable design-system foundations, semantic tokens, themes, component inventory, variants, and usage rules. Use when bootstrapping a design system, extending reusable UI infrastructure, resolving component duplication, or deciding whether a new UI need belongs in the shared system. Do not activate for every local styling change or create speculative components.
---

# Maintain Design System

## Why this exists

UI consistency deteriorates rapidly across multi-session and multi-developer projects:
each session introduces slightly different hex codes, arbitrary padding, and bespoke
button styles.

The solution is a single source of truth with two synchronized halves:
1. **Design System Specification** (`docs/architecture/design-system.md`): Documents the visual principles, token scales, and component inventory.
2. **Tokens in Code**: Live code assets (CSS custom properties, Tailwind config, design-token JSON) that make using the design system frictionless.

Once established, "style this screen" becomes "apply existing tokens" rather than "invent a one-off style."

## Prerequisites

1. **Read Requirements & Architecture**: Read `docs/specs/` and `docs/architecture/system-overview.md`
   to understand target audience, platform constraints, and the UI tech stack (React, Vue, Svelte, Tailwind, Vanilla CSS, etc.).
2. **Audit Existing UI**: If styles already exist, extract the colors, spacing, and typography
   currently in use, standardize them into clean scales, and migrate outliers toward them.

## Supporting Resources

Use these only when the current project needs them:

- When establishing or documenting a design system, adapt
  [`assets/design-system-overview.template.md`](assets/design-system-overview.template.md).
- When the repository lacks a discoverable component catalog, adapt
  [`assets/component-inventory.template.md`](assets/component-inventory.template.md).
- When creating a new portable token source, read
  [`references/design-tokens.md`](references/design-tokens.md) and adapt
  [`assets/tokens.template.tokens.json`](assets/tokens.template.tokens.json).
- When Storybook is already present or the user wants an isolated component catalog,
  read [`references/storybook.md`](references/storybook.md).

These resources define a repeatable logical contract, not a mandatory source-tree
layout. Preserve the repository's existing paths and conventions. Scaffold from a
template only when initializing a missing artifact is in scope.

## The Two Deliverables

### Deliverable 1: `docs/architecture/design-system.md`

Author or update the project's existing design-system documentation. If none exists,
adapt [`assets/design-system-overview.template.md`](assets/design-system-overview.template.md)
to the project's needs rather than copying irrelevant sections unchanged.

---

### Deliverable 2: Tokens in Code

Write the design tokens into the project in the format native to the stack:
- **Portable source**: DTCG-compatible `.tokens.json` when interoperability across
  tools, themes, brands, or platforms is a real requirement.
- **CSS / Web**: `src/styles/tokens.css` with CSS custom properties.
- **Tailwind**: Configure `theme.extend` in `tailwind.config.js` pointing to semantic variables.
- **TypeScript / Theme Objects**: `src/theme/tokens.ts`.

Ensure tokens support dark mode out of the box (e.g. `@media (prefers-color-scheme: dark)` or `.dark` class).
Do not migrate a working token system solely to adopt DTCG.

---

## Core Rules

1. **Semantic Role Naming (Role-Based Tokens)**:
   Name tokens for their *role* (`--bg-surface`, `--text-muted`, `--action-primary`), never their literal appearance (`--gray-200`, `--blue-500`). Role names make re-theming and dark mode seamless without refactoring component markup.
2. **Reuse Before Create**:
   Before creating a new UI component, check the inventory in `docs/architecture/design-system.md`. If a similar component exists, extend it with a new variant or state.
3. **Synchronize Code and Docs**:
   Never let the markdown specification and live token code drift. When adding a token or component, update both deliverables in the same session.
