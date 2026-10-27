# site-extensions Specification

## Purpose
Let a consumer add domain pages and generated examples through explicit
contracts while keeping its domain engines outside the toolkit dependency tree.

## Requirements

### Requirement: Explicit extension registration
The toolkit SHALL accept explicitly registered page, code-fence and browser-island adapters through a versioned contract, rejecting duplicate identifiers and unsupported contract versions before output generation.

#### Scenario: Adapter contract mismatch
- **WHEN** a consumer registers an adapter with an unsupported contract version
- **THEN** validation names the adapter and supported versions
- **AND** no plugin discovery, remote loading or arbitrary package execution is attempted

### Requirement: Domain ownership
The toolkit SHALL operate without diagram parsers, diagram renderers or domain workbench engines. A consumer SHALL provide domain output and retain responsibility for its generation and validity.

#### Scenario: Diagram code fence
- **WHEN** a consumer provides a fence adapter for a diagram language
- **THEN** the adapter supplies a result through the documented contract
- **AND** Telescope neither reimplements the language nor silently substitutes another renderer

#### Scenario: Unsupported fence
- **WHEN** a document contains a language fence with no registered adapter
- **THEN** it remains an escaped code block
- **AND** the toolkit does not claim diagram support

### Requirement: Gallery artifact manifest
The toolkit SHALL accept a versioned gallery manifest with stable unique ID, family, title, support status, source artifact references and an SVG preview for each implemented entry, plus an optional offline HTML player.

#### Scenario: Implemented example
- **WHEN** an implemented entry names existing source, SVG preview and offline player files
- **THEN** the gallery presents its title, family, support status, source downloads, preview and player link
- **AND** the supplied files retain their bytes and offline behavior

#### Scenario: Browse a family and download a preview
- **WHEN** a reader opens the gallery without browser scripting
- **THEN** family links lead to grouped examples and each detail links back to its family
- **AND** SVG previews have explicit download links in the active version tree

#### Scenario: Planned format
- **WHEN** an entry is marked planned without generated artifacts
- **THEN** it is visibly identified as planned and has no fabricated preview or player
- **AND** planned general PlantUML diagrams, DOT or Draw.io are not presented as implemented

### Requirement: Artifact validation
The toolkit SHALL reject missing artifacts, duplicate gallery IDs, unsupported statuses, manifest-version mismatches, and paths or symlinks that escape the artifact or output root before copying files.

#### Scenario: Missing SVG and escaping path
- **WHEN** a manifest names a missing SVG and a source path escaping the declared artifact root
- **THEN** validation identifies both entries and paths
- **AND** the build exits unsuccessfully without copying outside the output tree

#### Scenario: Redirected artifact
- **WHEN** a symlink resolves outside the artifact root
- **THEN** validation reports the resolved path escape
- **AND** the gallery build fails before copying that artifact

### Requirement: Gallery support status fidelity
The toolkit SHALL preserve a consumer's declared implemented and planned statuses, without inferring support from file extensions or a family label.

#### Scenario: Diagrams gallery
- **WHEN** a manifest declares sequence, BPMN, swimlane, regex, EBNF, JSON and YAML examples implemented and other format families planned
- **THEN** their status remains explicit in the generated gallery
- **AND** no renderer capability is attributed to Telescope itself

### Requirement: Preview card gallery

The gallery SHALL present supplied examples as responsive preview cards with a consistent preview frame, title, family and support label. Each card SHALL link to its stable detail route. Available theme variants MUST select the appropriate supplied SVG without cropping diagram content. Planned entries MUST remain clearly labeled without fabricated previews.

#### Scenario: Compare examples in either theme

- **WHEN** a reader browses a gallery with implemented and planned entries in light or dark mode
- **THEN** implemented cards show their supplied preview in a bounded frame with its aspect ratio preserved
- **AND** planned entries use an explicit text placeholder
- **AND** every card links to its stable detail page

#### Scenario: Static family navigation

- **WHEN** the reader follows an existing family anchor with JavaScript disabled
- **THEN** the corresponding family heading and its preview cards remain reachable
- **AND** existing family anchors, example routes and artifact URLs remain valid

### Requirement: Preview-first example detail

Each example detail SHALL prioritize its preview and expose its title, family, support status, scope and supplied sources. Implemented examples SHALL provide explicit SVG and source downloads and a separate link to any supplied offline player. The gallery MUST preserve source and preview bytes and MUST NOT execute consumer renderers to display an example.

#### Scenario: Inspect an example with several sources

- **WHEN** an entry supplies multiple text sources, light and dark SVGs and an optional player
- **THEN** each source is identified and inspectable, each supplied SVG has a download link, and the player opens through its own link
- **AND** a family backlink stays within the active base path and version tree
- **AND** each downloaded artifact is byte-identical to the input

#### Scenario: Non-text source

- **WHEN** a supplied source media type is not supported for inline text inspection
- **THEN** the page identifies that source and provides its download without attempting to render it as markup
- **AND** other available sources, previews and downloads remain usable

#### Scenario: Read source text safely

- **WHEN** a text source contains markup or script-like text
- **THEN** the Source view displays that text literally without executing it
- **AND** the unchanged source remains downloadable

#### Scenario: Existing version-one consumer

- **WHEN** an independent consumer supplies a valid manifest with schema version 1 and no new fields
- **THEN** the updated gallery builds with the shared library and matching CLI
- **AND** a consumer that does not configure a gallery has no gallery controls or gallery-specific behavior
