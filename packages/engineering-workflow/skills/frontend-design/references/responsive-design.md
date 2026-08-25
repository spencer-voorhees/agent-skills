# Responsive design

Use this reference for multi-column, data-dense, media-heavy, or unusually wide layouts.
Responsive design should preserve task priority and comprehension, not merely make every
desktop element narrower.

## Choose behavior from content

- Derive breakpoints from where the composition stops working, while preserving the
  repository's established breakpoint system when one exists.
- Constrain reading content by comfortable line length. Allow workspaces, comparisons,
  timelines, canvases, and dense data surfaces to use additional width when it helps the
  task.
- For each multi-column region, decide explicitly whether smaller screens should stack,
  reorder, collapse, scroll, summarize, or switch presentation. Do not default every
  grid to a carousel or every side panel to a bottom sheet.
- Preserve information hierarchy across layouts. Moving content visually must not create
  an incoherent DOM or keyboard order.

## Prevent fragile layouts

- Find and fix the element causing horizontal overflow. Do not use root-level clipping
  to conceal an unresolved layout defect.
- Let text wrap safely and give flex/grid children appropriate shrinking behavior.
- Keep media within its container and reserve dimensions when loading it to avoid layout
  shift.
- Use content-aware table strategies: preserve horizontal comparison when it matters;
  otherwise expose priorities through responsive columns, summaries, or detail views.
- Account for dynamic viewport behavior and safe areas when creating full-height mobile
  experiences.

## Verify representative conditions

Inspect at least a compact phone, a larger phone or tablet when relevant, an ordinary
desktop, and a wide desktop. Also check long labels, large values, empty content, browser
zoom, and both pointer and touch-oriented interactions where the product supports them.
