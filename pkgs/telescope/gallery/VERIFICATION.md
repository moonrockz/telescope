# Group 5 verification

Verified locally on macOS arm64 on 2026-10-26. Compiler reports
`v0.10.17+093cb8f9c`. Commands used the installed pinned toolchain directly with
matching `MOON_HOME`, avoiding an unrelated compiler earlier on the shell PATH.

Owned implementation is limited to `gallery/` and `extensions/`, including their
compiled examples, package manifests, generated public interfaces and docs. No
consumer repository files, task checkboxes, tracker state, commits or publication
were changed by this worker. Fixture code and supplied sample art are original
Apache-2.0 Telescope material.

## Portable packages

From `pkgs/telescope`, with the pinned `moon` executable:

```sh
moon fmt gallery extensions gallery/examples extensions/examples
moon check gallery extensions gallery/examples extensions/examples --target all --deny-warn
moon test -p moonrockz/telescope/gallery -p moonrockz/telescope/extensions \
  -p moonrockz/telescope/gallery/examples -p moonrockz/telescope/extensions/examples \
  --target all --deny-warn
```

Result: formatting and checks pass. All 17 tests pass on each of wasm, wasm-gc,
JS and native, totaling 68 successful test executions. Packages depend on pure
model/core only. Extensions do not import gallery, native IO, Rabbita host
rendering, CommonMark or consumer domain engines.

Gallery cases cover implemented/planned records, base paths `/` and `/example/`,
escaped metadata, declared companion layout, all seven family labels as data,
shared-file deduplication, missing sources and SVG references, schema mismatch,
unsupported status, duplicate IDs/routes, reserved and malformed IDs, absolute,
traversing, encoded and non-normalized paths, planned entries with artifacts,
preview/player media mismatch, parent/child output collisions, conflicting shared
media types, malformed JSON/record shapes, invalid bases, and optional producer
absence with malformed-present rejection.

Extension cases cover registered fence execution, escaped unknown source and
language attributes including repeated quotes, duplicate IDs/versions/labels/
routes before callbacks execute, exact page dispatch, route-local island
selection and static fallback, duplicate mount IDs, invalid assets/media types,
callback errors with provider/source/stage, and invalid output assets/headings.
The two example tests execute the consumer-owned typed producer and note adapter.

## Real consumer manifest integration

Read the coordinator-prepared diagrams manifest at
`/Users/damian/code/github/moonrockz/diagrams.mbt/site/gallery.json` and its declared
files without modifying that repository. Copied them into a fresh temporary
project, supplied generic branding and gallery config, then ran the native CLI
`build` and `check --format json` at both `/` and `/example/`.

Both builds succeed and both checks return `[]`. The manifest has 10 implemented
entries spanning sequence, BPMN, swimlane, regex, EBNF, JSON and YAML. Output
contains `/gallery/` and 10 standalone detail documents with source downloads,
supplied previews, explicit status and optional player links. Direct byte
comparison confirms all 32 declared artifact files equal their supplied inputs.
No artifact digests or freshness records were calculated or persisted.

Temporary evidence root for this session:
`/var/folders/gk/kq2l8mzd0lq64qspbc_6j80m0000gn/T/telescope-gallery-real-bbj7szru`.
It contains the input snapshot and `out/` plus `out-root/` builds. This is local
integration evidence, not a published-consumer qualification or downstream pin.

## Shared integration and limits

The library owner integrated providers into `site.prepare/build`, including
shared Rabbita document rendering and route-local island assets. The host owner
integrated gallery pages/copies, required regular-file and realpath checks,
output collision handling and offline resource declarations. The host owner
reports expanded HTML/SVG/CSS reference checking, aggregate artifact errors and
planned-only handling without an artifact directory; its filesystem regression
suite owns the final evidence for those changes. This worker does not claim those
new host regressions passed without the host worker's report.

The latest strict OpenSpec validation passes 1/1. Required `mise run format` ran
successfully. The subsequent `mise run check:setup` encountered formatting in a
concurrently added `scripts/publish.mbtx`; the coordinator was notified and owns
its final rerun. No browser accessibility audit, Linux execution, full engine
qualification, packaged-consumer release qualification or publication is claimed.
The coordinator owns tracker/task completion and final integration verification.
