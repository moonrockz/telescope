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

## Gallery viewport and export hooks

Gallery cards and example previews use a `.diagram-viewer` root marked with
`data-diagram-viewer`. Their stable parts are `.diagram-viewer__viewport`,
`.diagram-viewer__content`, `.diagram-viewer__toolbar`, `.diagram-viewer__export`
and `.diagram-viewer__status`. The toolbar appears only when scripts run. Card
titles remain ordinary detail links. Fit resets pan and fitted scale to 100%;
zoom ranges from 25% to 800%. Drag an enlarged image or focus its viewport and
use arrow keys to pan. Fullscreen uses the browser API when available and a
focus-contained page overlay otherwise. Escape restores focus and page scroll.
Print shows complete untransformed images.

Set `data-viewer-theme="light"`, `"dark"` or `"system"` on an instance. Without
an explicit policy, the viewer uses the stored site theme, then system settings.
Blocked storage falls back to system settings. Diagram preview colors remain
those of the supplied SVG.

Override these inherited CSS custom properties on one viewer or a parent:

- `--diagram-viewer-bg`, `--diagram-viewer-surface`, `--diagram-viewer-ink`,
  `--diagram-viewer-muted`, `--diagram-viewer-border`, `--diagram-viewer-accent`,
  `--diagram-viewer-accent-ink` select palette colors. Defaults follow the site's
  Smithy light/dark palette.
- `--diagram-viewer-canvas-bg`, `--diagram-viewer-toolbar-bg` and
  `--diagram-viewer-focus` default to the surface and accent.
- `--diagram-viewer-font` defaults to system sans-serif;
  `--diagram-viewer-font-size` to `15px`; `--diagram-viewer-space` to `.75rem`;
  `--diagram-viewer-control-radius` to `.5rem`; and
  `--diagram-viewer-panel-radius` to `.75rem`.

```css
/* Only this viewer changes, including in fullscreen. */
[data-diagram-viewer].my-skin {
  --diagram-viewer-accent: #b4235a;
  --diagram-viewer-surface: #fff7fb;
  --diagram-viewer-font: Georgia, serif;
  --diagram-viewer-space: 1rem;
  --diagram-viewer-control-radius: .25rem;
}
```

### Local raster adapter

Set `gallery_raster_adapter` to a normalized local output path, and use a static
mapping to supply that script and any local assets it loads. Only gallery pages
load the configured adapter. The script registers this asynchronous contract:

```js
window.DiagramsRaster = {
  async export({ svg, format, options, signal, onProgress }) {
    // Call the consumer's supported raster library with canonical SVG.
    // format is 'png' or 'jpeg'; options has theme, background, quality,
    // and optional width. null background requests transparent PNG.
    // signal permits cancellation; onProgress accepts a 0..1 fraction.
    return { bytes: new Uint8Array(/* encoded bytes */),
      mediaType: 'image/png', width: 640, height: 480 };
  }
};
```

Telescope supplies PNG/JPEG format, source or chosen pixel width, background,
PNG alpha and JPEG quality controls. It sends complete canonical SVG, independent
of zoom and pan, and reports busy, success, cancellation or failure in a live
status. Converter errors leave source and original SVG actions available.
Telescope does not render or modify consumer SVG. Use a consumer library that
supports its generated SVG, explicit fonts, themes and limits. Supply all adapter
assets locally for offline use.

The native host embeds an inert, escaped copy of each supplied SVG beside its
preview. Browser exports use those canonical bytes without a network request,
including after the page has loaded offline. Direct pure-planner integrations
can pass the optional `source_text` map with SVG paths and bytes for the same
behavior. If that map omits an SVG, the generic export control falls back to
reading the supplied preview URL.

### Index source inspection

Implemented index cards share the detail page's Preview/Source tabs. Tabs act
independently and preserve each mounted viewer's zoom and pan, including while
filters hide the card. Left/Right wrap through tabs; Home/End select the first
or last tab. Without scripts, preview and source sections remain readable.

Each declared file has its filename, media type and download. Eligible source
text appears exactly as supplied, with per-file copy feedback and a selectable
fallback when the clipboard is unavailable. Telescope never reconstructs original
syntax from SVG. Unsupported or unavailable inline text retains its download.

Customize `.gallery-workbench`, `.gallery-tabs`, `.gallery-tab`, `.gallery-panel`,
`.gallery-source` and `.gallery-source-file` for both card and detail layouts.
`--gallery-card-source-height` controls the card source scroll height, defaulting
to `20rem`. Long source lines scroll inside the panel in both themes.

With scripts, a labeled Source file selector chooses among multiple declared
files and retains its selection across tabs and filtering. Without scripts,
all files remain visible. `.gallery-source-select` styles the selector.
