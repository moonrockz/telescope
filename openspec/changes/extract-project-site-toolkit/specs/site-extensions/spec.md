## Purpose

Let a consumer add domain pages and generated examples through explicit
contracts while keeping its domain engines outside the toolkit dependency tree.

## ADDED Requirements

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
