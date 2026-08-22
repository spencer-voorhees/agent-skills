# Storybook Component Catalog

Use Storybook when it is already present or when the user wants an isolated component
catalog. Do not install it automatically merely because a task touches UI.

## Discovery

Before creating or extending a component:

1. Inspect Storybook configuration and story globs.
2. Search existing `*.stories.*` files, public exports, and component directories.
3. Render relevant stories when the environment supports it.
4. Treat the production component as the source; a story is a reproducible state of
   that component, not a duplicate implementation.

## Story expectations

Add stories for meaningful public variants and states. Choose states based on the
component rather than filling a universal checklist. Common candidates include:

- Default and documented variants
- Disabled and read-only behavior
- Loading or asynchronous behavior
- Validation and error states
- Empty, long-content, and constrained-width cases
- Theme differences
- Keyboard or interaction sequences

Use realistic labels and data. Avoid stories that differ only cosmetically without
documenting a meaningful state or contract.

## CSF example for React

Adapt imports and types to the project's installed Storybook version and framework.

```tsx
import type { Meta, StoryObj } from "@storybook/react";
import { Button } from "./Button";

const meta = {
  component: Button,
} satisfies Meta<typeof Button>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Primary: Story = {
  args: {
    variant: "primary",
    children: "Save changes",
  },
};

export const Disabled: Story = {
  args: {
    disabled: true,
    children: "Save changes",
  },
};
```

For Vue, Angular, Svelte, Web Components, or another renderer, follow the installed
framework adapter rather than copying React syntax.

## Verification

Run the repository's existing Storybook build and relevant interaction, accessibility,
or visual-regression commands. Do not claim visual or behavioral validation unless the
corresponding check actually ran.

Official documentation: https://storybook.js.org/docs/writing-stories
