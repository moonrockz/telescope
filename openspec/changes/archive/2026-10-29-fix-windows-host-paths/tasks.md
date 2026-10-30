# Tasks

## 1. Repair native paths and prove an independent consumer

Bead: telescope-dpa.1

- [x] 1.1 Add failing drive, extended-prefix, UNC and containment regressions and repair native canonicalization, parent and stage names without changing authored relative paths.
- [x] 1.2 Pass native host fixtures and qualify a prepared package in a fresh consumer without workspace or local-path dependencies; record evidence in host documentation.

## 2. Qualify the Windows host and preserve release gates

Bead: telescope-dpa.2

- [x] 2.1 Add an actual Windows native-host job to PR and release workflows; require it before publication while retaining existing Linux/macOS artifact qualification and permissions.
- [x] 2.2 Pass format, setup, strict OpenSpec, full engine and browser checks; review against repository and build-master rules and pass Windows CI.
- [x] 2.3 Update host support documentation with the qualified Windows library scope and keep CLI archive claims tied to existing released platforms.

## 3. Publish the approved patch and verify adoption

Bead: telescope-dpa.3

- [x] 3.1 Prepare a concrete patch release PR and qualify it; request owner approval for the exact source/version before publication.
- [x] 3.2 Publish through the owner-approved Actions workflow and record real package, archive and qualification evidence.
- [x] 3.3 Verify an actual published Windows host consumer and record its version, dependency source, host checks and evidence links before downstream adoption.

## Workflow follow-up

- Archive this completed change in the final publication-evidence pull request.
- After merge, close the release story with its PR and merge SHA, close the finished epic and sync this repository tracker.
