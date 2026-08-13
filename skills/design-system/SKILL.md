---
name: design-system
description: Create or extend the project's reusable design system — semantic tokens, type/spacing scales, and a component inventory — written to docs/context/40-design-system.md plus real token code in the codebase, so UI stays consistent across every session. Use whenever building or styling UI, adding components, or when the user says "design system", "make it look good/consistent/polished", "theme", "dark mode", or when buttons, colors, or spacing have started to drift between screens.
---

# Design System

## Why this exists

UI consistency dies by a thousand small sessions: each one picks a slightly
different gray, a slightly different padding, a third button variant. The fix
is a single source of truth with two halves — a document that says what the
system is, and token code that makes the right choice the easy choice. Once
both exist, "style this page" becomes "apply the system" instead of "invent
a style".

## Prerequisites

Read `docs/context/00-brief.md` and `20-constraints.md` first — the audience
and platform shape the design (a developer tool and a kids' app should not
come out looking the same). Read `30-architecture.md` to learn the UI stack,
since that decides what form the tokens take. If the context package doesn't
exist, build it with the **context-package** skill first.

Then audit any existing UI code. If styles already exist, the job is to
consolidate what's there into a system — not to impose a new look over it.
Extract the colors and spacing actually in use, pick the intended values,
and migrate outliers toward them.

## The two deliverables

### 1. docs/context/40-design-system.md

```markdown
# Design System

## Principles
[2–4 adjectives with one sentence each on what they mean concretely.
E.g. "Calm: no more than one accent color per screen."]

## Color tokens
| Token | Light | Dark | Use for |
|---|---|---|---|
| --bg | ... | ... | page background |
| --surface | ... | ... | cards, panels |
| --text | ... | ... | primary text |
| --text-muted | ... | ... | secondary text |
| --accent | ... | ... | primary actions, links |
| --border | ... | ... | dividers, input borders |
| --danger | ... | ... | destructive actions, errors |

[This table is a floor, not a ceiling — add role tokens the product
obviously needs (--success for a habit tracker, --warning for a monitor)
at creation time, freely. Only *contradictions* of existing choices need a
decision-log entry; additions don't.]

## Typography
[Font stack(s) and a scale: size/weight/line-height per level
(display, heading, body, small). Name each level.]

## Spacing & shape
[The spacing scale (e.g. 4/8/12/16/24/32/48), corner radii, shadows.
Small fixed sets — the point is that there are few choices.]

## Component inventory
### Button
- Variants: [primary / secondary / danger ...]
- States: [default, hover, active, disabled, loading]
- Rules: [e.g. one primary button per view]
### [Every other component, added as it's built]

## Don't
- [the specific mistakes this project must avoid, e.g. "no raw hex values
  in components — tokens only"]
```

### 2. Tokens as code

Write the tokens in whatever form the stack actually consumes — CSS custom
properties, a Tailwind config, a theme object, design-token JSON. Put the
file where `30-architecture.md`'s module map dictates; if the module map
doesn't reserve a spot, use the stack's conventional location and add it to
the module map yourself, marked as owned by this skill — the location must
end up recorded in exactly one place either way. Include dark mode from day
one if the platform can express it (it's cheap now and expensive to
retrofit).

The document and the code must never disagree — and don't take that on
faith: before finishing, mechanically compare the values in the doc's
tables against the token code (grep the hex values and scale numbers on
both sides). Eyeballing is how the two drift on day one.

## Semantic tokens, not raw values

Name tokens for their role (`--surface`, `--text-muted`, `--danger`), never
their appearance (`--gray-200`, `--light-blue`). Role names survive a
re-theme and make dark mode a token swap instead of a rewrite. Components
reference tokens exclusively; a hex value inside a component is a bug the
review skill will flag.

## Reuse before create

Before building any UI element, check the component inventory. If something
close exists, extend it (a new variant or state) rather than creating a
sibling. If a genuinely new component is needed, add it to the inventory in
the same session you build it — an inventory that lags the code stops being
consulted, and drift returns.

## Extending the system

When a screen needs something the system can't express, that's a system gap,
not a license for a one-off. Add the token/variant to both deliverables,
then use it. If it contradicts an existing choice (e.g. a second accent
color), log the decision and its reason in `docs/context/50-decisions.md`.
