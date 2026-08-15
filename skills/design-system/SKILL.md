---
name: design-system
description: Create or extend the project's reusable design system — semantic tokens, typography/spacing scales, and a component inventory — written to docs/architecture/design-system.md plus real token code in the codebase, so UI stays consistent across every session. Use whenever building or styling UI, adding components, creating themes, or when the user says "design system", "style this", "make it look good/polished", "theme", "dark mode", "UI components", "color tokens", or when buttons, colors, or spacing have started to drift between screens.
---

# Design System (Tokens & Component Inventory)

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

## The Two Deliverables

### Deliverable 1: `docs/architecture/design-system.md`

Author or update `docs/architecture/design-system.md` using the following structure:

```markdown
# Design System Specification

## 1. Visual Principles
- **[Principle 1]**: [e.g., "Calm & Content-First: Maximum one vibrant accent color per view."]
- **[Principle 2]**: [e.g., "High Affordability: Interactive elements have unmistakable hover and focus rings."]

## 2. Semantic Color Tokens
| Token | Light Value | Dark Value | Purpose / Role |
|---|---|---|---|
| `--bg-canvas` | `#FFFFFF` | `#0F172A` | Primary application background |
| `--bg-surface` | `#F8FAFC` | `#1E293B` | Cards, panels, modal dialogs |
| `--bg-surface-hover` | `#F1F5F9` | `#334155` | Hover state for interactive surfaces |
| `--text-primary` | `#0F172A` | `#F8FAFC` | Headings and high-contrast body text |
| `--text-muted` | `#64748B` | `#94A3B8` | Secondary labels, timestamps, captions |
| `--border-subtle` | `#E2E8F0` | `#334155` | Card outlines, dividers |
| `--border-focus` | `#3B82F6` | `#60A5FA` | Focus rings for accessibility |
| `--action-primary` | `#2563EB` | `#3B82F6` | Primary CTAs and active states |
| `--action-danger` | `#DC2626` | `#EF4444` | Destructive actions, validation errors |
| `--feedback-success` | `#16A34A` | `#22C55E` | Confirmation messages, success badges |

## 3. Typography Scale
- **Font Families**:
  - Sans: `Inter, -apple-system, BlinkMacSystemFont, sans-serif`
  - Mono: `JetBrains Mono, monospace`
- **Scale**:
  - `Display`: `2rem` (32px) / line-height `1.2` / weight `700`
  - `Heading 1`: `1.5rem` (24px) / line-height `1.3` / weight `600`
  - `Heading 2`: `1.25rem` (20px) / line-height `1.4` / weight `600`
  - `Body`: `1rem` (16px) / line-height `1.5` / weight `400`
  - `Small / Caption`: `0.875rem` (14px) / line-height `1.5` / weight `400`

## 4. Spacing & Elevation Scale
- **Spacing**: `4px` (xxs), `8px` (xs), `12px` (sm), `16px` (md), `24px` (lg), `32px` (xl), `48px` (2xl)
- **Radii**: `4px` (subtle), `8px` (default container), `9999px` (pill/badge)
- **Shadows**:
  - `--shadow-sm`: `0 1px 2px 0 rgb(0 0 0 / 0.05)`
  - `--shadow-md`: `0 4px 6px -1px rgb(0 0 0 / 0.1)`

## 5. Component Inventory

### Button
- **Variants**: `primary`, `secondary`, `outline`, `danger`, `ghost`
- **States**: `default`, `hover`, `active`, `focus-visible`, `disabled`, `loading`
- **Rules**: Exactly one primary button per screen/view.

### Input / Textarea
- **Variants**: `default`, `error`, `disabled`
- **States**: `empty`, `filled`, `focus-visible`
- **Rules**: Inputs must always include an associated label and explicit error message container.

## 6. Strict Anti-Patterns
- **No Hardcoded Hex/RGB**: Raw hex colors inside components are strictly prohibited. Always use semantic tokens.
- **No Arbitrary Spacing**: Use the 4/8/12/16/24/32/48 scale exclusively.
```

---

### Deliverable 2: Tokens in Code

Write the design tokens into the project in the format native to the stack:
- **CSS / Web**: `src/styles/tokens.css` with CSS custom properties.
- **Tailwind**: Configure `theme.extend` in `tailwind.config.js` pointing to semantic variables.
- **TypeScript / Theme Objects**: `src/theme/tokens.ts`.

Ensure tokens support dark mode out of the box (e.g. `@media (prefers-color-scheme: dark)` or `.dark` class).

---

## Core Rules

1. **Semantic Role Naming (Role-Based Tokens)**:
   Name tokens for their *role* (`--bg-surface`, `--text-muted`, `--action-primary`), never their literal appearance (`--gray-200`, `--blue-500`). Role names make re-theming and dark mode seamless without refactoring component markup.
2. **Reuse Before Create**:
   Before creating a new UI component, check the inventory in `docs/architecture/design-system.md`. If a similar component exists, extend it with a new variant or state.
3. **Synchronize Code and Docs**:
   Never let the markdown specification and live token code drift. When adding a token or component, update both deliverables in the same session.
