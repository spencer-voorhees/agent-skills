# Source-to-target analysis

Use these mappings as investigation prompts, not automatic conversions. The correct
target depends on the installed Magento and Hyvä versions, extensions, and project
conventions.

## Trace a capability

Start from a customer journey or URL and follow all contributors to its behavior:

- route registration, URL rewrites, redirects, and store-code behavior
- React containers/components, ScandiPWA plugins, render maps, and extension overrides
- queries, mutations, fragments, resolver modules, and error handling
- Redux or other shared state, persistence, cookies, local storage, and session changes
- Magento configuration, CMS content, product/category/customer attributes, and cron or
  indexer dependencies
- third-party modules, payment and shipping integrations, analytics, consent, and feature
  flags
- translations, prices, taxes, currencies, customer groups, and store views
- loading, empty, error, validation, success, responsive, keyboard, and focus states
- metadata, canonical links, structured data, robots behavior, and analytics events

Distinguish custom business behavior from ScandiPWA framework plumbing. Only the former
normally belongs in the target contract.

## Target pattern heuristics

| ScandiPWA concern | Investigate first in Hyvä/Magento |
|---|---|
| Client route or page | Existing Magento controller, URL rewrite, layout handle, page layout, and template |
| React presentation component | Existing Hyvä template, Hyvä UI variant, reusable PHTML partial, block, or view model |
| Local interactive state | Small CSP-compatible Alpine component scoped to the rendered element |
| Redux/customer session state | Server-rendered state, Magento customer-data section, section invalidation, or Alpine store only when target conventions require it |
| GraphQL query for Magento storefront data | Block/view model, repository or service contract, existing Hyvä view model, or retained API only for a justified consumer |
| GraphQL mutation | Existing Magento form/controller/service flow with form keys and validation, or a justified API endpoint |
| ScandiPWA plugin/override | Layout XML, template override, view model, Magento DI plugin/observer, or compatibility module at the narrowest stable extension point |
| SCSS and generated class trees | Target design tokens, Tailwind utilities/components, and the theme's small CSS layer |
| Image component | Hyvä Media view model or established target image component with explicit dimensions and loading behavior |
| CMS-rendered React content | Existing Magento CMS rendering, an available Hyvä CMS component, or a small server-rendered content component |
| Browser persistence | Magento private content, cookie/config-backed state, or deliberate Alpine persistence with privacy and expiry considered |
| PWA-only behavior | Explicit product decision: reproduce with an appropriate web capability, replace, defer, or omit |

## Cross-cutting traps

- A visually simple component may hide pricing, tax, customer-group, inventory, or
  authorization behavior. Trace its data and Magento modules before rebuilding it.
- Removing a GraphQL call does not automatically make its backend module obsolete; check
  other consumers, schema extensions, indexers, and admin dependencies.
- Full-page cache and private content replace parts of client-state behavior. Verify guest
  to customer transitions, cart changes, logout, and section invalidation explicitly.
  Exercise stateful behavior as continuous journeys. For cart-related work, derive and
  verify relevant sequences such as guest add to cart, login with or without an existing
  customer cart, merge or reconciliation results, update and remove actions, private
  content refresh, and logout; do not assume Magento's expected result when the source
  behavior or approved contract differs.
- Hyvä Theme and Hyvä Checkout are separate integration surfaces. Do not assume a theme
  template migration covers checkout behavior or payment compatibility.
- Tailwind major versions and CSP theme choice materially affect implementation patterns.
  Inspect the installed project instead of applying examples from another version.
- Preserve source quirks only when they are approved behavior. Record intentional target
  improvements so parity testing does not misclassify them as regressions.
