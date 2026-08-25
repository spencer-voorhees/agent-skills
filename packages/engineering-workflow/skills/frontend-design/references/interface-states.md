# Interface states

Use this reference for asynchronous, data-dependent, permission-sensitive, or otherwise
stateful surfaces. Inventory only states the interface can actually enter.

## State matrix

For each dynamic region, consider:

- Initial or first-run
- Loading and refreshing
- Populated and partially populated
- Empty because no data exists
- Empty because filters exclude results
- Validation and recoverable errors
- Permission, authentication, or unavailable states
- Saving, optimistic, success, and rollback behavior
- Disabled or read-only behavior

## Design principles

- Loading placeholders should preserve the final composition when its shape is known.
  Avoid false precision or skeleton layouts that bear no resemblance to the result.
- Distinguish first-run guidance from filtered-empty results. Each should explain the
  condition and offer the most useful next action.
- Keep errors close to their cause, state what happened in plain language, preserve the
  user's input, and provide recovery when possible.
- During async actions, prevent accidental duplicate submission while keeping the
  control's purpose and dimensions recognizable.
- Do not replace existing content with a blank loader during background refresh when
  stale content can remain safely visible.
- Avoid celebratory or intrusive success feedback for routine actions. Confirmation
  should match the consequence and uncertainty of the operation.
- Use consistent terms across controls, progress feedback, errors, and completion. An
  action named “Publish” should not become “Submit” or “Deploy” later in the flow.

Exercise these states with realistic data, including long text, missing optional fields,
large numbers, and partial failures. Do not fabricate claims or production status to make
a mockup appear complete.
