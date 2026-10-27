# Extract project site toolkit

## Why

Smithy, Morphir and diagrams.mbt each carry MoonBit project site machinery that
mixes reusable documentation behavior with project content and domain tools.
Telescope should release that common machinery before diagrams.mbt adopts it,
so the next consumer can install a tested package instead of copying another site.

## What Changes

- Publish a reusable `moonrockz/telescope` library and matching `telescope` CLI.
  Separate pure configuration, routes and content analysis from Rabbita rendering,
  filesystem/process IO and optional adapters.
- Provide static landing pages, Markdown and HTML documents, docs navigation,
  heading links, search, themes, articles and feeds, plus build/check/serve tools.
  Development templates are excluded from content discovery by default.
- Provide optional, generic `moon doc` ingestion and version-tree adapters in the
  first usable release. Preserve diagrams' API anchors, signature/source links,
  doc prose, package ordering and per-tree search, together with root, `next/`,
  `v/<minor>/` and `latest/` behavior. Consumers retain release selection and deploy.
- Define typed extension adapters and a versioned gallery artifact manifest.
  The manifest identifies family, support status, sources, SVG preview and optional
  offline player. Telescope validates and presents supplied files; consumers own
  diagram rendering, code-fence providers and workbench engines.
- Prove the architecture first in an independent fresh consumer outside the
  checkout, using a packaged candidate without sibling paths. Qualify published
  library and CLI installation again after the explicit owner publication gate.
- Preserve Apache attribution and source provenance. Keep the initial extraction
  small; Smithy and Morphir remain reference projects rather than migration targets.

## Capabilities

### New Capabilities

- `site-content`: Configuration, base paths, source discovery, HTML/Markdown,
  stable routes, navigation and document facts.
- `site-presentation`: Static page shells, accessible navigation, search, theme,
  articles and optional browser islands.
- `site-tooling`: Reproducible build/check/serve, diagnostics and packaged
  library/CLI consumption.
- `site-extensions`: Explicit extension adapters and gallery artifact validation
  without a dependency on consumer domain engines.
- `site-api-versions`: Optional MoonBit API ingestion and isolated version trees
  compatible with the existing diagrams site.

### Modified Capabilities

None. This repository has no accepted specifications yet.

## Beads

- **Tracked by**: `telescope-0wg`. Implementation approved with gallery digests removed; one story per numbered task group.
- **Related**: diagrams.mbt `adopt-telescope-site` depends on this release.
  Cross-workspace coordination uses Run `run_b3638d9bfa3d` and mailbox
  `run:run_b3638d9bfa3d`. Implementation is tracked in epic `telescope-0wg`.

## Impact

The intended module has pure `model` and `content` packages, Rabbita `shell`,
host `build`, `check` and `serve` packages, browser `islands`, and optional
`adapters/moon-doc`, `adapters/versions` and `gallery` packages. The native CLI
initially supports Linux x64 and macOS arm64; other platforms need qualification.
The design records exact source files and inspected git revisions.

First release excludes dynamic plugin loading, a general theme marketplace,
deployment hosting, bundled diagram parsers/renderers, domain workbenches and
wholesale Smithy/Morphir migrations. No engine implementation, release,
publication, commit or push is part of this setup and proposal turn. A future
consumer must pin actual published library and CLI versions; no placeholder,
local path or sibling workspace module is a valid adoption dependency.
