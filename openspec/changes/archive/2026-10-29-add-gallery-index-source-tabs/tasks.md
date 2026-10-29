# Tasks

## 1. Prove an independent candidate consumer

Bead: telescope-elg.1

- [x] 1.1 Package the baseline and run test:consumer -- --prepared outside the workspace, verifying library and CLI use without workspace path overrides; record evidence and prerequisites in the candidate report.

## 2. Implement independent index source inspection

Bead: telescope-elg.2

Depends on group 1.

- [x] 2.1 Reuse source panels on implemented cards with per-entry IDs and exact escaped text, ordered multiple files, labeled filename selection and unavailable-source downloads; verify focused gallery tests and document the source contract.
- [x] 2.2 Enhance each workbench with keyboard tabs and copy feedback, retaining mounted previews; verify browser independence, arrow/Home/End focus, repeated toggles, zoom/pan, filtering, links and fullscreen/export actions.
- [x] 2.3 Add shared card styling and responsive/static coverage; verify no-script reading, both themes at 360/768/1440 widths, clipboard denial, hostile source and active version-tree URLs in browser tests.

## 3. Qualify and release matching distributions

Bead: telescope-elg.3

Depends on group 2.

- [x] 3.1 Prepare matching 0.5.0 module/CLI/package versions, changelog and candidate documentation; verify format, check:setup, check, strict OpenSpec validation and actual browser tests.
- [x] 3.2 Qualify packaged library and CLI in fresh consumers and publisher environment, record exact prepared SHA/version and evidence for owner review; both native platforms must pass CI before publication.
- [x] 3.3 After exact SHA/version owner approval and merged release PR, publish only through GitHub Actions and record real library/CLI coordinates, checksums and public consumer results on both supported platforms.

## Workflow follow-up

- The coordinator owns PRs and merges. Publication requires separate owner approval of the exact merged SHA and version.
- Keep all stories open until merge with PR and merge SHA. The release story remains open through the final publication-evidence PR.
- Archive and sync deltas in that final evidence PR only after actual publication. Close the epic only after every child merges, then sync the Telescope tracker.
