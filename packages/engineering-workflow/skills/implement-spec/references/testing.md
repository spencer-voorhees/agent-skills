# Testing During Implementation

Use testing to prove changed behavior and prevent plausible regressions. Match effort to
risk; do not produce tests mechanically for every edited line.

## Discover before adding

Inspect the repository's test commands, framework configuration, nearby tests, fixtures,
factories, helpers, and CI. Follow established placement and naming. Do not introduce a
second test framework for convenience.

## Choose the test level

- **Unit**: isolated rules, transformations, parsing, and edge cases.
- **Component**: rendered UI behavior, states, accessibility semantics, and interactions.
- **Integration**: databases, files, network adapters, queues, framework boundaries, and
  other contracts whose real behavior matters.
- **End-to-end**: a small set of critical workflows that require the assembled system.

Prefer the lowest-cost level that exercises the actual risk. A mocked test is not useful
when the bug is likely to live in serialization, persistence, routing, or another mocked
boundary.

## Select cases

Map tests to acceptance criteria and changed behavior. Consider:

- Expected behavior
- Boundary and empty inputs
- Invalid input and dependency failure
- Permissions and authorization
- Retry, idempotency, concurrency, or ordering when relevant
- Loading, empty, error, disabled, and success UI states
- Compatibility with existing consumers

Avoid assertions on private implementation details. Keep snapshots small and meaningful.
Reuse stable fixtures and control time, randomness, and external dependencies when they
would otherwise make results nondeterministic.

## Run checks

Run the narrowest relevant test while iterating. Before completion, run the broader
checks justified by the change, such as:

- Related unit, component, or integration suites
- Type checking
- Linting
- Production build
- Migration validation
- Storybook or visual checks
- End-to-end or smoke tests for critical paths

State exactly which commands ran and their outcome. If environment limitations prevent a
check, report the missing evidence rather than substituting confidence language.
