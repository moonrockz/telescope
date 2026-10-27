# Proposal

## Why

Telescope's warm gold palette differs from Smithy's indigo and cool gray palette. Its gallery lists examples as document sections, which makes visual comparison harder than in a component library gallery.

## What Changes

- Set the shared light and dark defaults from Smithy's reviewed color tokens. Keep Telescope's existing token names, theme persistence and system fallback.
- Render a responsive gallery of preview cards with family navigation, a local text filter, visible result counts and a clear empty state.
- Give each stable example page a large preview panel, Preview and Source controls, source copy and download actions, and a separate link to an available offline player.
- Keep static family anchors, all example content and downloads usable without JavaScript. Preserve artifact bytes and manifest version 1.
- Qualify an independent packaged consumer, then prepare an owner-approved release of the library and matching CLI before diagrams.mbt adopts it.

## Capabilities

### New Capabilities

None. Extend the existing presentation and extension contracts.

### Modified Capabilities

- `site-presentation`: Smithy-aligned default palette and accessible gallery browsing controls.
- `site-extensions`: preview cards and example inspection using consumer-supplied artifacts.

## Beads

- **Tracked by**: telescope-iqz.
- **Related**: diagrams.mbt change `align-site-theme-and-gallery` depends on the actual release from this change.

## Impact

Shared CSS, gallery host rendering, optional gallery browser behavior, browser and consumer qualification, and release documentation. No breaking manifest or public host API change is planned. Native library and CLI distributions must contain the same theme and gallery assets.

Smithy reference: `moonrockz/smithy` at `b97203cea93ed2b71affc1580817ecfd41a6b515`, `site/public/styles.css`. Its local file matches GitHub main. Keep Apache attribution if adapting source.

Out of scope: changes to Smithy, diagram renderer palettes, historical release archives, live source editing, renderer execution inside Telescope, arbitrary workbench plugins, telemetry, digest manifests, and a new theme configuration framework. Publication requires explicit owner approval of the release version and commit.
