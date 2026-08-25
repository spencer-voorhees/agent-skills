# Frontend accessibility

Use this reference when designing or implementing interactive, form-heavy, or dynamic
interfaces. Follow the repository's accessibility requirements and testing tools when
they are more specific.

## Structure and navigation

- Use semantic elements and meaningful landmarks before adding ARIA.
- Preserve a logical heading hierarchy, reading order, and keyboard focus order.
- Ensure every interactive element is reachable and operable by keyboard, with a visible
  focus indicator that remains clear against every surface.
- Provide a skip mechanism when repeated navigation precedes substantial page content.
- Do not make hover, color, position, animation, or gesture the only way to discover
  information or perform an action.

## Controls and forms

- Give icon-only controls an accessible name and keep decorative icons out of the
  accessibility tree.
- Associate every input with a persistent label. Connect descriptions and validation
  messages programmatically; do not use placeholder text as the label.
- Preserve familiar keyboard behavior for menus, dialogs, tabs, comboboxes, and other
  composite widgets. Prefer established accessible primitives over recreating them.
- Make targets comfortably operable across pointer and touch inputs, with sufficient
  spacing to avoid accidental activation.

## Content and perception

- Meet the project's contrast standard for text, controls, focus indicators, charts,
  and meaningful states. Check actual rendered combinations rather than token names.
- Provide useful alternative text for meaningful images and empty alternative text for
  purely decorative images.
- Ensure content remains usable under text resizing and browser zoom without clipping,
  overlap, or loss of controls.
- Provide text or symbolic reinforcement when color communicates status.

## Motion and dynamic updates

- Respect reduced-motion preferences. Remove nonessential movement and replace necessary
  transitions with low-motion alternatives that preserve understanding.
- Keep focus stable during async updates unless moving it is necessary to complete the
  interaction.
- Announce important errors, completion messages, and live updates appropriately without
  making routine changes excessively noisy for screen-reader users.

Verify with the project's automated accessibility checks when available, then perform
keyboard and visual focus checks because automation cannot validate the full experience.
