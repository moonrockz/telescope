# Default presentation

Telescope uses the indigo and cool neutral palette from Smithy's site. The
reference is `moonrockz/smithy` revision
`b97203cea93ed2b71affc1580817ecfd41a6b515`, `site/public/styles.css`.
See NOTICE for source attribution.

| Role | Light | Dark |
| --- | --- | --- |
| Page | `#f9fafb` | `#0f1014` |
| Surface | `#ffffff` | `#17181f` |
| Text | `#111827` | `#e5e7eb` |
| Secondary text | `#6b7280` | `#8b93a8` |
| Accent | `#4f46e5` | `#a5b4fc` |
| Selected background | `#eef2ff` | `#1e1b4b` |
| Decorative border | `#e5e7eb` | `#26283a` |

Essential control borders use a stronger neutral than decorative separators.
Focus rings use the accent. Browser qualification measures text, link, selected
state, control and focus contrast in each theme. Semantic warning, success and
error colors keep their distinct meanings.

Light, dark and system selection use the same token mapping. A saved explicit
choice is applied before styled paint. When preference storage is unavailable,
the system palette applies and the reading controls remain usable. No external
font or color service is required.

The theme styles site content and gallery frames. Gallery SVG and offline player
artifacts retain their supplied bytes and colors. Available light and dark SVG
variants follow the selected site theme. A single-theme preview keeps a compatible
surface. Historical site archives retain the styles they were released with.

The gallery uses a family rail and preview cards on wide screens. Family links
wrap above the cards on narrow screens. With scripts enabled, a local text filter
combines title, family and description with the chosen family, reports results
and provides a reset action. Without scripts, all grouped examples remain visible.

Each example has a large preview and source inspection panel. Keyboard users can
switch Preview and Source with the arrow, Home and End keys. Source copying gives
feedback and falls back to selectable text if clipboard access is denied. Both
sections and all downloads remain available without scripts. Offline players
open through separate links; browsing the gallery does not execute a renderer.
