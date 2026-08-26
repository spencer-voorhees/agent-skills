# Routing to Hyvä AI skills

Hyvä maintains its AI skills at
<https://github.com/hyva-themes/hyva-ai-tools>. This migration workflow expects the
relevant official skills to be installed. Install or update them from that repository
instead of copying their instructions into this skill. Their installer supports
individual skills, resolves their dependencies, and supports Codex and other common
coding agents.

At the start of the active migration unit, inspect the agent's available skill catalog.
Select every official Hyvä skill that owns part of the target work, then read each selected
skill fully before implementing that part. Do not load unrelated CMS, UI, or theme-creation
skills merely because they are installed.

Use only the skills relevant to the active component, capability, or migration slice:

| Need | Hyvä skill |
|---|---|
| Discover target themes | `hyva-theme-list` |
| Establish a child theme when the approved target does not exist | `hyva-child-theme` |
| Create CSP-compatible target interactivity | `hyva-alpine-component` |
| Evaluate and apply an available Hyvä UI component | `hyva-ui-component` |
| Render responsive storefront images | `hyva-render-media-image` |
| Register module sources for Tailwind v4 or exclude them | `hyva-tailwind-include-exclude` |
| Compile target-theme CSS | `hyva-compile-tailwind-css` |
| Create a Magento module for target-owned integration code | `hyva-create-module` |
| Write target journey and Alpine-aware end-to-end coverage | `hyva-playwright-test` |
| Create Hyvä Commerce CMS components | `hyva-cms-component` |
| Add a custom Hyvä Commerce CMS field | `hyva-cms-custom-field` |
| Inspect installed Hyvä Commerce CMS definitions | `hyva-cms-components-dump` |
| Determine the repository's Magento command wrapper | `hyva-exec-shell-cmd` |

The CMS skills apply only when Hyvä Commerce CMS is installed and the migration contract
calls for it. Hyvä UI may require licensed package access; do not install or assume access
without authorization.

## Invocation boundary

Give the selected Hyvä skill one bounded target task with the target theme/module,
acceptance criteria, installed version context, and relevant source evidence. Then return
to the migration workflow for parity verification and any status updates.

For component-level work, returning to the migration workflow means verifying the
component and its immediate integration point; it does not require loading or updating
the full program ledger.

The component skill does not decide whether a source feature should be rebuilt, adapted,
or omitted; whether a backend API can be removed; whether target behavior is equivalent;
or whether the migration item is complete. Those decisions remain with the migration
workflow.

If an expected skill is not installed, do not fabricate its contents. Report the missing
skill, then use the installed Hyvä package source and official documentation only when
they provide sufficient evidence; otherwise stop the affected implementation task.
