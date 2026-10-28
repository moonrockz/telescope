# Standardize tutorial components

## Why

Smithy's language tour already combines authored lessons, an editable workspace and checked teaching examples. Telescope consumers currently have to reproduce that infrastructure to offer a tutorial, even though the language-specific execution belongs to their own projects.

## What Changes

- Add an optional, standard tutorial feature composed of reusable content, workspace and verification components. A consumer can use static lessons without an editor or execution engine.
- Define a versioned TOML tutorial manifest for ordered courses, stable lesson routes, sections, prose, references, starting files and named cases. Support comments and explicit tables for authoring. Include tutorial pages in the shared navigation, search, source links and version trees.
- Provide multi-file editing, independent file histories, diagnostics and output panels, reset, saved edits, pane expansion and changed-output highlighting. Support comparison groups and step-through results through consumer-declared capabilities.
- Add a reusable code editor component for tutorials, playgrounds and other pages. It owns the open public Formatter trait, provider bindings, undoable formatting and stale-result protection. Consumers select formatters per file or language without depending on tutorial models or execution engines.
- Ship MoonBit syntax highlighting in the rich code editor, selected by `moonbit` or `mbt`, for standalone and tutorial use. Preserve text, selection and histories while highlighting updates during edits or language switches.
- Define explicit tutorial execution and editor contracts. Consumers supply prebuilt browser assets and optional compiled check adapters; Telescope supplies lifecycle and presentation. Smithy-specific engines, severity rules, output formats, serialization profiles and playground URLs remain consumer-owned.
- Add deterministic case checking and tested source-region includes, with source-aware text/JSON diagnostics. Consumer checks can add pinned reference comparisons without putting Java, Smithy or Morphir into Telescope.
- Qualify the components in a fresh consumer using a small unrelated engine. Record Smithy parity against its main checkout and the related codec workspace, without migrating either workspace in this change.
- Keep tutorial configuration opt-in and existing extension contract version 1 valid. Qualify a packaged candidate before an explicitly owner-approved release; downstream adoption follows actual publication.

## Capabilities

### New Capabilities

- `site-tutorials`: Optional tutorial content, validated manifests, ordered course navigation, stable routes and static reading within the active deployment tree.
- `code-editor`: General editor composition, MoonBit highlighting, independent document histories, an open formatter trait, explicit provider bindings and safe undoable formatting, usable without tutorials.
- `site-tutorial-workspaces`: Interactive lessons composed with the shared code editor, resilient execution, scoped saved edits and capability-driven comparison and step-through views.
- `site-tutorial-checks`: Named case verification and tested source includes, with explicit consumer ownership of domain execution and reference evidence.

### Modified Capabilities

- `site-extensions`: Add versioned tutorial execution registration and composition with the general code editor's registrations, separate from the existing page/fence/island contract.

## Beads

- **Tracked by**: telescope-58o, with one Telescope-local child story per numbered task group. Implementation approved on 2026-10-27; publication remains separately gated.
- **Related**: No dependent Telescope change is active. Smithy's `add-versioned-json-codecs` is a read-only compatibility reference. Any Smithy adoption needs a separate proposal in its own repository after publication.

## Impact

The implementation would add general editor packages under `pkgs/telescope/editor/` and tutorial packages under `pkgs/telescope/tutorial/`, integrated with `model`, `content`, `site`, `views`, `host`, packaged assets and the thin CLI. It would add a pinned MoonBit TOML parser, extend consumer and Chromium fixtures, document authoring and provider contracts, and update attribution for adapted Smithy code. Rich editing may add pinned CodeMirror dependencies to an optional browser bundle, loaded only by pages that explicitly use it.

The source inventory in `design.html` pins Smithy main at `caa78a677b88fdf506eb77953453d2519f1f4786` and its codec workspace at `e3c140d11dba72b5f642c1e634bd94ec4adc2c94`. Implementation and PR merges were approved on 2026-10-27. Publication and downstream edits remain outside that approval. Existing 0.2.1 consumer configuration and extension registration remain valid; any necessary public MoonBit source changes require an explicit compatibility decision before implementation.
