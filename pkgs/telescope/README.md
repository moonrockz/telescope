# Telescope library

`moonrockz/telescope` is a project site library. Version `0.1.1` is published with
a matching native CLI. The CLI is built from `apps/telescope` in this repository.
See the repository's version-specific release documentation for installation
and compatibility evidence. New publications require owner approval.

| Package | Responsibility | Targets |
| --- | --- | --- |
| `model` | Configuration, routes, diagnostics, search, API metadata and version navigation | wasm, wasm-gc, JS, native |
| `content` | Front matter, HTML facts, heading IDs, text and URL rewriting | wasm, wasm-gc, JS, native |
| `markdown` | Native CommonMark rendering into `content.Document` | native |
| `views` | Rabbita document shell, landing pages, docs, articles and ToC | native |
| `site` | In-memory source preparation and rendering into output instructions | native |
| `host` | Contained async IO, provider builds, staged promotion, checks, preview and assembly | native |
| `gallery` | Supplied artifact manifest validation and presentation | portable |
| `extensions` | Explicit page, fence and island adapter contracts | portable |
| `islands` | Search, theme, navigation, ToC, copy buttons and version selection | JS |

The module contains no diagram engine imports. Native CommonMark is pinned to
`moonbit-community/cmark@0.4.12`; rendering uses
`moonbit-community/rabbita@0.16.5`. All external module versions are pinned in
`moon.mod`. Source provenance and Apache notices are in `NOTICE` and `LICENSE`.

## Configuration

Parse configuration with `model.SiteConfig::parse(source_name, json_text)`.
It raises `model.Invalid(Array[Problem])`, with source file, line and message.
`Problem::render()` produces a readable diagnostic. JSON object keys below are
stable version 1 inputs; an omitted `schema_version` retains the original site
configuration compatibility, and an explicitly unsupported version fails.

```json
{
  "schema_version": 1,
  "title": "Observatory",
  "description": "Tools for observing projects",
  "base_path": "/observatory/",
  "site_url": "https://example.org/observatory/",
  "repo_url": "https://github.com/example/observatory",
  "repo_ref": "reviewed-ref",
  "docs_dir": "guide",
  "pages_dir": "site/pages",
  "articles_dir": "site/articles",
  "source_roots": ["guide", "site/pages", "site/articles"],
  "nav": [{"group": "Guide", "items": ["start.md", "reference/"]}],
  "footer": "Observatory contributors",
  "packages": [],
  "api": []
}
```

The default content directories are `docs`, `site/pages` and `site/articles`.
The default discovery roots also include `pkgs` and `apps` for selected package
READMEs. `source_roots` bounds discovery, and `config.includes(path)` applies
normalized paths and exclusions. `exclude`, when supplied, replaces the default
list. Defaults exclude templates, superpowers plans, agent metadata, OpenSpec,
Git, dependencies and build output. Opting in to development material requires
both an explicit source root and an exclusion list that permits it.

`packages` lists package names with READMEs below `pkgs/` or `apps/`. `chapters`
maps those names to ordered sub-package paths. `api` lists explicitly selected
relative module directories, including layouts outside `pkgs/`. Navigation
entries name top-level pages, directories or globs below `docs_dir`; every
published docs page must match exactly one group when groups are configured.

`base_path` is an absolute URL path ending in `/`, with no traversal or encoded
segments. `site_url` ends in `/` and denotes the canonical URL of that tree.
`config.href(route)` prefixes internal routes with `base_path`, while
`config.absolute(route)` uses `site_url`. Source links use `repo_url` and
`repo_ref`, whose default is `main`.

## Content and trust

Inputs are reviewed repository content. Raw HTML, provider output and island
fallback HTML are trusted and are not sanitized. This library is not an upload
service. The host validates regular files, realpaths, input/output boundaries
and collisions before writing or copying.

Markdown uses CommonMark with tables, task lists and strikethrough. Front matter
accepts text and list fields. Documents use `title`, `summary`, `order` and
`status: proposed`; articles also require `title`, `date` and `authors`, with a
filename `YYYY-MM-DD-slug.md` or `.html`. Drafts are skipped with a warning in
both preview and release preparation. The retained `main_build` argument allows
existing callsites to compile; it does not publish draft content.

HTML fragments receive the shell. Complete HTML documents preserve their own
head and structure and receive no second shell. Relative `href` and `src` links
are rewritten against the source path, and referenced public resources produce
copy instructions. Headings retain explicit IDs and attributes; missing IDs
use stable slugs with numeric suffixes for repeated text. Full HTML files retain
their exact structure apart from source-relative URL rewriting.

Every unhandled code fence remains escaped code, including diagram languages.
Consumers compile explicit providers when they want another representation.
The optional `content.check_moonbit_fences` helper is a consumer lint policy;
Telescope does not require a `notest` marker to display code examples.

## Build contract

`site.SourceFile` contains `{ path: String, text: String? }`. Paths are relative
to the consumer root; source content needs text, while binary resources use
`None`. `site.prepare(config, sources, main_build~, api?, providers?,
external_routes?)` validates sources and returns pages, copy pairs and warnings.
`site.build` accepts the same inputs asynchronously and returns `site.Built`.

`Built.outputs` contains `Output::Text(output_path, text)` and
`Output::Copy(output_path, consumer_source_path)`. All output paths are relative.
The `site` planning API performs no filesystem IO and does not fetch tags.
The published native `host` package supplies source discovery, API inputs,
staged writes and link checks. It rejects symlink escapes and file/directory
collisions, combines output producers before promotion, and supplies embedded
shell CSS and compiled islands as `assets/site.css` and `assets/islands.js`.

Without a landing source, build generates a project title and description page.
Generated docs and article indexes, Atom feed and deterministic local search
remain inside the configured tree. Drafts do not enter indexes or feeds.
`external_routes` declares pages supplied by other host producers, such as a
gallery, so references to those pages can be validated during preparation.
It does not create those pages; built-output checks must verify their output.

## Providers and islands

Pass `providers~: extensions.Registry` to `site.prepare` or `site.build`.
Registry validation runs before callbacks. Page adapters create explicit routes;
fence adapters receive source, route, base, language and decoded fence body.
Callbacks return typed HTML, text, headings, assets and problems. Errors name the
adapter, stage and source. Provider assets become copy instructions from their
consumer-relative paths and remain subject to host containment checks.

Island registrations name exact routes, a mount ID, script, optional stylesheet
and readable fallback HTML. Only those routes get their mount and assets.
The JS script owns that mount and replaces or augments its fallback. Full HTML
pages can receive explicitly registered islands without getting the site shell.
The executable library sample is `site/providers_test.mbt`, which compiles a
consumer callback and checks both its page and fence output and route isolation.
See `extensions/README.md` and `gallery/README.md` for those contracts.

## API metadata and versions

`model.ApiPackage::parse(file, text)` reads compiler `package_data.json`, and
`model.api_index_packages(file, text)` reads `module_index.json` in package order.
The supported format is pinned to MoonBit `0.10.17+093cb8f9c`. Unsupported required
shapes raise source diagnostics rather than silently emitting incomplete pages.
`site.ApiSite` contains the supplied commit and `ApiModule` values, each with
module directory, module name, packages and package README text.

The API output retains `/api/<qualified-package>/`, item `#Name`, method
`#Type.method` and trait implementation anchors. Selected-package signature
links and `api:` prose links stay in the current tree. Unselected qualified
package signature links point to the Mooncakes module docs root without guessing
a symbol fragment, and explicit HTTP(S) signature
links remain external. Source links retain the
supplied build ref, file and line. Missing prose becomes a build warning.
The notebooks fixture in `model/api_fixture_test.mbt` preserves the diagrams
baseline; `fixtures/moon-doc` records fresh compiler metadata for this module.

`model.VersionsFile` describes the supplied latest minor line, whether next
exists and the ordered retained lines. Its helpers implement root, `next/`,
`v/<minor>/` and `latest/` URLs without release discovery or network IO. The host
assembles checked trees. The browser selector probes the same page, then falls
back to that tree's docs, articles or API index, or its home for another section.
Reserved version prefixes cannot be claimed by content/provider routes.
No-release data creates no invented latest link. Release policy and deployment
belong to the consumer.

## Verification

From the repository root, using the pinned mise toolchain:

```shell
mise exec -- moon check pkgs/telescope/model pkgs/telescope/content --target all --deny-warn
mise exec -- moon test pkgs/telescope/model pkgs/telescope/content --target all --deny-warn
mise exec -- moon test pkgs/telescope/markdown pkgs/telescope/site pkgs/telescope/views --target native --deny-warn
```

These commands verify library behavior. Host, fresh-consumer packaging,
supported-platform and browser checks are separate release evidence.

Native consumers can also import `moonrockz/telescope/host`. Its `build` accepts
an explicit `extensions.Registry`, performs contained async IO and staged output
promotion, and validates/copies provider assets. Custom drivers use the released
host directly; the stock CLI is a thin caller with an empty registry. See
[host documentation](host/README.md). Pure-package consumers do not import the
native host.
