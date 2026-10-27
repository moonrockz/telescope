## Purpose

Provide a configurable static project site presentation that remains useful
without browser scripting and adds optional controls where they help readers.

## ADDED Requirements

### Requirement: Project-neutral static shell
The toolkit SHALL render landing, documentation, article and extension pages with consumer metadata, branding, navigation and footer content, without importing consumer domain engines.

#### Scenario: Unrelated project
- **WHEN** a fresh consumer supplies a different project name, links and landing content
- **THEN** the generated shell contains that project's identity
- **AND** Smithy, Morphir and diagrams branding is absent

### Requirement: Accessible static reading
The toolkit SHALL provide readable page content, semantic navigation, a skip link and heading links before browser scripts run.

#### Scenario: JavaScript disabled
- **WHEN** a reader opens a documentation page with scripting disabled
- **THEN** its content, navigation and table of contents remain usable
- **AND** keyboard navigation reaches the main content through the skip link

### Requirement: Per-tree search
The toolkit SHALL build a deterministic local search index from published pages and enabled API content, with results limited to the current version tree.

#### Scenario: Search on an older version
- **WHEN** the reader searches under `/diagrams.mbt/v/0.2/`
- **THEN** results link to that tree's documents and API items
- **AND** draft, development and other-version content is absent

### Requirement: Theme selection
The toolkit SHALL support light, dark and system themes, apply a stored explicit preference before the first styled paint, and retain readable defaults when storage is unavailable.

#### Scenario: Stored theme with denied storage
- **WHEN** a reader first uses a stored dark preference and later opens a page where storage access throws
- **THEN** the first page applies dark mode before its styled content appears
- **AND** the second page remains readable using the system default without a script failure stopping other controls

### Requirement: Optional browser islands
The toolkit SHALL load only configured browser controls and page-specific extension assets, without requiring a whole-site client application.

#### Scenario: Page-specific workbench
- **WHEN** a consumer registers a workbench script for one route
- **THEN** that route contains its mount point and script
- **AND** ordinary documentation pages do not load the workbench assets

### Requirement: Articles and feeds
The toolkit SHALL render dated articles and a feed using configured metadata and deployment URLs, excluding drafts in release builds.

#### Scenario: Release feed
- **WHEN** a release build includes one published article and one draft
- **THEN** the article index and feed contain only the published article
- **AND** its feed URL uses the configured canonical site URL
