# Proposal

## Why

Gallery index cards currently require a detail-page visit to inspect declared source. Readers need independent Preview/Source tabs alongside each preview, including the original syntax that produced it.

## What Changes

- Reuse shared exact-source panels on implemented index cards with unique IDs, filenames, copy/download actions and accessible keyboard tabs.
- Keep previews mounted and preserve viewer zoom/pan, filtering, detail links, fullscreen and raster actions.
- Retain readable static source sections without JavaScript, safe escaping, unavailable-source downloads and narrow-width scrolling.
- Prepare matching library and CLI 0.5.0 candidates, qualify fresh consumers and retain the explicit publication gate.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `site-presentation`: Independent index-card source inspection alongside existing detail inspection.

## Tracking

Implementation is approved by the upstream diagrams handoff and dispatched task task_59314f8ba887. Telescope owns its local epic and task-group stories; publication requires exact SHA/version owner approval. Stories remain open until their PR merges, and the release story stays open through published evidence and archive.

## Impact

`gallery/plan.mbt`, `islands/gallery.mbt`, shared CSS, gallery model/browser/consumer tests, documentation and release version files. No manifest schema or public function signature changes. No downstream repository edits or local-path adoption.
