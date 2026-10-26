# Telescope

Read README.md and CONTRIBUTING.md before changing this repository.

## Working preferences

- Use compilers, linters, formatters, static analyzers and focused tests for
  issues they determine. Review semantics, architecture, performance,
  concurrency and requirements with reasoning.
- Keep docs/superpowers/ artifacts local. Never stage or commit them. Add that
  path to the repository-local .git/info/exclude if needed, not tracked .gitignore.
- You are not alone in the codebase. Preserve others' edits and keep work within
  the assigned workspace. Do not edit downstream repositories from this one.
- Use pinned mise tools. Development tasks use MoonBit scripts with versioned
  external imports and moonbitlang/async for filesystem and process IO.

## Planning and implementation

- OpenSpec uses the local html-design schema. Proposals include proposal.md,
  design.html, capability specs and tasks.md. Follow generated .agents/skills/.
- Planning does not authorize engine implementation, publication or migration.
- Each numbered tasks.md group has a separate Bead: line. Create repository-local
  beads only after approval. Never inherit Morphir's shared tracker or labels.
- Claim a group's story before work. Close it only after merge with the PR and
  merge SHA. Archive in the last implementation PR. See CONTRIBUTING.md.
- Preserve Apache attribution, source revisions and third-party licenses.
- HTML designs use docs/templates/agent-document.html and its external assets.
  Active changes use ../../../docs/templates/assets/; archives use
  ../../../../docs/templates/assets/. Resolve asset paths on disk.
- Run mise run format, mise run check:setup and
  mise exec -- openspec validate --all --strict before review.
- Run `mise run check` for strict engine verification and `mise run test:browser`
  for actual browser behavior. Qualify packaged installs with
  `mise run test:consumer -- --prepared`; published installs need a real release.
- The reusable native host is published in `moonrockz/telescope/host`. Keep CLI
  entry points thin and register consumer renderers through explicit providers.

## Cross-workspace coordination

This bootstrap belongs to Run run_b3638d9bfa3d. Its coordinator mailbox is
run:run_b3638d9bfa3d. Telescope owns extract-project-site-toolkit; diagrams.mbt
owns adopt-telescope-site and may adopt only an actual published version.
