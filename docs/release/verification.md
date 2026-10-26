# Candidate verification, 2026-10-26

This records the final local, unpublished public-host 0.1.0 candidate on macOS arm64. It does not
record a release, owner publication approval, a merged release PR or downstream
adoption. The worktree is awaiting coordinator integration; artifact checksums
identify this candidate independently of an uncommitted source snapshot.

The compiler was v0.10.17+093cb8f9c, selected through its pinned mise installation
and explicit MOON_HOME/PATH. Moon's executable build date is 2026-10-21; it is
not a different compiler version. Bun 1.4.3 bundled the generic islands, and
Node 24.14.1 ran the pinned browser harness.

| Command | Observed result |
| --- | --- |
| `mise run format` | Passed |
| `mise run check:setup` | Passed script checks, YAML, actionlint 1.7.12, schema/assets and OpenSpec validation |
| `mise exec -- openspec validate --all --strict` | Passed, one change |
| `mise run check` | Strict native compilation and 217/217 native tests passed; model/content/gallery/extensions checked on wasm, wasm-gc, JS and native |
| Pinned `moon test pkgs/telescope/host --target native --deny-warn` | 10/10 focused host tests passed |
| Pinned `moon test scripts/release-approval.mbtx --deny-warn` | 2/2 publication-gate regression tests passed |
| `mise run package` | Library ZIP and relocatable macOS arm64 native archive/checksum created; CLI reports 0.1.0 |
| `mise run test:consumer -- --prepared` | Passed the external, isolated-cache candidate consumer |
| `mise run test:browser` | Browser owner reports 38/38 passed without skips, retries or flakes; actual results retained under `_build/browser/` |

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
| `_build/publish/moonrockz-telescope-0.1.0.zip` | `89a829c1cd93405973a1b6ca8a6e5626e1a7034d5f01e2d9cf69146aa0248c47` |
| `_build/package/telescope-0.1.0-macos-arm64.tar.gz` | `82c85d7bc9b4d5c3c6d1a0016f2e6a1c7337e1b6b0e2c36107baa25286f3d6f6` |

The native archive also retains available resolved dependency license/notice
files and module metadata, plus MoonBit core's license. After that packaging-only
addition, `cmp` verified the executable still matches the browser-qualified bytes
and the installed-consumer suite passed again.

Machine evidence is `_build/evidence/consumer-macos-arm64.json`, plus browser
`results.json`, `cli-evidence.json`, report, traces and screenshots. No gallery
hashes or output digest manifests were introduced. These archive checksums are
retained for package integrity and installation.

Linux x64 execution remains pending an actual Actions run. The workflows target
Ubuntu 24.04 x64 and macOS 15 arm64, and require both native qualifications before
publication; browser assurance runs once on Linux using the produced CLI.
Actionlint/YAML checks validate definitions, not a successful remote run or timing.
The release gate's pure stale/unmerged/wrong-branch tests passed, but its live
GitHub permission/PR API happy path and actual publication have not run.

The pinned `moon publish --dry-run` exits 255 without credentials.json before it
can package. No dummy or real credential was installed locally. A trusted Actions
preflight checks secret availability as a boolean; current availability remains
unknown. The credential-dependent publication dry run is inside the explicitly
approved Actions publication job. Publication remains blocked until an authorized
owner/admin dispatch identifies the exact main merge SHA, version and merged
release PR, with the required candidate checks and actual credentials available.

No commit, push, publication, archive, downstream edit or task checkbox update
was performed by this worker. The coordinator owns tracker/task integration,
release PR/merge evidence, final diagrams compatibility and all publication or
published-consumer work. Tasks 7.2 onward remain unverified.

The separate actual-diagrams fixture is maintained by another worker and is not
included in these completed checks. `mise run test:diagrams-consumer` is wired
with the same pinned wrapper but intentionally excluded from normal check/CI
because it requires a supplied external checkout. The coordinator must rerun
setup checks after that worker finishes editing its script and fixtures.
