# Test Review

Assess whether the change has credible regression evidence. Do not require tests merely
to increase test count, and do not equate line coverage with behavioral coverage.

## Review questions

1. What observable behavior changed?
2. Which test demonstrates each important behavior or acceptance criterion?
3. Does the test exercise the production path, or do mocks bypass the risky boundary?
4. Are meaningful failure, boundary, permission, and concurrency cases covered?
5. Would the test fail if the relevant implementation were removed or broken?
6. Does it assert public behavior rather than incidental implementation details?
7. Does it reuse established fixtures, factories, and test utilities?
8. Are snapshots focused and reviewable rather than broad approvals of noisy output?
9. Were the relevant commands actually run, and are their results reported accurately?

## Findings threshold

Raise a finding when a plausible regression would escape the current suite or when a
test gives false confidence. State the concrete behavior that can break, why existing
coverage misses it, and the smallest useful test that would detect it.

Do not demand a test for a purely mechanical change when existing checks already prove
the invariant. Do not claim a test passes unless it was executed in the current review
or supported by explicit, current CI evidence.
