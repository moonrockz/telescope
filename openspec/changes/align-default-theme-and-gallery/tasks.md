# Tasks

## 1. Prove the shared palette and specimen path in an independent consumer

Bead: telescope-iqz.1

Acceptance: A fresh packaged consumer outside the workspace uses Smithy-aligned colors and renders one gallery card and detail with its static source and downloads. No sibling source dependency is needed.

- [x] 1.1 Map shared default CSS tokens to the pinned Smithy reference and document the mapping and source attribution; verify rendered light, dark and system palette values in the browser.
- [x] 1.2 Render one preview card and a preview/source detail through the pure gallery planner and verified host inputs; add focused behavior tests for source escaping, unchanged routes and artifact bytes, and optional planner input compatibility.
- [x] 1.3 Package the library and matching CLI and run `mise run test:consumer -- --prepared`; verify the independent candidate consumer sees the same palette and specimen assets from both distributions.
- [x] 1.4 Update the gallery and presentation docs for this path and run format, setup, engine and focused browser checks; record the candidate result as packaging evidence, not publication.

## 2. Complete the visual gallery and browsing controls

Bead: telescope-iqz.2

Acceptance: Cards, family selection, text filtering, counts and reset work for multiple families and support states, with static fallback and stable family links.

- [x] 2.1 Complete responsive grouped cards, bounded previews, supplied theme variants and planned placeholders; verify fixture pages at 360, 768 and 1440 CSS pixels in light and dark themes without cropping diagrams.
- [x] 2.2 Add gallery-only filtering for title, family and description, combined family selection, polite result counts and reset; verify matching, empty state and stable focus through real browser interactions.
- [x] 2.3 Preserve existing family fragment IDs, direct-link initialization and back/forward behavior; verify both enhanced navigation and no-script anchors at root and project base paths.
- [x] 2.4 Document browsing and fallback behavior and add the required browser cases; verify a consumer without a gallery has no gallery controls or active gallery behavior.

## 3. Complete accessible preview and source inspection

Bead: telescope-iqz.3

Acceptance: Readers can inspect supported text sources, switch panels and use downloads and optional player links. All content remains available without scripting.

- [x] 3.1 Complete host-read source panels for multiple supported UTF-8 text artifacts and labeled download fallback for other sources; verify literal display, no script execution, existing containment checks and byte-identical downloads.
- [x] 3.2 Enhance static detail sections with accessible Preview/Source tabs and keyboard navigation; verify selected state, arrow/Home/End behavior, no-script visibility and narrow panels in browser tests.
- [x] 3.3 Add source copy feedback and clipboard-denied fallback while retaining explicit source/SVG downloads and a separate player link; verify each action against actual fixture artifacts.
- [x] 3.4 Document the optional pure planner input, source support and accessibility behavior; verify generated interfaces, measured text/control/focus contrast, reduced motion and both theme override directions.

## 4. Qualify and release the shared update

Bead: telescope-iqz.4

Acceptance: Full checks pass, and an owner-approved Actions release provides a real library and matching native CLI verified through public consumers on both supported platforms.

- [x] 4.1 Run format, setup, strict OpenSpec validation, engine, browser and independent packaged-consumer qualification; record final candidate source revision and results, including no-gallery and versioned consumers.
- [x] 4.2 Prepare version and changelog updates and release notes for a concrete owner-reviewed release PR; verify matching library/CLI versions and existing release gates before requesting publication approval.
- [ ] 4.3 After explicit release approval, publish only through GitHub Actions and run actual public-consumer checks on Linux x64 and macOS arm64; record version, source revision, archive URLs and checksums and both consumer reports.
- [ ] 4.4 Send verified release evidence to the diagrams coordinator mailbox and record acknowledgement; verify the downstream pins refer to those public artifacts and complete release documentation in the final PR.

## Workflow follow-up

- Approval creates one local epic and four stories. Add dependencies between groups and keep cross-workspace coordination in `run:run_b3638d9bfa3d`.
- Archive in the last implementation PR, repair relative HTML links and sync accepted specifications there.
- Close stories only after their PR merges, with PR and merge SHA; close the epic only when every child is closed, then pull and push the local tracker.
- Proposal approval does not authorize publication. Seek release approval for the concrete version and commit.
