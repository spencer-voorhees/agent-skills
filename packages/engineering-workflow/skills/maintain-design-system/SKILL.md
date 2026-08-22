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
1. **Design-system documentation**: Visual principles, token scales, component
   inventory, and ownership rules in the repository's established location.
2. **Tokens in code**: Live code assets (CSS custom properties, Tailwind config,
   design-token JSON) that make using the design system frictionless.

Once established, "style this screen" becomes "apply existing tokens" rather than "invent a one-off style."

## Prerequisites

1. **Read Requirements & Architecture**: Find relevant requirements and architecture
   through repository instructions and existing conventions to understand the audience,
   platform constraints, and UI stack.
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

## Choose the documentation destination

For requested design-system documentation, use an explicit user path first, then
repository instructions such as `AGENTS.md`, then an existing unambiguous design-system
convention. If none exists, ask where to save it rather than creating a documentation
tree. In a non-interactive run, update the code source of truth and report the proposed
documentation in the task output when a repository file is not required.

## The two deliverables

### Deliverable 1: Design-system documentation

Author or update the project's existing design-system documentation. If none exists,
adapt [`assets/design-system-overview.template.md`](assets/design-system-overview.template.md)
to the project's needs rather than copying irrelevant sections unchanged.

---

### Deliverable 2: Tokens in code

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
   Before creating a new UI component, find the repository's component inventory or
   inspect the shared component implementation. If a similar component exists, extend
   it with a new variant or state.
3. **Synchronize Code and Docs**:
   When durable design-system documentation exists, keep it synchronized with live token
   and component code. Do not create a Markdown specification solely to satisfy this rule.
