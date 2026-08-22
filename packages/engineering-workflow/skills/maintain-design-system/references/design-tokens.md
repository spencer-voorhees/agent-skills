# Portable Design Tokens

Use this reference only when a project needs a new portable token source or already
uses the Design Tokens Community Group format.

## Decision rule

- Preserve an existing working token system and its conventions.
- Prefer DTCG-compatible tokens for new systems that cross tools, themes, brands, or
  platforms, or when a platform-neutral source of truth is an explicit goal.
- Do not introduce a token transformation pipeline for a small project when semantic
  CSS variables or the framework's existing theme system are sufficient.

## Logical layers

1. **Primitive tokens** hold raw palettes and scales.
2. **Semantic tokens** name stable product roles and alias primitives.
3. **Component tokens** are optional; add them only when component-level theming or
   governance requires another layer.

Application components should normally consume semantic or component tokens, not raw
palette values.

## DTCG format notes

- Tokens are JSON objects identified by `$value`.
- `$type` communicates the value type and may be inherited from a group.
- `$description` records purpose rather than restating the value.
- Curly-brace references such as `{color.palette.brand.600}` alias another token.
- Conventional file extensions are `.tokens` and `.tokens.json`.

The stable 2025.10 specification is a W3C Community Group report, not a W3C
Recommendation: https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/

## Generated output

Treat platform output as generated when the repository has a token build pipeline.
Document the source file, generated destinations, build command, and whether generated
files are committed. Never edit generated output instead of its source.

## Adoption checklist

- [ ] The project benefits from portable structured tokens.
- [ ] Token ownership and source of truth are explicit.
- [ ] Naming separates raw values from semantic roles.
- [ ] Theme and brand override behavior is documented.
- [ ] Generated output and its command are documented.
- [ ] Components consume stable semantic roles.
