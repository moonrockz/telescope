# Tasks

Status: Implementation approved. The candidate is unpublished. Local macOS arm64
library, CLI, isolated packaged-consumer and 38 browser checks pass. Linux CI and
the actual diagrams compatibility fixture are pending. Publication requires the
separate owner approval in group 7; downstream adoption remains blocked until
real published-consumer verification succeeds. Stories stay open until merge.

## 1. Prove an independent packaged consumer

Bead: telescope-0wg.1

Owner: Telescope implementation maintainer. Dependencies: proposal approval.

Acceptance: A new consumer outside all source workspaces installs a packaged
candidate library and CLI by exact version, builds and checks one page at `/`
and `/example/`, and uses no local path dependency or sibling workspace member.
This is a prerelease proof, not permission for diagrams to adopt the candidate.

- [x] 1.1 Add the minimal published-module and CLI layout with pinned dependencies and retained source notices; verify public interfaces compile and no consumer engine import enters the package graph.
- [x] 1.2 Implement one thin path through pure config/content, Rabbita rendering, async host output and CLI build/check; verify a one-page mixed-content fixture builds and checks at both required base paths.
- [x] 1.3 Package the candidate library and CLI and add `mise run test:consumer` to create a fresh external consumer with an isolated candidate registry/cache; verify recorded package version/source, CLI version and zero local-path/workspace overrides.
- [ ] 1.4 Document and run the complete candidate-consumer instructions on Linux x64 and macOS arm64, recording platform results and package provenance; verify the test still works with all reference checkouts unavailable.

## 2. Extract content, routes and navigation

Bead: telescope-0wg.2

Owner: Telescope implementation maintainer. Dependencies: group 1.

Acceptance: Pure packages check across wasm, wasm-gc, js and native; mixed
HTML/Markdown fixtures preserve links/IDs at root and nested bases. Development
templates stay out of public output, navigation and search.

- [x] 2.1 Add configuration validation, deterministic route planning, navigation groups and package/chapter order; verify duplicate routes, invalid bases and nav collisions produce aggregated source diagnostics.
- [x] 2.2 Add front matter, document facts, heading IDs and link resolution over supplied text, with native CommonMark rendering behind the host adapter; verify mixed-format fixtures preserve full HTML heads and fragment shell behavior.
- [x] 2.3 Add explicit source discovery and resource copying with default exclusions for development templates, planning artifacts and build output; verify an exclusion fixture and traversal/collision rejection.
- [x] 2.4 Port only needed attributed source fixtures and document configuration, trust model and HTML/Markdown rules; verify focused content tests and all-target pure package checks, then run the documented fixture build.

## 3. Build the generic shell and optional islands

Bead: telescope-0wg.3

Owner: Telescope implementation maintainer. Dependencies: groups 1 and 2.

Acceptance: An unrelated project gets its own branding, docs/articles/feed and
search/theme controls. Static reading works without JS. Page-specific scripts
load only on their registered routes.

- [x] 3.1 Generalize the Rabbita layout, landing/docs/article views, ToC and feed metadata; verify no reference-project branding appears in an unrelated-consumer fixture and feed URLs use its canonical base.
- [x] 3.2 Add deterministic local search and theme/menu/ToC/copy islands with pinned JS/browser tooling; verify keyboard use, no-JS reading, stored theme before paint and denied-storage fallback in browser tests.
- [x] 3.3 Add per-route island assets and static fallbacks; verify an extension page loads its script while ordinary docs do not, and document the mount and asset contract with a working sample.
- [x] 3.4 Document shell customization, article drafts and theme behavior; verify examples build and focused browser/feed/search tests pass, including a narrow viewport with long paths.

## 4. Complete host build, check and serve tooling

Bead: telescope-0wg.4

Owner: Telescope implementation maintainer. Dependencies: groups 2 and 3.

Acceptance: CLI output is deterministic; failures name stage and source; failed
builds preserve the previous completed site. Built checks cover page/fragment/asset
links, and preview serves the configured base on loopback and shuts down cleanly.

- [x] 4.1 Add staged output promotion and explicit input/output boundaries using async IO; verify two builds have identical file paths and bytes and a failed build leaves the prior output intact.
- [x] 4.2 Add human and JSON built-output diagnostics for pages, fragments, assets, feeds and base-path escapes; verify broken-link fixtures report all expected origins and exit nonzero.
- [x] 4.3 Add loopback `serve` with configured base, explicit port, safe resource paths and signal cleanup; verify nested asset requests and that shutdown releases the port without any publication or release fetch.
- [ ] 4.4 Add meaningful engine `mise run check` and focused CLI tasks, documenting exit codes and build/check/serve usage; verify those commands on both initially supported native platforms and keep `check:setup` distinct.

## 5. Add typed adapters and gallery artifacts

Bead: telescope-0wg.5

Owner: Telescope implementation maintainer; diagrams maintainer supplies its
manifest producer in `adopt-telescope-site`. Dependencies: groups 2 through 4.

Acceptance: A consumer-compiled adapter and prebuilt gallery work without any
domain engine in Telescope. Stable records preserve declared support status and
artifact bytes. Missing, escaping or symlink-redirected files fail.

- [x] 5.1 Define adapter contract version 1 for pages, fences and islands with explicit IDs, inputs, outputs and errors; verify duplicate IDs/version mismatch fail and unhandled fences remain escaped code.
- [x] 5.2 Define the gallery manifest with stable ID/family/title/status and source references, SVG previews, optional offline players and companion files; verify valid implemented and planned records and schema-version rejection.
- [x] 5.3 Validate regular files, normalized paths, realpath/symlink containment and output collisions before copy; verify focused negative tests for each failure and byte-preserving offline artifact playback.
- [x] 5.4 Document and test a consumer-owned sample adapter and gallery producer using small attributed fixtures; verify implemented sequence/BPMN/swimlane/regex/EBNF/JSON/YAML and planned general PlantUML/DOT/Draw.io statuses are presented faithfully without adding their engines.

## 6. Preserve optional API and version-tree behavior

Bead: telescope-0wg.6

Owner: Telescope implementation maintainer; diagrams maintainer reviews its
compatibility fixtures. Dependencies: groups 2 through 5.

Acceptance: Optional adapters preserve diagrams' API anchors/prose/signature and
source links, chapter order, search and root/next/v/minor/latest layout. Offline
assembly consumes supplied trees, leaving tag lookup and deployment to consumers.

- [x] 6.1 Extract optional `moon doc` ingestion using the attributed notebooks fixture and fresh pinned-compiler output; verify item/method anchors, qualified links, doc prose, source file/lines and unsupported-shape diagnostics.
- [ ] 6.2 Preserve API search entries, chapter order, `api:` references and missing-prose diagnostics; verify focused API fixture comparisons against the recorded diagrams baseline and document module/ref input configuration.
- [x] 6.3 Add the optional supplied-tree assembly adapter and version manifest; verify offline root/next/v/minor/latest output, reserved-prefix rejection, tree-local assets/search and no network or checkout mutation.
- [x] 6.4 Add version selector and static banners with same-page and missing-page fallback; verify no-release, older-release and next-only-page cases in browser tests and document the consumer release-policy boundary.
- [ ] 6.5 Run an attributed diagrams-compatibility fixture through both optional adapters; verify the route/anchor manifest and internal links before marking the first release usable, and send results through mailbox `run:run_b3638d9bfa3d`.

## 7. Prepare and publish the first usable distribution

Bead: telescope-0wg.7

Owner: Telescope repository owner authorizes publication; release maintainer
executes it. Dependencies: all earlier groups and explicit publication approval.

Acceptance: Library and CLI are published at the same actual semantic version
after owner approval. A clean consumer installs both from real distribution
sources, verifies checksums and builds/checks without any local overrides.

- [ ] 7.1 Prepare an owner-gated GitHub Actions release workflow and release PR with semantic version, changelog, supported-platform archives, SHA-256 checksums, registry metadata and complete notices; verify package dry-run, all checks and reproducible candidate installation instructions.
- [ ] 7.2 Obtain and record explicit Telescope repository-owner approval of publication before executing it; verify the approval identifies the release PR/version and keep publication and downstream readiness blocked if absent.
- [ ] 7.3 After that approval, publish through GitHub Actions the library to Mooncakes and matching CLI archives/checksums to the versioned GitHub release; verify both real coordinates exist and report partial-publication failure without claiming readiness.
- [ ] 7.4 Run `mise run test:consumer -- --published <actual-version>` in a clean environment against the real registry and downloads; verify exact pins, CLI version, checksums, both deployment bases and no candidate registry, local paths or workspace overrides.
- [ ] 7.5 Publish version-specific install/API/adapter compatibility documentation and send exact release coordinates and test evidence to `run:run_b3638d9bfa3d`; verify the diagrams maintainer can replace its adoption gate with those actual pins before removing its generator.

## Workflow follow-up

- Keep each story open until its PR merges, then close it with PR and merge SHA.
- The release PR can merge before publication. Keep group 7 open until the final
  verification/documentation PR records real published-install evidence and
  archives the change. Do not publish from a workstation.
- Archive in that last implementation PR, repair archived asset prefixes to
  `../../../../docs/templates/assets/`, merge spec deltas and update inbound links.
- Validate all specs and setup after archive; close the local epic only after all
  child stories merge and its spec link points to the archive.
- diagrams.mbt implements its own `adopt-telescope-site` change after verified
  publication. Smithy and Morphir migration requests need separate proposals.
