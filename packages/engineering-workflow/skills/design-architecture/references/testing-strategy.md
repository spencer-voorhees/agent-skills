# Testing Strategy for Architecture

Use this reference when architecture decisions create meaningful test boundaries.
Keep the strategy proportional to risk and compatible with the repository's existing
test framework, fixtures, and CI.

## Define observable boundaries

For each important behavior, identify the cheapest test level that provides credible
evidence:

- **Unit** for isolated domain rules and transformations.
- **Component** for UI behavior in controlled states.
- **Integration** for boundaries such as databases, queues, files, or service adapters.
- **End-to-end** for a small number of critical user journeys crossing the system.

Prefer realistic integration tests where the correctness risk lives at an integration
boundary. Do not replace the boundary under test with a mock and then claim the
integration is verified.

## Record consequential choices

Document only choices implementation cannot safely infer:

- Which contracts or boundaries require integration coverage
- Which dependencies may be mocked and which require realistic substitutes
- Required fixtures, test data, clocks, randomness, or environment isolation
- Migration, compatibility, rollback, and failure-path verification
- Critical journeys requiring end-to-end or smoke coverage
- Commands or CI jobs that provide release evidence

Avoid target coverage percentages unless the project already uses them or a concrete
risk justifies one. Coverage is a diagnostic signal, not proof of behavior.
