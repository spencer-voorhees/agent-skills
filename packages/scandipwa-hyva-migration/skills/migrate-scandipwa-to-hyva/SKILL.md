---
name: migrate-scandipwa-to-hyva
description: Migrate and verify one component, capability, coherent slice, or an entire Magento storefront program from ScandiPWA to Hyvä. Use with an existing rebuild/adapt/omit scope map or a focused user request to trace ScandiPWA React/GraphQL behavior, select native Hyvä PHTML/Alpine/Tailwind patterns, route implementation through installed Hyvä AI skills, and prove target parity. Do not use for ordinary Hyvä work with no ScandiPWA migration context.
---

# Migrate ScandiPWA to Hyvä

Move approved storefront behavior to Hyvä without mechanically translating the
ScandiPWA implementation. Preserve the product contract, Magento integrations, and
explicit rebuild/adapt/omit decisions while adopting native Hyvä and Magento patterns.

Hyvä's official AI skills are the expected implementation specialists: discover the
installed set and use every relevant skill for the active target task. Retain ownership
of migration scope, source tracing, sequencing, parity, and completion here.

## Choose the operating scope

Use the narrowest mode that satisfies the request. Do not turn component-level work into
a storefront-wide migration exercise.

### Component or capability mode

Use this mode when the user names one component, capability, page region, or tightly
bounded customer behavior. Trace only the source files, Magento integrations, states,
and immediate dependencies needed to migrate that unit. Read the corresponding scope-map
item when one exists, but do not normalize, audit, or re-plan unrelated rows.

Define a local completion boundary: the component's observable states, its containing
page or integration point, and focused regression coverage. Finish by reporting that
unit's status; never imply that the wider migration is complete.

Tracing and testing an adjacent system does not make it editable. Treat shared producers,
authentication, cart reconciliation, backend services, and other neighboring behavior as
verification surfaces by default. Changes outside files directly owned by the active unit,
its necessary target integration, and focused tests require explicit scope expansion or a
handoff as a discovered dependency.

### Migration-program mode

Use this mode when the user asks to assess, plan, execute, or report across multiple map
items or the whole storefront. Normalize the scope map into a dependency-aware ledger,
sequence coherent slices, track cross-cutting foundations, and maintain program-level
completion evidence.

If a request names a specific component and does not explicitly ask for broader planning,
select component or capability mode.

## Establish the migration contract

Read repository instructions and inspect the working tree before editing. Locate the
ScandiPWA source, the Hyvä target, relevant Magento modules, and any scope-map entries for
the selected work. Do not assume they share a repository or that the target is empty.

Treat relevant entries in a scope map explicitly supplied by the user or unambiguously
identified as current by the repository as the controlling product decision. If multiple
maps exist or approval/currentness is unclear, resolve that before relying on a
disposition. Do not silently change an item from rebuild, adapt, or omit; flag
contradictions or newly discovered dependencies.

In migration-program mode, preserve the map's format and terminology unless the user asks
to replace it. Normalize it into a working ledger using
[`references/migration-ledger.md`](references/migration-ledger.md), filling missing
implementation and verification details from evidence. If no usable map exists, inventory
customer-visible journeys and custom behavior, propose a ledger, and resolve choices that
materially change scope before implementing them.

In component or capability mode, the user's focused request plus any matching map entry is
sufficient. Do not require creation of a program ledger before implementation.

Verify from repository, deployment, or runtime evidence and record the parts of the
baseline relevant to the selected scope:

- coexistence and cutover topology: how each storefront is activated, which traffic still
  reaches ScandiPWA, shared contracts, and the rollback boundary
- Magento, ScandiPWA, Hyvä Theme, Alpine, and Tailwind versions
- target child theme and parent, including CSP-compatible versus legacy theme
- Hyvä Checkout, Hyvä UI, Hyvä Commerce CMS, and compatibility-module availability
- store views, locales, currencies, customer groups, and relevant feature flags
- deployment and command wrappers already used by the repository

Do not infer live traffic activation, shared operational contracts, or rollback facts.
Record unknowns explicitly. They may allow target implementation to continue, but they
block an operational cutover until verified.

Unless the user confirms that ScandiPWA is retired and authorizes cutover work, treat
every running source storefront as an active consumer. During any target implementation
while ScandiPWA remains active, do not delete, disable, or incompatibly change ScandiPWA
code, shared GraphQL or service contracts, Magento modules, configuration, routing,
cookies or sessions, customer-data sections, cache behavior, or content. If the target
requires a shared contract change, keep it backward compatible and verify both
storefronts. Record removal candidates for an authorized cutover instead of removing them
opportunistically.

## Trace behavior, not just files

For each in-scope capability, trace the full source behavior across routes, React
components and plugins, GraphQL operations, client state, browser storage, Magento
modules, CMS/admin configuration, styling, assets, translations, analytics, SEO, and
third-party integrations. Read
[`references/source-to-target.md`](references/source-to-target.md) for the migration
heuristics and target pattern catalog.

Capture source evidence and observable acceptance criteria. Include relevant loading,
empty, error, authenticated, responsive, keyboard, and cache-sensitive states. Source
code is evidence of current behavior, not a target architecture template.

When the source storefront is runnable, capture a pre-change behavioral baseline on
representative fixtures and replay the same journeys against the target. If the source
cannot run, state that limitation, name the substitute evidence, and carry the remaining
parity risk into the handoff.

If no authoritative map, acceptance artifact, test, or approved design resolves material
behavior alternatives, present the ambiguity and obtain confirmation before choosing.
Unambiguous behavior derived from static source may be used as provisional criteria, but
label it as substitute evidence rather than approved source parity.

Before custom-building a capability, search in this order:

1. Magento or Hyvä already provides the behavior.
2. An installed extension or Hyvä compatibility module provides it.
3. An installed Hyvä UI component fits with bounded adaptation.
4. Existing target-theme components, view models, templates, and tokens can be reused.
5. A small custom implementation is required.

Classify any ScandiPWA-only API, module, package, configuration, content, infrastructure,
or integration that the target no longer needs as a retention or retirement candidate.
Do not remove it during ordinary component or target implementation work.

## Plan the active unit

In component or capability mode, define the component boundary and only the immediate
dependencies required to make it work in its target integration point. In
migration-program mode, build a dependency order from the ledger. Implement shared theme
foundations and cross-cutting integrations before dependent page features, but avoid a
large foundation rewrite disconnected from a verifiable journey.

Each active unit should deliver one coherent customer-visible behavior and include:

- map or ledger IDs when present, plus source evidence
- exact target behavior and explicit non-goals
- chosen Magento/Hyvä pattern and affected modules or theme areas
- dependencies, data and configuration requirements, and rollback boundary
- focused verification, including the source-versus-target comparison when available

High-risk journeys such as authentication, cart, checkout, payments, pricing, customer
data, and consent require explicit test coverage and must not be inferred from visual
similarity alone. When behavior crosses authentication, session, cart, private-content,
or persistence boundaries, verify the transition as a continuous journey; separately
testing the before and after states does not prove reconciliation or invalidation. Ask
before changing an approved scope decision or introducing a new paid product, external
service, or consequential data contract.

## Implement in the target architecture

Use layout XML, PHTML templates, blocks and view models, Magento service contracts,
customer-data sections, Alpine components, and Tailwind/theme CSS according to the
installed target's conventions. Prefer the target theme's established tokens and
components over copied ScandiPWA styles.

Do not port React component structure, Redux state, GraphQL client plumbing, CSS class
trees, or browser-storage behavior one-for-one. Recreate the observable behavior with
the smallest target-native implementation. Preserve URLs, analytics events, SEO
semantics, accessibility, and responsive behavior only to the extent required by the
contract.

Read [`references/hyva-ai-routing.md`](references/hyva-ai-routing.md), identify every
installed Hyvä AI skill relevant to the active unit, and use it for its bounded target
task. Read each selected skill fully before acting. Do not reproduce generic Hyvä
implementation guidance when an installed Hyvä skill owns it. Do not delegate migration
decisions or completion claims to a component skill.

If an expected Hyvä skill is unexpectedly unavailable, report which specialization is
missing. Inspect the installed Hyvä source and repository conventions and proceed only
when they provide sufficient evidence for a safe implementation; otherwise stop at the
affected task rather than inventing guidance.

Keep changes scoped to the active unit. Preserve unrelated work, and do not commit,
push, deploy, install paid packages, or mutate shared environments unless the user has
authorized that action.

## Scale with agents only when useful

Use one capable coding agent by default. Do not create custom Hyvä specialist agents that
duplicate the official Hyvä skills.

For a large migration with intentionally parallel execution, a coordinator may assign
dependency-ready, non-overlapping slices to implementation agents. The coordinator alone
owns ledger structure, shared target decisions, cross-slice dependencies, and final
completion status. An optional independent verification agent may perform read-only
source-versus-target journey checks. Do not parallelize tightly coupled checkout, cart,
customer-state, or shared-theme changes without explicit file and contract boundaries.

## Gate cutover and retirement

In migration-program mode, read
[`references/cutover.md`](references/cutover.md) only when the request includes a traffic
switch, source retirement, or obsolete-dependency cleanup. Authorization to plan or
implement the migration does not authorize an operational cutover or cleanup.

Keep target readiness, cutover readiness, cutover execution, rollback observation, and
retirement cleanup as distinct evidence-backed states. Do not claim program completion
while an in-scope deferred item remains a cutover blocker, the operational switch is
unapproved or unverified, or required cleanup has not been verified.

## Verify equivalence and target quality

Run the cheapest checks that credibly prove the active unit, followed by broader checks
proportional to its risk. Use repository-provided Magento, PHP, JavaScript, Tailwind, and
test commands. Never claim a check passed unless it ran successfully.

Verify applicable dimensions:

- acceptance criteria on the same representative products, categories, customers, and
  store views as the source
- guest and authenticated state, private content, cache transitions, and session changes
- loading, empty, validation, failure, and recovery behavior
- keyboard operation, focus, labels, announcements, contrast, and reduced motion
- mobile through wide layouts without copying source breakpoints blindly
- canonical URLs, metadata, structured data, redirects, and indexability
- analytics, consent, translations, currencies, taxes, prices, and configured extensions
- image dimensions and loading strategy, JavaScript errors, layout shift, and avoidable
  regressions to key storefront performance metrics

Use browser or Playwright checks for customer-visible flows when available. When the
source storefront is runnable, compare the target against the captured source baseline
using equivalent fixtures and continuous journeys. Otherwise use the recorded substitute
evidence and report the remaining parity risk. Do not treat pixel identity as required
unless the migration contract says so.

Update any matching map or ledger status only with evidence. A capability is verified
when its acceptance criteria pass in the Hyvä target; a successful build alone is
insufficient.

When acceptance criteria rely on substitute evidence because the source or authoritative
contract is unavailable, report `target-verified against substitute evidence`, not
`source-parity verified`. Treat the unit as fully accepted only when an authorized owner
confirms the criteria or accepts the recorded residual parity risk.

## Finish or hand off

In component or capability mode, the unit is complete only when its acceptance criteria
and containing integration point pass with evidence and any matching map entry is updated
or handed off. If only provisional criteria were available, report the narrower status
until an authorized owner accepts them or the residual risk. Do not make program-level
completion claims.

In migration-program mode, call the target `target-ready` when every rebuild/adapt item is
verified, every omission is approved, shared journeys pass, and deferrals are either
explicitly removed from the cutover scope or remain named blockers. If operational
cutover is not requested, finish at that status. Claim `program-complete` only when any
in-scope cutover and retirement work also satisfies
[`references/cutover.md`](references/cutover.md).

At each handoff, report the applicable subset of:

- component, capability, slice, and map or ledger items completed
- target behavior delivered and important implementation decisions
- verification commands and journey evidence
- blocked, deferred, omitted, or newly discovered items with owners or required decisions
- remaining ScandiPWA-specific dependencies and why they remain
- the next dependency-ready unit when broader work remains
