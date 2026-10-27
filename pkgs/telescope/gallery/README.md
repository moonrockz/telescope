# Gallery contract version 1

Since 0.1.1, the gallery groups examples by family and adds explicit SVG downloads.
Its shared host links the enabled gallery from primary navigation. These fixes
are not present in the published 0.1.0 package.

`moonrockz/telescope/gallery` parses and plans supplied artifacts without IO or
diagram engines. The consumer owns generation, source correctness and its checked
pipeline. All records use `schema_version: 1`. Optional informational `producer`
metadata contains `project`, `ref` and `pipeline`. These are provenance strings,
not freshness proofs. Absence is valid; supplied producer fields must be nonempty.

```json
{
  "schema_version": 1,
  "producer": {"project": "Example", "ref": "checked-source-ref", "pipeline": "gallery"},
  "root": "site/artifacts",
  "entries": [{
    "id": "review-sequence",
    "family": "sequence",
    "title": "Review sequence",
    "status": "implemented",
    "description": "A consumer-generated example.",
    "scope": "A static illustration; no process execution.",
    "sources": [{"path": "review.mmd", "media_type": "text/plain"}],
    "preview": {"path": "review.svg", "media_type": "image/svg+xml"},
    "player": {"path": "player/index.html", "media_type": "text/html"},
    "companions": [{"path": "player/player.css", "media_type": "text/css"}]
  }]
}
```

An implemented entry requires nonempty `sources` and an SVG `preview`. Optional
`preview_dark` is another SVG file record. Light and dark previews appear on
explicit light and dark surfaces, with captions and alternative text. Reading,
source downloads and the offline player link work without JavaScript. `description`
and `scope` are optional strings. `family` is a label supplied by the consumer.
Sequence, BPMN, swimlane, regex, EBNF, JSON and YAML receive no special treatment.

A planned entry has `id`, `family`, `title`, `status: "planned"` and optional
description/scope. Omit all artifacts. Planned general PlantUML, DOT and Draw.io
entries receive descriptive detail pages with no preview, downloads or player.

IDs use lowercase ASCII letters, digits and internal hyphens. `artifacts` is
reserved. Paths use slash-separated nonempty segments containing ASCII letters,
digits, `.`, `-`, `_` or `~`. A segment cannot be `.` or `..`. Absolute paths,
backslashes, encoded paths, spaces, query strings and fragments are rejected.
Producers should choose portable filenames; the parser never silently rewrites
paths. Shared identical paths and media types copy once. Conflicting media types
and parent-file/child-path collisions fail.

```moonbit
let manifest = @gallery.parse_manifest(text, source="site/gallery.json").unwrap()
let plan = @gallery.plan(manifest, "/example/").unwrap()
// plan.pages: GalleryPage { route, title, body_html }
// plan.copies: ArtifactCopy { source_path, output_path, media_type }
```

Both functions return `Result[..., Array[@model.Problem]]`. `validate` also checks
manually constructed public records. Routes are `/gallery/` and `/gallery/<id>/`;
the configured base prefixes all generated links. Bodies are escaped shell inputs.
The host renders them through the shared Rabbita views to create complete HTML.
It copies bytes to `gallery/artifacts/<source_path>`, retaining directory
relationships for players and companion resources.

CLI configuration uses `gallery: {"manifest": "site/gallery.json", "root":
"site/artifacts"}`. The host resolves these relative to its declared project root.
Manifest `root` is a fallback when config omits `root`; it is also a normalized
relative path. It does not authorize arbitrary filesystem access.

Before staging, the host must check every required file is regular, resolve
symlinks under the artifact root, reject escapes, and aggregate collisions with
all other output pages/assets. It must check local references in supplied SVG,
HTML and CSS against declared sources, previews, players and companions. Missing
or undeclared companion resources fail. Pure validation cannot prove filesystem
existence, symlink containment or byte preservation. Host integration tests own
that evidence. Reviewed repository HTML/SVG/players follow the site's trust model;
this contract is not an untrusted-upload sanitizer.

There are no per-file hashes, digest manifests or freshness records. Archive
download checksums belong to release installation and are unrelated to galleries.

`examples/` is an original Apache-2.0 Telescope fixture with a consumer-owned typed
producer and supplied static illustration/player. It copies no upstream domain
engine or generated diagram. Tests exercise all seven family labels as data, not
as claims that Telescope can render those languages.
