# Native host

Since 0.1.1, the host restores latest-tree canonical links during assembly when
`site_url` is supplied and the page exists in the latest release. It preserves
authored canonical links. The published 0.1.0 host does not insert missing
canonical links.

Import `moonrockz/telescope/host` from the published library for filesystem,
rendering and process orchestration. It supports the native target. Pure
configuration and content packages remain available on every supported target.

Native filesystem boundaries normalize Windows drive and UNC paths, including
extended canonical prefixes, before containment checks and path joins. POSIX
filenames and authored relative-path restrictions retain their existing rules.
The Windows native-host CI job checks this library boundary and blocks release
publication on a failure. It does not create a Windows CLI archive; CLI archive
qualification remains Linux x64 and macOS arm64.

```moonbit
let warnings = @host.build(
  root,
  config_path,
  output_dir,
  providers=registry,
)
```

`build(root, config_path, out, base?, providers~, main_build~)` reads reviewed
content, forwards the explicit `extensions.Registry` to `site.build`, validates
all provider assets and output collisions, stages files, checks them, and
promotes the completed output. `providers` defaults to an empty registry and
`main_build` defaults to false. Set main_build true when drafts must fail.

Providers are consumer-compiled callbacks. Configuration never discovers or
loads executable packages. The stock CLI calls this same host with no custom
providers. The host records provider IDs and supplied gallery inputs in
`telescope-build.json`, without hashes. CSS and generic browser islands are
embedded with the package and generated from pinned tools during packaging.

`check(out, base)` aggregates built-output diagnostics. `diagnostics(problems,
"text" | "json")` formats them. `serve(out, base, port)` is loopback-only and
supports GET and HEAD. `assemble(manifest_path, out)` consumes supplied checked
trees offline. See the repository CLI documentation for boundary, staging,
version and artifact rules.

The independent consumer test imports this public host from the packaged
candidate or the actual published version and registers a small custom fence provider outside Telescope's workspace.
It demonstrates provider-driven rendering without copying host implementation
or importing a consumer domain engine into Telescope.

Gallery builds verify every artifact before reading source text. Declared UTF-8
text sources feed the pure gallery planner through its optional `source_text=`
map, keyed by source path. The host renders all available text into the static
detail HTML and escapes it literally. Unsupported media, malformed UTF-8 and
NUL-bearing binary sources retain labeled downloads. A source declaration does
not exempt previews, players or companions from their resource checks. The copy
plan and download bytes remain unchanged. See the [gallery contract](../gallery/README.md)
for supported MIME types, progressive controls and no-script behavior.
