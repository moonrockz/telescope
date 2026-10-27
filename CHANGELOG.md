# Changelog

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
