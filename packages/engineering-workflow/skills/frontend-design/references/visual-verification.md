# Visual verification

Use this reference whenever code changes rendered UI. Source review and passing tests do
not establish visual quality.

## Prepare

1. Run the application through its documented development or preview command.
2. Confirm the relevant route loads without console or runtime errors.
3. Populate representative content and exercise important interface states. Use safe
   local fixtures or mocks rather than changing production data.

## Inspect

Capture or inspect the rendered interface at representative phone, desktop, and wide
desktop sizes; include tablet when the composition changes meaningfully there. Review:

- Whether the design read and signature are visible rather than diluted by generic
  patterns.
- Visual hierarchy, reading order, typography, spacing rhythm, alignment, and optical
  balance.
- Palette, shape, icon, image, and component consistency with the selected system.
- Overflow, clipping, unexpected wrapping, excessive empty space, and layout shift.
- Hover, focus, pressed, disabled, loading, empty, error, and success states as relevant.
- Keyboard focus visibility and reduced-motion behavior.
- Theme variants only when the product supports them; neither light nor dark mode is an
  automatic requirement.

## Refine

Make at least one focused critique pass after seeing the render. Fix observed problems
rather than adding decoration by instinct. Reinspect affected viewports and states, then
report what was visually checked and any conditions that could not be exercised.
