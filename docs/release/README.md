# Release procedure

Telescope 0.2.1 is published. [Install and compatibility evidence](0.2.1.md)
records actual pins, CLI downloads, checksums and both clean public consumers.
The owner-approved [release run](https://github.com/moonrockz/telescope/actions/runs/40594390130)
published source `1f84c6c8de780ea9322db6eef14c10395a4670f9` after PR 8 merged.
Only an approved GitHub Actions release job may publish a new version.
The preceding [0.2.0 release](0.2.0.md) retains its source and public reports.

The earlier [0.1.1 release](0.1.1.md) and [0.1.0 release](0.1.0.md) retain their
actual source identities and installation reports. The following initial-release
repair history explains the publisher's current behavior.

The [first approved attempt](https://github.com/moonrockz/telescope/actions/runs/40449781959)
passed native/browser qualification, credential availability and the live
owner/admin approval gate, then failed while locating its downloaded library
ZIP. Neither publication step ran. Multi-path artifact upload retains `publish/`,
`package/` and `evidence/` directories. The publisher must read the library from
`release-<platform>/publish/` and CLI files from `release-<platform>/package/`.
The repair was checked against the actual downloaded Linux/macOS artifacts:
both native checksums and ZIP integrity checks pass, and the extracted Linux
library passes strict native compilation. A fresh source compatibility run also
preserves all 77 diagrams routes, 5,376 anchors and 40 artifact copies.

The [second approved attempt](https://github.com/moonrockz/telescope/actions/runs/40458124684)
extracted those artifacts successfully, then its publication dry run failed
because the temporary Moon home had no dependency registry. No upload ran.
The publisher now links the qualified toolchain's registry into that home.
`mise run test:publish-environment`, after `mise run package`, uses the same home
preparation to package the actual qualified ZIP without creating credentials.
Both PR and release qualification run this check before promotion.

The [third approved attempt](https://github.com/moonrockz/telescope/actions/runs/40461111541)
passed packaging and the server accepted its dry run for `moonrockz/telescope@0.1.0`
with HTTP 202 and an explicit statement that no changes were made. The pinned CLI
nevertheless exited unsuccessfully, so no real upload ran. The publisher accepts
that exact receipt only for a dry run of the requested module/version. Conflicting
statuses, other versions, cancellation and real publication failures remain errors.

Fresh published consumers initialize their empty registry from the public index
before resolving the exact version. `mise run test:consumer-environment` checks
that bootstrap using a real public dependency and no credentials, candidate cache
or workspace override. PR and release qualification run it before packaging.

PR CI qualifies the exact source on Linux x64 and macOS arm64. Each job runs setup
validation, all-target pure checks, strict native compilation and native tests,
then builds one native artifact and consumes that same archive in a clean
consumer. The two platforms cover different executable, filesystem and installer
risks and both block release. The first successful run took 2m50s on Linux and
1m56s on macOS. No nightly-only checks replace these release obligations.

The manual Release candidate workflow defaults `publish` to false. It repeats
qualification on both platforms, validates both module versions against the CLI
candidate version, and packages and installs the candidate artifacts. The
credential-dependent `moon publish --dry-run` runs only inside the approved
publication job immediately before publication. Any
failed, missing, cancelled or unfinished matrix job prevents the publication job
through `needs`. Uploaded artifacts are retained for 30 days and consumed in the
same run. An older successful run cannot satisfy a new candidate.

Before publication, a repository owner or authorized repository admin must
explicitly approve a manual workflow dispatch for the exact source SHA and
version. Set `publish` true, type that SHA into `approved_sha`, and supply the
release PR URL in `release_pr`. The release gate crosschecks these values against
the GitHub event inputs, verifies that the actor has repository admin authority,
requires main, and verifies the release PR is merged to main with its merge SHA
matching the approved source commit. This
supports owner-authored PRs, which cannot receive their author's GitHub APPROVED
review. Dispatching a default dry run grants no publication approval.

The workflow also names a `release` environment. Configure owner reviewers and
protected release branches before publication if that second gate is desired.
The environment name alone does not prove protection; its settings have not been
verified or changed by this implementation.

A trusted publication preflight checks only whether `MOONCAKES_USER_TOKEN` is
available as an Actions secret, using a boolean expression. The approved release
preflight and publication passed, confirming availability without exposing the
credential. Organization secret metadata was not inspected or changed.
PR jobs receive no publication credential. The publish script refuses a
workstation, rechecks the manual owner/admin approval, creates a temporary Actions-only Moon home
with a mode-0600 credential file and deletes it afterwards without printing the
credential. It publishes from the tested library ZIP's extracted source. CLI
archives are promoted directly from the qualification jobs.

Publication can partially succeed. If Mooncakes publication succeeds but GitHub
release creation or published consumer qualification fails, report the partial
state and keep adoption blocked. Do not overwrite a published version or rerun
blindly. Inspect actual coordinates and recover under a new explicit owner
decision. Both library and CLI must exist at the same real version and pass
published qualification before downstream adoption.

Required final evidence is the owner/admin dispatch URL, release PR and approved source SHA,
Mooncakes coordinate, CLI archive URLs and verified checksums, both native
platform results, API/version compatibility fixtures and the published consumer
report. The 0.1.0 events and reports are recorded in the version-specific evidence.
Do not archive this change or close its beads before the coordinator's final
integration and merge gates.

Candidate CI passes on both platforms, including archive consumption and Linux
browser qualification. Failure propagation uses direct job relationships. The
owner/admin gate API happy path and actual publication also passed in run 40520332727.

The approval mechanism follows [GitHub review and environment semantics](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments).
The credential file follows [MoonBit's package publication contract](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html).

The pinned Moon CLI checks for credentials before honoring `moon publish
--dry-run`. Its local dry run currently exits 255 because no credential file
exists. No dummy credential was created to bypass that check. Default candidate
qualification uses `moon package`, archive/checksum creation and independent
consumer installation. The credential-dependent publication dry run is inside
the explicitly approved publication job immediately before publication.

Browser qualification runs once on Linux within the producing job, after the
native binary exists. It covers JS/browser behavior independently of the second
native platform's installation qualification. Browser JSON reports, traces and
screenshots upload even after a failure; failed candidates never upload a
promotable release artifact. The macOS matrix uses `macos-15` because GitHub is
[retiring macOS 14 runners](https://github.blog/changelog/2026-10-01-github-actions-macos-14-runner-image-retirement/).
`actionlint` and yamllint mechanically check the workflow definitions.
