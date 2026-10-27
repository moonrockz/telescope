# Native host

Import `moonrockz/telescope/host` from the published library for filesystem,
rendering and process orchestration. It supports the native target. Pure
configuration and content packages remain available on every supported target.

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

The clean candidate-consumer test imports this public host from the packaged
version and registers a small custom fence provider outside Telescope's workspace.
It demonstrates provider-driven rendering without copying host implementation
or importing a consumer domain engine into Telescope.
