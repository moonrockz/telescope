# Changelog

## 0.5.1, 2026-10-29

- Fix native Windows drive and UNC canonical paths, containment and sibling staging.
- Qualify native host builds, output checks, assembly and loopback preview on Windows.
- Require Windows host qualification before publication alongside Linux/macOS distribution checks.
- Install fresh macOS tools after restored yamllint environments could not execute.

Owner-approved Actions publication and clean Linux/macOS public consumers passed.
See [release evidence](docs/release/0.5.1.md).

## 0.5.0, candidate

- Add independent accessible Preview/Source tabs to implemented gallery index cards.
- Reuse exact declared source panels with multiple filenames, copy/download actions, safe escaping and no-script reading.
- Preserve mounted preview zoom/pan across tab changes, filtering and hidden viewport resize.
- Expose shared gallery styling hooks and a configurable card source scroll height.

Library and CLI candidates are prepared together. Publication requires owner
approval of the exact release SHA and version; see [candidate notes](docs/release/0.5.0.md).

## 0.4.0, 2026-10-28

- Add scoped fullscreen, bounded zoom, Fit and pointer/keyboard pan to gallery cards and detail previews.
- Provide native fullscreen and an accessible modal fallback with focus and scroll restoration.
- Document per-instance viewer themes, stable part classes and CSS custom properties.
- Add an optional local PNG/JPEG consumer adapter with sizing, background, quality, cancellation and accessible feedback. Canonical SVG stays independent of viewport state and can export offline.
- Add optional tree-relative header logo and favicon configuration.
- Fix explicit light viewer colors, applied site theme changes when storage writes fail, and modal scroll restoration near the page bottom.
- Breaking API change: direct SiteConfig literals must set header_logo, favicon and gallery_raster_adapter. Use empty strings for existing behavior; JSON configurations may omit the new keys.

Owner-approved Actions publication and fresh public installs passed on Linux x64 and macOS arm64. See [release evidence](docs/release/0.4.0.md).

## 0.2.1, 2026-10-27

- Align gallery Reset filters controls with the filter textbox and use the shared indigo fill and contrasting text in both themes.
- Keep responsive wrapping and empty-state reset controls consistent.

Linux x64 and macOS arm64 real public installation passed. See
[release evidence](docs/release/0.2.1.md).

## 0.2.0, 2026-10-27

- Align the shared light and dark defaults with Smithy's indigo and cool neutral palette.
- Present gallery examples as responsive preview cards with local family and text filtering.
- Add accessible Preview and Source inspection, source copying and explicit downloads.
- Preserve manifest version 1, stable routes, artifact bytes and static content without JavaScript.
- Add an optional source-text input to the pure gallery planner; the native host supplies verified text.
- Preserve download-only source files during checks while retaining validation of active resources.
- Replace the local CLI atomically so rebuilding does not invalidate a running macOS preview.

Linux x64 and macOS arm64 clean public installation passed. See
[release evidence](docs/release/0.2.0.md).

## 0.1.1, 2026-10-27

- Show the enabled gallery in shared navigation, with the correct current link.
- Group gallery examples by family, link details back to their family and offer
  explicit downloads for light and dark SVG previews.
- Restore latest-tree canonical links during supplied-tree assembly when the
  corresponding released page exists, preserving authored canonical links.
- Retain actual 0.1.0 publication and clean published-install evidence.

## 0.1.0, 2026-10-27

- Extract generic configuration, content facts, Rabbita views, navigation,
  articles, feeds and browser islands from the attributed reference sites.
- Add the native build/check/serve/assemble CLI, staged output promotion,
  contained file handling and human/JSON diagnostics.
- Add explicit extension registration, supplied gallery artifacts, optional
  MoonBit API metadata and offline version-tree assembly.
- Package one library and matching relocatable CLI archives, with isolated
  candidate-consumer qualification and an owner-gated Actions release workflow.

Linux x64 and macOS arm64 clean published installation passed.
No consumer domain engines are distributed. Reviewed repository HTML is trusted
input; this release is not an untrusted-upload service.
