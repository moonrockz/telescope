# Tasks

## 1. Repair native paths and prove an independent consumer

Bead: telescope-dpa.1

- [x] 1.1 Add failing drive, extended-prefix, UNC and containment regressions and repair native canonicalization, parent and stage names without changing authored relative paths.
- [ ] 1.2 Pass native host fixtures and qualify a prepared package in a fresh consumer without workspace or local-path dependencies; record evidence in host documentation.

## 2. Qualify the Windows host and preserve release gates

Bead: telescope-dpa.2

- [x] 2.1 Add an actual Windows native-host job to PR and release workflows; require it before publication while retaining existing Linux/macOS artifact qualification and permissions.
- [ ] 2.2 Pass format, setup, strict OpenSpec, full engine and browser checks; review against repository and build-master rules and pass Windows CI.
- [ ] 2.3 Update host support documentation with the qualified Windows library scope and keep CLI archive claims tied to existing released platforms.

## 3. Publish the approved patch and verify adoption

Bead: telescope-dpa.3

- [ ] 3.1 Prepare a concrete patch release PR and qualify it; request owner approval for the exact source/version before publication.
- [ ] 3.2 Publish through the owner-approved Actions workflow and record real package, archive and qualification evidence.
- [ ] 3.3 Verify an actual published Windows host consumer before downstream adoption, archive this change in its final evidence PR and close/sync local beads only after merge.
