# Contributing to Telescope

Telescope 0.5.0 is published. Review the accepted specifications and public
package contracts before changing the engine. Implementation approval does not
authorize a new publication or a downstream migration.

## Development setup

Install mise, then run from the repository root:

```shell
mise trust
mise install
mise run format
mise run check:setup
```

Tools are pinned in `.config/mise/config.toml`: Node 24.14.1, OpenSpec 1.14.3,
MoonBit 0.10.17+093cb8f9c, Bun 1.4.3, yamllint 1.38.0 and actionlint 1.7.12. The MoonBit HTTP archive does not
include its core library. If the installed tool lacks core, complete that exact
installation using the upstream installer:

```shell
curl -fsSL https://cli.moonbitlang.com/install/unix.sh -o /tmp/telescope-install-moonbit.sh
MOON_HOME="$(mise where http:moonbit)" bash /tmp/telescope-install-moonbit.sh '0.10.17+093cb8f9c'
```

All development scripts use `moonx` with pinned external imports. Use
`moonbitlang/async` for filesystem and process IO. Mise task commands explicitly
select the pinned Moon home and put its bin directory first, including for child
processes. Do not rely on a user-installed Moon binary earlier on PATH.

`mise run format` formats the engine and development scripts. `check:setup`
checks script formatting and types, YAML workflows, the local schema, HTML asset
references and all OpenSpec artifacts. `mise run check` separately checks pure
model/content/gallery/extensions across wasm, wasm-gc, JS and native, checks
native packages with warnings denied, and runs native tests. The CommonMark
host adapter is native; pure content analysis remains portable.

`mise run package` bundles the generic JS islands using pinned Bun, embeds CSS
and JS into the native CLI, packages the library and creates the native archive
with a download checksum. `mise run test:consumer -- --prepared` consumes those
artifacts outside the workspace using an explicitly seeded prerelease cache.
After packaging, `mise run test:publish-environment` checks that the publisher's
isolated Moon home resolves the qualified library's dependencies and packages it
without a credential. PR and release qualification enforce this boundary.
`mise run test:consumer-environment` separately verifies public-index bootstrap
for a fresh published consumer, without a candidate registry or credentials.
This proves packaging shape, not publication. See [CLI usage](docs/cli.md),
[installation](docs/release/install.md) and [release gates](docs/release/README.md).

## OpenSpec and review documents

OpenSpec was explicitly initialized for this repository with:

```shell
mise exec -- openspec init --tools codex,claude,grok,cursor,github-copilot --profile core --no-animation
```

To refresh the six generated workflows for those clients, use
`mise run openspec:setup`. It isolates personal OpenSpec profile and delivery
settings and preserves existing proposals, specs and project configuration.
Codex uses `.agents/skills/openspec-propose/SKILL.md`; portable agents can read
that file directly. Other generated client directories contain equivalent
workflows. Keep repository policy here and in AGENTS.md, not generated files.

Before a new change, run `mise exec -- openspec context --json`, then use
`openspec new change <verb-name>`, `openspec status` and `openspec instructions`
through `mise exec --`. Never initialize another repository as a side effect.
A complete proposal contains `proposal.md`, `design.html`, one delta spec per
capability, and `tasks.md`. Each group states acceptance criteria and verification.
Run `mise exec -- openspec validate --all --strict` before review.

Start new HTML designs from the shared template in
`openspec/schemas/html-design/templates/design.html`. It has inline CSS and
works offline without asset path changes. Historical designs still use
`docs/templates/assets/`; repair those paths when archiving them. Keep their
license and attribution records. See `openspec/README.md` for bundle maintenance.

## Repository-local tracker

Use this repository's own beads tracker. No shared Morphir tracker, repo labels,
Dolt remote settings or close-before-merge rule applies here. Do not initialize
or create beads during proposal drafting. After maintainer approval, initialize
this repository's tracker if needed and create one epic per approved change and
one child story per numbered task group. Record each story on a separate `Bead:`
line below its heading. Pending approval is a status, not a fabricated bead ID.
Record story dependencies when groups need earlier results.

Claim the story before implementation and tick its checkboxes after verification.
Keep the story open while its PR is under review. In the last implementation PR,
archive the completed change, merge its deltas into accepted specs and repair
HTML asset paths and inbound links. Do not make archive a tracked implementation
checkbox that prevents archive readiness.

After merge, close completed stories with the PR and merge SHA as their reason.
Close the epic only when every child story has merged, and point its spec link
to the archived change. Sync using this repository's configured backend. An
unmerged PR or a local commit is not a reason to close a story. For the release
group, the release PR can merge first. Its final verification and documentation
PR records real publication evidence and archives the change; keep the story
open until that final PR merges.

## Publication and downstream adoption

The proposal chooses one published library module, `moonrockz/telescope`, and a
matching `telescope` CLI release. Its first target matrix is native CLI on Linux
x64 and macOS arm64, with pure packages checked across MoonBit targets and JS
islands tested in browsers. Other native platforms require qualification before
support claims. The owner approves a release PR before publication. Publication runs through
GitHub Actions, never from a workstation. The release workflow defaults to dry run and checks an explicit manual owner/admin dispatch approving the exact commit and version
before publication. Credentials remain an Actions-only owner setup prerequisite.
Both distributions must use the same actual semantic version. Publication is a blocking
owner gate, not an assumed successful task.

An initial fresh-consumer tracer bullet tests a packaged candidate outside the
workspace, with local registries/caches allowed only as explicit prerelease test
inputs. It cannot be used as a downstream dependency. Final distribution checks
must consume the actual published library and CLI without local path overrides.
The diagrams consumer must pin those real versions; never use 0.0.0, a proposed
version, a local path or a sibling workspace member as a substitute.

## Cross-workspace coordination

Run `run_b3638d9bfa3d` coordinates this work. Send design contract changes and
release evidence to coordinator mailbox `run:run_b3638d9bfa3d`. Telescope owns
`extract-project-site-toolkit`; diagrams.mbt owns dependent change
`adopt-telescope-site`. The coordinator owns diagrams files and their migration
proposal. Keep source inventories in Telescope's HTML design and update both
proposals through that mailbox when contracts change. Smithy and Morphir are
source references for this release, not wholesale migration targets.
