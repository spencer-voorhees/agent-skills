---
name: frontend-design
description: Design or substantially reshape a web interface with a distinctive, brief-specific visual direction, intentional typography and layout, realistic content, responsive behavior, and complete interaction states. Use when the user asks for frontend design, a new screen or page, a visual redesign, or a polished non-generic interface. Respect an existing design system and do not activate for minor local styling adjustments.
---

# Frontend Design

Create an interface whose visual language, structure, content, and behavior follow from
the brief rather than a reusable AI template. The user's stated direction, supplied
references, brand assets, and repository conventions take precedence over this skill's
preferences.

## Establish the design read

Before proposing or editing a design:

1. Inspect the brief, audience, interface's primary job, real content, reference material,
   existing UI, shared components, tokens, and technical constraints.
2. Classify the work as **greenfield**, **preserve**, or **overhaul**. For a redesign,
   audit before editing. Do not silently change brand identity, navigation semantics,
   content hierarchy, URLs, form contracts, or established interaction behavior.
3. Infer a concise design read: subject, audience, purpose, and visual language. Ask a
   focused question only when plausible interpretations would lead to materially
   different results.
4. Calibrate three qualitative axes rather than defaulting to maximum decoration:
   - **Variance**: restrained and systematic ↔ expressive and asymmetric
   - **Motion**: mostly static ↔ interaction-rich and cinematic
   - **Density**: spacious and editorial ↔ compact and information-dense

Treat these axes as design reasoning, not configuration the user must manage.

## Form a direction before building

Create a compact plan appropriate to the requested deliverable:

- **Visual premise**: the idea connecting the subject to the interface's material,
  imagery, typography, and composition.
- **System**: palette roles, type roles, spacing and shape logic, layout behavior, and
  icon or image language.
- **Signature**: one memorable element that embodies the brief. Spend boldness there
  and keep supporting elements disciplined.
- **Content**: realistic domain language and data. Interface labels describe what the
  user controls, remain consistent across the flow, and avoid promotional filler.
- **Behavior**: responsive transformations, interaction states, async states, and a
  motion stance proportional to the product.

Critique the plan before implementation. Replace choices that could belong to an
unrelated product, decoration that encodes nothing, repeated layout formulas, and
familiar visual effects selected without a subject-specific reason. A known pattern is
not forbidden when the brief genuinely calls for it.

## Fit the project

- Reuse existing tokens, primitives, and components when they satisfy the need. Search
  before creating.
- Distinguish an official design system from an aesthetic reference. Use an existing or
  explicitly selected system through its supported components and tokens; do not claim
  that an inspired approximation is an official implementation.
- Route reusable gaps in tokens, themes, variants, or components to
  `maintain-design-system`. Keep page-specific composition and art direction local.
- Preserve the current framework and styling approach unless changing them is part of
  the request. Verify dependencies before importing them.
- Use real brand and product assets when available. Do not fabricate product screenshots,
  endorsements, status, or metrics that could be mistaken for real claims.

## Complete the experience

Design the relevant states, not only the ideal populated screen: default, hover, focus,
pressed, selected, disabled, loading, empty, partial, error, and success. Include only
states the interaction can actually enter.

- For interactive, form-heavy, or dynamic interfaces, read
  [`references/accessibility.md`](references/accessibility.md).
- For multi-column, data-dense, or unusually wide layouts, read
  [`references/responsive-design.md`](references/responsive-design.md).
- For asynchronous or data-dependent surfaces, read
  [`references/interface-states.md`](references/interface-states.md).
- When producing or changing rendered UI, read
  [`references/visual-verification.md`](references/visual-verification.md).

## Deliver and refine

Match the output to the request: a visual-direction brief, structured recommendation,
mockup, prototype, or implemented interface. Do not assume a design request authorizes
code changes.

When implementation is in scope, build from the reviewed direction and derive local
choices from it consistently. Use screenshots or another available visual inspection
method to critique the rendered result at representative viewports, then make a focused
refinement pass. Verify hierarchy, system consistency, real content, responsive behavior,
interaction states, and accessibility rather than judging quality from source code alone.
