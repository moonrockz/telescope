# Tasks

## 1. Add generic viewport controls

Bead: telescope-e8e.1

- [x] 1.1 Add card/detail markup and scoped shared runtime/CSS; verify zoom limits, Fit, pan, keyboard, native/fallback fullscreen, custom skins, themes, resize and multiple instances in browser tests.
- [x] 1.2 Preserve static/source/SVG behavior and document public hooks; verify no-script, print, narrow layout, filters and byte preservation with existing gallery suites.
- [x] 1.3 Package the changed library/CLI and qualify a fresh independent consumer without workspace overrides using mise run test:consumer -- --prepared.

## 2. Add brand assets and local raster adapter

Bead: telescope-e8e.2

Depends on group 1.

- [x] 2.1 Add validated optional header logo/favicon paths and tree-relative shell output; verify absent and invalid settings and root/next resource URLs with model, host and browser tests, and document configuration.
- [x] 2.2 Add supported local adapter asset integration and PNG/JPEG controls with options and feedback; verify a real consumer fixture, complete canonical input, download bytes, failure recovery and unchanged SVG/source actions.
- [x] 2.3 Run format, check:setup, check, test:browser, package, prepared consumer and strict OpenSpec validation; record release-ready evidence without publication.

## Workflow follow-up

- Archive in the last implementation PR. Close local beads after merge with PR and merge SHA and sync the configured backend.
- Obtain separate owner release approval before opening a release PR or publishing. Confirm a matching published library and CLI before downstream adoption.
