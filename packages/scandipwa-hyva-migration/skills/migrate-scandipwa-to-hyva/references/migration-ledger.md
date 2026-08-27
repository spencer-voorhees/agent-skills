# Migration ledger

Use the project's existing scope map as the durable source when one exists. Do not force
it into this exact representation. Maintain these fields in the map, a linked artifact,
or a temporary working view so decisions and completion remain auditable.

For a focused invocation, read and update only the matching row and directly linked
dependencies. If no matching row exists, use the focused user request as the local
contract and report the missing map entry; do not normalize unrelated migration scope.

## Minimum fields

| Field | Purpose |
|---|---|
| ID | Stable identifier used in plans, changes, tests, and handoffs |
| Capability or journey | Customer-visible behavior, integration, or cross-cutting concern |
| Source evidence | Routes, components, plugins, GraphQL operations, modules, configuration, and captures that prove current behavior |
| Disposition | `rebuild`, `adapt`, or `omit`, preserving the approved scope decision |
| Decision provenance | Approved map/version or explicit owner decision supporting disposition changes, omissions, and deferrals |
| Acceptance criteria | Observable target behavior, including important states and variants |
| Dependencies | Shared target foundations, Magento modules, third parties, content, data, and other ledger IDs |
| Target pattern | Native feature, compatibility module, Hyvä UI, theme template/view model, Alpine, customer section, custom module, CMS component, or another explicit choice |
| Slice | Coherent implementation batch that will deliver and verify the item |
| Risk | Customer, revenue, data, security, SEO, accessibility, performance, or operational risk |
| Status | Current workflow state |
| Evidence | Target files, tests, command results, screenshots, URLs, and review notes |

Useful optional fields include owner, estimate, store-view coverage, test fixtures,
analytics events, content migration, delivery dependency, reversal note, and decision
date.

## Status model

Use the repository's existing statuses when available. Otherwise use only the states the
team needs from this compact model:

| Status | Exit condition |
|---|---|
| `scoped` | Disposition and capability are known |
| `traced` | Source behavior and dependencies have evidence |
| `ready` | Acceptance criteria and target approach are sufficient to implement |
| `implementing` | Target work has started |
| `blocked` | A named dependency or decision prevents progress |
| `verified` | Target acceptance criteria pass with named evidence; this alone does not imply source parity, deployment, or production readiness |
| `omitted` | Omission is approved and rationale is recorded |
| `deferred` | Deferral, owner or trigger, and impact are recorded |

Do not mark an item verified merely because its files were ported or the application
builds. Do not use `omitted` to hide a failed or unresolved implementation.
An in-scope deferred item prevents reporting all migration work as implemented and
verified unless an authorized decision removes it from scope or changes its disposition.

## Normalizing an existing map

Preserve the original IDs, labels, dispositions, and ownership. Add missing fields in a
compatible way, or keep a temporary overlay keyed by original ID when the map must not be
edited. If one map row contains multiple independently releasable behaviors, create
linked child items without changing the parent's approved scope.

When source tracing reveals an unscoped dependency:

1. link it to the affected item;
2. classify it as an implementation dependency, a new product capability, or dead source
   code;
3. proceed when it is an in-scope technical necessity that does not change behavior;
4. request a decision when it changes product scope, cost, data handling, or a public
   contract.

Record obsolete ScandiPWA code, dependencies, configuration, and integrations as removal
candidates for the team responsible for source retirement. Do not overload target
implementation status or remove those items as part of this skill.
