# Release verification

## Published 0.5.0, 2026-10-29

Owner-approved repaired source `4116b2d51da5ff8999ca8437e4aa0a973e7babdf` from
[PR 19](https://github.com/moonrockz/telescope/pull/19) passed
[Actions run 40895904607](https://github.com/moonrockz/telescope/actions/runs/40895904607), including both platform qualifiers,
the live exact-commit/version gate, publication and real Linux public installs.
Independent macOS public installs passed with no candidate cache or workspace
override. Both CLI archives and the public Mooncakes ZIP match the same-run
qualified artifacts. The tag points to the approved commit.

The release passed 285 native tests, strict portable checks on all four targets,
124 Chromium cases, publisher/public-index regressions and packaged consumers.
[The release guide](0.5.0.md) records behavior, downloads and four public consumer
reports. [Publication metadata](publication-0.5.0.json) records provenance and
verified SHA-256 values, including the failed first attempt's recovery.

## Published 0.4.0, 2026-10-28

Owner-approved [PR 16](https://github.com/moonrockz/telescope/pull/16) merged as
`8ab416c7f6e1fc1973f5a4b0caac628978f0895f`, retaining its qualified head tree.
[Actions run 40767534086](https://github.com/moonrockz/telescope/actions/runs/40767534086) repeated Linux/macOS qualification and
passed the live exact-commit/version owner/admin gate, credential-dependent dry
run, publication and real Linux public consumer. Independent macOS public
qualification passed too, without a candidate cache or workspace override.

The release passed 284 native tests, strict four-target pure checks, publisher
and public-index regressions, packaging and prepared consumers. Linux passed all
120 browser cases. Actual public library and CLI downloads match the same-run
qualified artifacts byte for byte; tag v0.4.0 points to the approved source.
[The release guide](0.4.0.md) records public pins, downloads, SHA-256 hashes,
migration notes and the four host/CLI/tutorial/editor public consumer reports.
[Machine-readable metadata](publication-0.4.0.json) retains the source and receipts.

## Published 0.3.0, 2026-10-28

The owner approved publication from PR 11's squash merge
`6afd8622e81a1778467fc55a8242d2071d3c39d0`.
[Actions run 40637807149](https://github.com/moonrockz/telescope/actions/runs/40637807149)
passed both platform qualifiers and the live exact-commit/version owner/admin
gate, then published `moonrockz/telescope@0.3.0` and matching CLI v0.3.0.

Qualification passed 282 native tests, two release-gate tests, 18 JS unit tests,
compiled native/worker protocol parity, publisher regressions, public-index
bootstrap, all-target portable checks, packaging and prepared consumers. Linux
passed all 108 Chromium scenarios. Real published consumers then passed on Linux
x64 in the publication job and independently on macOS arm64. They resolved the
actual registry package and checksum-verified release archive from empty homes,
without candidate caches or workspace overrides.

[0.3.0.md](0.3.0.md) records exact downloads and SHA-256 values, the four public
consumer reports and machine-readable publication evidence. Standalone Formatter
use requires no tutorial import; tutorial qualification includes seven independent
cases, native/worker JSON and revision parity, Chromium edits, deterministic
builds and both `/` and `/sample/v/1/` bases. Existing gallery and version-one
consumer regressions pass. No downstream migration is claimed.


## Published 0.2.1, 2026-10-27

Owner-approved PR 8 merged as `1f84c6c8de780ea9322db6eef14c10395a4670f9`,
retaining the exact qualified tree of `4e6dc1d2b7db47a86a77d7efb9c407c6a4b4b7e7`.
[Release run 40594390130](https://github.com/moonrockz/telescope/actions/runs/40594390130)
passed both native qualifiers and the exact-commit owner/admin gate, then
published `moonrockz/telescope@0.2.1` and matching native CLI archives.

Both qualifiers passed 232 native tests, two release-gate tests, two publisher
regressions, public-index bootstrap, all-target pure checks, packaging and
prepared consumers. Linux passed all 56 browser cases and a real public install.
An independent macOS public install passed with
`mise run test:consumer -- --published 0.2.1`. Both started from empty registries
without local paths, workspace overrides or candidate entries.

[The release guide](0.2.1.md) records exact public coordinates and verified
checksums. Reports are [Linux](consumer-0.2.1-linux-x64.json) and
[macOS](consumer-0.2.1-macos-arm64.json). They retain root/nested deterministic
builds, manifest version 1, exact source/artifact bytes and public API coverage.
The patch aligns gallery reset controls and uses the shared indigo fill.


## Published 0.2.0, 2026-10-27

The owner approved PR 7 and publication of 0.2.0. Its squash merge
`597f50ab27ffc116d50b48c7a402a250ade856b2` retained the exact qualified tree of
`a97d05a3ffc9934f590217f67677cd064b23388f` on an unchanged base.
[Actions run 40573188390](https://github.com/moonrockz/telescope/actions/runs/40573188390)
passed both native qualifiers and the exact-commit owner/admin gate, then
published `moonrockz/telescope@0.2.0` and matching CLI archives.

| Qualification | Result |
| --- | --- |
| Native Linux and macOS | 232 engine tests, two owner-gate tests, two publisher regressions, public-index bootstrap, all-target pure checks, packaging and prepared installs passed |
| Linux browser | 56 cases passed, including palette contrast, gallery filtering, keyboard tabs, source copying, no-script fallback and version-tree source preservation |
| Real Linux public consumer | Passed in the publication job from an empty registry and actual downloads |
| Real macOS public consumer | `mise run test:consumer -- --published 0.2.0` passed from an empty registry and actual downloads |

Retained reports are [Linux](consumer-0.2.0-linux-x64.json) and
[macOS](consumer-0.2.0-macos-arm64.json). [0.2.0.md](0.2.0.md) records the exact
library pin, supported compiler, public archive URLs, SHA-256 values and Orca
handoff acknowledgement. Both public installs verify manifest version 1, static
source inspection and unchanged artifact bytes at root and nested bases, without
candidate caches or workspace overrides. Diagrams pinned these real artifacts
after receiving and acknowledging the release evidence.

## Published 0.1.1, 2026-10-27

The owner approved PR 5 and publication of 0.1.1. Its squash merge
`4c2c7ebb235425c917780fccfc874a5beb06c156` retains the qualified tree.
[Actions run 40531421002](https://github.com/moonrockz/telescope/actions/runs/40531421002)
passed both platform qualifiers and the live exact-commit owner/admin gate,
then published `moonrockz/telescope@0.1.1` and matching native CLI archives.
The server accepted the dry run with HTTP 202 and the real upload with HTTP 200.

| Qualification | Result |
| --- | --- |
| Native Linux and macOS | 224 engine tests, two owner-gate tests, two publisher regressions, public-index bootstrap, all-target pure checks, packaging and candidate installs passed |
| Linux browser | 42 checks passed, including gallery navigation/downloads, no-script version trees and canonical availability |
| Real Linux published consumer | Passed in the publication job, from an empty registry and actual downloads |
| Real macOS published consumer | `mise run test:consumer -- --published 0.1.1` passed from an empty registry and actual downloads |

Retained reports are [Linux](consumer-0.1.1-linux-x64.json) and
[macOS](consumer-0.1.1-macos-arm64.json). Exact versions, downloads, archive
SHA-256 values and API compatibility are in [0.1.1.md](0.1.1.md). Each published
consumer verified exact pins, CLI version/checksum, a compiled custom provider,
deterministic root/nested builds, failure preservation, API generation and
preview shutdown. Neither used a candidate registry or workspace override.

This release restores gallery primary/family navigation and SVG downloads,
plus latest-page canonicals without truncating filenames such as `genindex.html`.
The review finding for that filename case was reproduced, fixed, replied to and
resolved before merge. Diagrams receives the actual 0.1.1 pins and checksums in
Orca dispatch `ctx_673ab88ae239` on Run `run_b3638d9bfa3d`.

Elapsed release time was 13m41s. Linux qualification took 12m31s, including the
browser dependency installation; macOS waited about 10 minutes for a runner and
then qualified in 2m34s. Publication and actual Linux installation took 58s.
These are observed elapsed times, not billed cost or a promised feedback target.

## Published 0.1.0, 2026-10-27

The owner-approved [release run 40520332727](https://github.com/moonrockz/telescope/actions/runs/40520332727)
published `moonrockz/telescope@0.1.0` and both matching CLI archives from
`f119b0621d4a6dfe02a5e84615027a133e7f460f` after PR 4 merged. Its tree matched
the qualified head with an unchanged base. The live owner/admin gate passed.
The server returned HTTP 202 for the accepted dry run and HTTP 200 for actual
publication. [Installation and API/adapter compatibility](0.1.0.md) records exact
downloads and archive checksums.

| Qualification | Observed result |
| --- | --- |
| Both exact-source release qualifiers | Setup, strict native compilation, 221 native tests, two owner-gate tests, all-target pure-package checks, packaging and prepared consumers passed |
| Environment regressions on both platforms | Two publisher regressions and one fresh-public-index regression passed |
| Linux browser checks | 38 passed using the produced native CLI |
| Actual Linux published consumer | Passed inside the publication job from the public registry and GitHub downloads |
| Actual macOS published consumer | `mise run test:consumer -- --published 0.1.0` passed locally from the public registry and GitHub downloads |

Both actual published consumers verified exact pins, CLI versions and SHA-256,
compiled the public host with a consumer-owned provider, and built and checked
mixed content at `/` and `/example/`. Deterministic output, failed-build
preservation, template exclusion, API generation, HEAD responses and preview
shutdown passed. Retained reports are [Linux](consumer-0.1.0-linux-x64.json) and
[macOS](consumer-0.1.0-macos-arm64.json). Neither consumer seeded a candidate
entry or used a moon.work/local-path override. No local publication credential
was created; the Actions-only credential was removed with its temporary home.

The release took 3m40s. Linux qualification took 2m29s, macOS 2m44s and
publication plus actual Linux installation 48s. These are elapsed job times,
not billed cost. Both native qualifiers gate promotion; browsers run once on
Linux. Publication promoted the same qualified archives without rebuilding.

Both published-install results and exact coordinates were sent through Orca
Run `run_b3638d9bfa3d` to diagrams dispatch `ctx_a1b42e27a11a`. The worker
acknowledged them and resolved the actual registry pin. Diagrams integration
and its own review remain in progress in PR 32.

## Historical candidate verification, 2026-10-26

The following is the prerelease record, retained as history. Its unpublished
status, pending CI and unperformed publication statements apply to that date.

This records the final local, unpublished public-host 0.1.0 candidate on macOS arm64. It does not
record a release, owner publication approval, a merged release PR or downstream
adoption. [Implementation PR 1](https://github.com/moonrockz/telescope/pull/1)
contains the candidate; the checksums below identify the local package inputs.

The compiler was v0.10.17+093cb8f9c, selected through its pinned mise installation
and explicit MOON_HOME/PATH. Moon's executable build date is 2026-10-21; it is
not a different compiler version. Bun 1.4.3 bundled the generic islands, and
Node 24.14.1 ran the pinned browser harness.

| Command | Observed result |
| --- | --- |
| `mise run format` | Passed |
| `mise run check:setup` | Passed script checks, YAML, actionlint 1.7.12, schema/assets and OpenSpec validation |
| `mise exec -- openspec validate --all --strict` | Passed, one change |
| `mise run check` | Strict native compilation and 219/219 native tests passed; model/content/gallery/extensions checked on wasm, wasm-gc, JS and native |
| Pinned `moon test pkgs/telescope/host --target native --deny-warn` | 12/12 focused host tests passed |
| Pinned `moon test scripts/release-approval.mbtx --deny-warn` | 2/2 publication-gate regression tests passed |
| `mise run package` | Library ZIP and relocatable macOS arm64 native archive/checksum created; CLI reports 0.1.0 |
| `mise run test:consumer -- --prepared` | Passed the external, isolated-cache candidate consumer |
| `mise run test:browser` | 38/38 passed before the static mapping addition; current-source browser CI remains pending |

The consumer used a real `moon package` ZIP inserted into an isolated temporary
Mooncakes cache/index with explicit prerelease metadata derived from the packaged
module's pinned imports. Its manifest pinned `moonrockz/telescope@0.1.0`; no
moon.work or local-path override was created. Only compiler bin/lib/include were
linked as tools. The library tests include calling the public host with a custom compiled fence
provider, both passing with warnings denied. The CLI was installed by extracting
its native archive after SHA-256 verification, outside all source workspaces.

The consumer built and checked its own mixed Markdown/full-HTML fixture at `/`
and `/example/`. It compared every output path and byte across repeated builds,
proved a failed build retains prior output, confirmed development templates are
excluded, and exercised explicitly configured fresh `moon doc` generation.
Loopback preview served nested CSS, HEAD returned valid 200 and 404 responses,
and shutdown released its port. No reference checkout was used by the harness.

Host regressions cover traversal/UTF-8 paths, aggregated missing resource and
fragment diagnostics, atomic promotion, escaping symlinks, aggregated gallery
artifact and CSS companion failures, planned-only galleries without artifact
roots, offline no-release assembly, metadata-output containment, and byte-identical
gallery HTML/JSON through version assembly. Search indexes remain tree-relative
and are copied unchanged. The browser harness separately proves search under
assembled root/latest trees, HEAD availability checks, missing-page fallbacks,
static banners, theme/storage behavior, keyboard controls, registered islands,
no-JS reading and the narrow ToC fallback.

The final candidate files are:

| Artifact | SHA-256 |
| --- | --- |
| `_build/publish/moonrockz-telescope-0.1.0.zip` | `328fd5bd17179bcc605299dde2a5f6d28b337ff5a771c4ebb5fec6ee362d2fd9` |
| `_build/package/telescope-0.1.0-macos-arm64.tar.gz` | `8cb78bc1724a00a6ecbc333e948b06e5de26b9ebd382de9e837d9cad57242b3c` |

The native archive retains available resolved dependency license/notice files
and module metadata, plus MoonBit core's license. Real diagrams content exposed
missing stable static-resource copying. The host now supports explicit directory
mappings, with byte, exclusion, traversal, symlink and output-collision regressions.
The full engine check, packaging and installed-consumer suite passed again after
that source change. Actual CI also exposed an empty registry on fresh machines;
setup now initializes the pinned Moon registry before running scripts.

Machine evidence is `_build/evidence/consumer-macos-arm64.json`, plus browser
`results.json`, `cli-evidence.json`, report, traces and screenshots. No gallery
hashes or output digest manifests were introduced. These archive checksums are
retained for package integrity and installation.

The [first successful Actions qualification](https://github.com/moonrockz/telescope/actions/runs/40422349667)
passed both Linux x64 and macOS arm64 at engine source commit
`8636c261ae8ea5dd8f52146b7d231813537e8822`. Each platform passed setup,
engine checks, packaging and isolated candidate installation; Linux also passed
all 38 browser checks using its produced CLI. The macOS job took 1m56s. These
are candidate qualifications, with publication disabled.
The release gate's pure stale/unmerged/wrong-branch tests passed, but its live
GitHub permission/PR API happy path and actual publication have not run.

The pinned `moon publish --dry-run` exits 255 without credentials.json before it
can package. No dummy or real credential was installed locally. A trusted Actions
preflight checks secret availability as a boolean; current availability remains
unknown. The credential-dependent publication dry run is inside the explicitly
approved Actions publication job. Publication remains blocked until an authorized
owner/admin dispatch identifies the exact main merge SHA, version and merged
release PR, with the required candidate checks and actual credentials available.

Publication, merge, archive and real published-consumer work have not occurred.
Tasks 7.2 onward remain unverified; implementation stories stay open until merge.

The separate actual-diagrams fixture now passes through the public host and
consumer-owned Mermaid/PlantUML providers: 77 routes, 5,376 genuine anchors,
nine escaped XML code literals, 12 gallery entries and 40 byte-identical
artifact copies. Internal links and those comparisons pass across root, next,
v/0.2 and latest supplied trees. Its [report](../../tests/diagrams-consumer/report.json)
records exact source refs and the source-level prerelease boundary. Existing
missing API prose generates 3,831 warnings; there are no other warnings. No
downstream dependency or engine was changed by that test.

`mise run test:diagrams-consumer` uses the pinned wrapper but is excluded from
normal check/CI because it requires an external checkout. Final `mise run format`
and `mise run check:setup` passed after the fixture was completed. This proof
complements the isolated packaged consumer; neither is a real published install.
