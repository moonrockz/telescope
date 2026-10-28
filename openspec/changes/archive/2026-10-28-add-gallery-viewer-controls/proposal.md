# Proposal

## Why

Large gallery previews need accessible inspection and export actions. Consumers also need supported header and favicon inputs instead of changing generated pages.

## What Changes

- Add shared, scoped gallery viewport controls with fullscreen fallback, zoom, pan and Fit.
- Keep card title navigation separate from preview actions.
- Add an optional local consumer raster adapter contract and accessible PNG/JPEG controls.
- Add deployment-relative header logo and favicon configuration.
- BREAKING: direct `SiteConfig` struct literals must supply three new default-empty asset fields. JSON configuration remains compatible.
- Preserve static previews, sources, SVG downloads and existing filtering.

## Capabilities

### New Capabilities

- `gallery-viewports`: Accessible inspection and consumer-supplied raster export of gallery previews.

### Modified Capabilities

- `site-presentation`: Header logo and favicon inputs.

## Tracking

Approved as the upstream implementation scope of diagrams.mbt change refresh-site-and-diagram-viewers. Publication remains a separate owner gate.

## Impact

Gallery planning, generic browser assets, shared shell configuration, packaged CLI assets, browser and independent consumer fixtures, and public presentation documentation. No consumer diagram engine is imported.
