# Design System

## Status and ownership

- Status: Draft
- Owners: [team or maintainers]
- Token source: [path or system]
- Component source: [path or package]
- Component catalog: [Storybook URL/path, other tool, or none]
- Supported platforms: [web, iOS, Android, other]
- Supported themes: [light, dark, brands, other]

## Principles

Document a small number of product-specific principles that help resolve real design
decisions. Avoid generic aspirations that do not change implementation choices.

1. **[Principle]** — [What decision this principle changes]
2. **[Principle]** — [What decision this principle changes]

## Foundations and tokens

| Layer | Source | Generated output | Notes |
|---|---|---|---|
| Primitive tokens | [path] | [path or none] | Raw palette and scales |
| Semantic tokens | [path] | [path or none] | Stable roles consumed by UI |
| Component tokens | [path or none] | [path or none] | Add only when needed |

Token naming convention: `[document convention]`

Theme selection and overrides: [document runtime behavior and source of truth]

## Component model

- **Primitives** — Low-level reusable controls and layout building blocks.
- **Components** — Reusable UI with a stable, documented interface.
- **Patterns** — Recurring compositions or interactions spanning components.
- **Feature compositions** — Product-specific UI that remains with its feature.

Before creating a component:

1. Search the component source, exports, catalog, and nearby feature code.
2. Reuse an existing component when its semantics and behavior fit.
3. Add a variant when the difference is a recurring expression of the same component.
4. Create a new reusable component only when the need is distinct and likely to recur.
5. Keep business-specific composition in the feature unless reuse is demonstrated.

## Accessibility baseline

- Keyboard behavior: [expectations]
- Focus visibility: [expectations]
- Labels and descriptions: [expectations]
- Contrast and theming: [expectations]
- Reduced motion: [expectations]
- Automated checks: [commands or tools]

## Documentation and verification

- Component examples or stories: [location and convention]
- Unit and interaction tests: [location and command]
- Visual regression checks: [tool and command, or none]
- Design-system build: [command, or none]

## Change policy

Document how to add, deprecate, and remove tokens and components. Include compatibility
expectations when the design system is consumed by more than one application.

## Known gaps

- [Gap, impact, and intended follow-up]
