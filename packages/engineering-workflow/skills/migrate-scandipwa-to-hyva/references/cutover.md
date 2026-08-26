# Program cutover and source retirement

Read this reference only when migration-program scope includes switching live traffic,
retiring ScandiPWA, or removing obsolete dependencies. Target implementation and parity
work do not imply authorization for these operational actions.

## Lifecycle claims

Use distinct claims so target delivery is not confused with operational completion:

| Claim | Evidence required |
|---|---|
| `target-ready` | Rebuild/adapt items and shared journeys are target-verified; omissions are approved; deferrals are removed from cutover scope or remain blockers |
| `ready-for-cutover` | `target-ready` passes; coexistence topology, current scope approval, cutover checklist, exact environment/release, rollback evidence and trigger, observation window, owners, and monitoring are verified |
| `cutover-executed` | An authorized traffic switch ran and initial post-switch checks passed; the rollback observation window remains active |
| `cutover-complete` | The observation window ended, monitoring and rollback triggers were evaluated, planned source traffic state was confirmed, and restoration remained viable |
| `cleanup-verified` | `cutover-complete` passes; approved retirement candidates reached their authorized final disposition and checks prove required consumers still work |
| `program-complete` | All preceding required claims pass; retained dependencies are proven non-obsolete or have an explicit approved scope exception and owner |

Do not infer operational facts. Unknown traffic, consumer, rollback, or environment state
blocks the affected lifecycle claim.

## Approval gate

Stop immediately before changing live traffic, disabling the source, deploying a cutover
release, or starting retirement cleanup unless that action is explicitly authorized.
Record the approval evidence, approver, exact environment, release or revision, scope,
time or window, rollback trigger, and responsible operator. Earlier approval to build the
migration is not cutover approval.

## Cutover sequence

Adapt the mechanics to the repository and platform, while preserving this ordering:

1. Verify the approved scope/map version and that no unresolved in-scope item is hidden as
   omitted or deferred. Confirm the `target-ready` claim before proceeding.
2. Inventory source-only dependencies and all known consumers before switching traffic.
3. Verify the cutover checklist, representative commerce journeys, monitoring, rollback
   mechanism, rollback trigger, observation window, and owners. Provide a rollback
   rehearsal or other named evidence that restoring routing preserves compatible sessions,
   carts, orders and payments when applicable, cache/private content, configuration, and
   schema/data state. If rehearsal is impractical, record explicit owner acceptance of the
   untested residual risk.
4. Obtain the explicit operational approval, then switch only the authorized traffic.
5. Run environment-level checks for routing, authentication, sessions, cart, checkout,
   orders and payments when applicable, cache and private content, integrations, errors,
   and project-defined metrics. Confirm source traffic matches the planned state, then
   record `cutover-executed`.
6. Observe for the agreed window while keeping rollback viable. Roll back when its trigger
   is met; do not remove the source merely because the first smoke test passed. Record
   `cutover-complete` only after the window and its exit criteria pass.
7. After the rollback boundary, obtain any required cleanup approval and retire candidates
   in reversible batches where practical. Verify after each batch.

## Removal register

Track each candidate with a stable ID, owner, consumers and consumer-audit evidence,
disposition (`retain`, `disable`, or `remove`), rationale, dependency order, restoration or
rollback method, approval, status, and verification evidence.

Treat `disable` as an interim state unless explicitly approved as the permanent end state.
A `retain` disposition is complete only when evidence shows the item is not obsolete or an
authorized owner approves it as a scope exception. Do not relabel a known-obsolete item as
retained merely to close the register.

Inspect more than repository references. Include applicable:

- Composer and JavaScript packages, Magento modules, schemas, DI, cron, indexers, and APIs
- theme and extension code, build/deploy scripts, tests, generated configuration, and jobs
- environment configuration, secrets, proxies, routes, CDN/cache rules, and monitoring
- CMS content, assets, translations, admin configuration, and data migrations
- external consumers, integrations, licenses, operational runbooks, and support ownership

A repository search alone cannot prove that runtime or external consumers are gone.
Program completion requires zero unresolved required-removal candidates; approved retained
exceptions need a rationale, owner, and continuing verification plan.
