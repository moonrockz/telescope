# Diagrams source-level compatibility proof

This is an explicitly prerelease source compatibility test for task 6.5. It
does not prove registry installation or publication and does not authorize
diagrams.mbt adoption. The separately qualified packaged consumer and the
later real published install remain required.

From the Telescope root, with the pinned mise tools installed:

```sh
MOON_HOME="$(mise where http:moonbit)" PATH="$(mise where http:moonbit)/bin:$PATH" \
  moonx scripts/test-diagrams-consumer.mbtx \
  --repo-root /Users/damian/code/github/moonrockz/diagrams.mbt
```

The supplied checkout must contain the actual source engine revision e0a5410,
preparation revision 31302b0, its reviewed 77-page baseline, current gallery
artifacts, and prebuilt `_build/site-api` metadata. The runner reads that
checkout without building in it, changing its dependency, or adopting a
candidate. It copies Telescope, actual diagrams modules, docs, package READMEs,
assets and metadata into a temporary workspace outside both source roots.
`api_generate` is false, and explicit source roots cover docs, pages, package
READMEs and site assets.

An explicit `static` mapping copies `apps/site/assets/examples` to
`assets/examples`, preserving legacy guide/player URLs alongside the gallery's
`gallery/artifacts` URLs. Telescope supplies the shell CSS. The retained
`regressions/static-assets` fixture records the missing-copy failure found by
this compatibility run.

The native consumer calls public `host.build` with two compile-time registered
fence providers. The callbacks use the real Mermaid and PlantUML renderers,
retaining `figure.diagram` and the legacy per-provider SVG ID prefixes. Both
`plantuml` and `puml` share one occurrence counter. Domain dependencies belong
to this consumer only.

Every public route and every anchor in the baseline must survive. Additional
anchors are compatible. This includes SVG IDs, raw HTML IDs and API anchors.
The old inventory accidentally captured nine `id='...'` strings inside escaped
XML code as anchors. Original `_site` pages are copied as independent evidence;
tag-aware inspection proves those strings were never DOM IDs. The driver checks
all nine remain in code in both original and new output. It accepts the corrected
inventory and records 5,376 genuine baseline DOM anchors across the 77 routes.
The test checks the 12 current gallery IDs, families and implemented statuses,
and compares copied artifacts by bytes without hashes. Public host checks
validate all internal page, fragment and resource links before and after
offline version assembly. One checked source tree supplies synthetic next and
0.2 trees, so root, next, v/0.2 and latest all undergo the same baseline and
artifact checks. The synthetic version label is test data, not a release claim.

Successful runs retain `report.json` here with exact source refs, counts and
qualification limits. Temporary sources and output trees are removed. See
[NOTICE](NOTICE) for attribution.

Pass `--keep-temp` to retain the external workspace when investigating a
failure. Its path is printed before building.
