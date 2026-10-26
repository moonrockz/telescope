# Telescope CLI

Custom native drivers import `moonrockz/telescope/host` and call
`build(root, config_path, out, providers=registry)` with explicit compiled adapters.
The stock CLI uses that same published host with an empty registry.

Run commands from the consumer project root. Configured paths are relative to
that root, including sources, gallery files and optional API module directories.
The CLI has no release-fetch or deployment command.

```json
{
  "schema_version": 1,
  "title": "Independent Observatory",
  "description": "Project documentation",
  "base_path": "/example/",
  "site_url": "https://example.test/example/",
  "repo_url": "https://example.test/observatory",
  "repo_ref": "main",
  "packages": [],
  "source_roots": ["docs", "site/pages", "site/articles"]
}
```

```sh
telescope build --config site/site.json --out _site
telescope check --config site/site.json --out _site --format text
telescope check --config site/site.json --out _site --format json
telescope serve --config site/site.json --out _site --port 4173
```

`--base /` or `--base /example/` overrides deployment links for a preview.
`--root` explicitly chooses the project root for build. Config and source files
must remain inside it. Build rejects source/output overlap, escaping symlinks,
non-regular artifacts, output traversal and file/directory collisions.

Build renders into a private sibling directory, checks that output, then
promotes it. A failed build leaves the prior output intact. Promotion keeps a
backup until the new tree is renamed successfully and runs without cancellation.
Two builds with identical declared inputs have identical output paths and bytes.
`telescope-build.json` records the toolkit version and explicitly declared
extensions; it contains no output hashes or digest manifest.

Check aggregates missing pages/resources/fragments, deployment-base escapes,
missing titles and malformed XML feeds. It checks HTML, SVG and CSS local
resources, including quoted CSS imports and `url(...)`, against regular files
inside output. Assembled version trees are checked independently. JSON diagnostics
contain source, line and message; line zero identifies a file-level finding.
Exit codes are 0 for success, 1 for validation/build/IO failure and 2 for CLI
usage errors. Human build warnings go to stderr.

Serve binds `127.0.0.1` only and serves an existing build beneath its base path.
It rejects traversal, malformed URL escapes and escaping symlinks. SIGINT or
SIGTERM closes the listener. It does not watch, rebuild, publish or fetch releases.

Optional gallery configuration supplies `gallery.manifest` and `gallery.root`.
A planned-only gallery needs no artifact root. Implemented entries require every
artifact to be a regular contained file, and offline HTML/SVG/CSS companion
references must be declared. Supplied bytes are copied unchanged. See
[the gallery contract](../pkgs/telescope/gallery/README.md).

Use `"static": [{"from": "site/assets", "to": "assets"}]` to copy a consumer
directory to stable output URLs such as `/example/assets/logo.svg`. Both paths
are normalized relative directories; `from` is relative to the project root and
`to` to the output tree. Static directories do not need to be source roots.
Default/configured exclusions still apply. Copies preserve bytes, reject escaping
symlinks and input/output overlap, and participate in output collision checks.

Optional `api` lists consumer module directories. Supply `moon doc` output under
`api_output`, default `_build/site-api/<module>/doc`. To explicitly request the
host to invoke `moon doc`, set `api_generate` to `true`. No invocation occurs
when `api` is empty or generation is not requested. Repository source links use
`repo_ref`. The pure API parser remains in the library model.

Version assembly accepts already built and checked trees, without network IO:

```json
{
  "schema_version": 1,
  "base_path": "/example/",
  "site_url": "https://example.test/example/",
  "latest": "0.1",
  "trees": [
    {"id": "next", "path": "trees/next", "base_path": "/example/next/"},
    {"id": "0.1", "path": "trees/0.1", "base_path": "/example/v/0.1/"}
  ]
}
```

Tree paths are relative to the manifest's directory. The consumer chooses
`latest` and supplies release ordering. Omitting `latest` selects next at root
and creates no latest tree. Top-level next/v/latest source routes are reserved.
The adapter copies the selected release to root and latest, rebases URL-bearing
attributes and CSS, preserves binary assets, adds static banners and writes
`versions.json`. Older-version banners link to the same page in latest or its
section fallback. Consumers own tag selection, downloads, archive checksums,
eligibility and deployment policy.
