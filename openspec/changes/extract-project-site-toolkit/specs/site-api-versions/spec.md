## Purpose

Provide optional project-neutral API documentation and version-tree behavior
so consumers can adopt Telescope without breaking existing documentation URLs.

## ADDED Requirements

### Requirement: Optional MoonBit API ingestion
The toolkit SHALL accept supported `moon doc` metadata for explicitly selected modules and render package and item pages with doc prose, signatures, heading anchors and source links, without requiring domain packages.

#### Scenario: Existing API fixture
- **WHEN** the adapter reads the diagrams notebooks API fixture and its module and package indexes
- **THEN** package paths, item anchors, doc prose and signatures retain their meaning
- **AND** source links use the consumer repository and supplied build ref

### Requirement: API cross-links and diagnostics
The API adapter SHALL preserve qualified signature links, documentation cross-links, package chapter order and API search entries, and report unsupported metadata shapes and missing prose as explicit diagnostics.

#### Scenario: API signature references another package
- **WHEN** an item signature references a selected package and an external package
- **THEN** selected-package links resolve within the same tree
- **AND** external links remain external and source locations retain their line numbers
- **AND** the item appears in that tree's API search entries

#### Scenario: Unsupported metadata
- **WHEN** a compiler emits an unsupported API metadata shape
- **THEN** ingestion fails with the source file and supported format information
- **AND** it does not emit silently incomplete API pages

### Requirement: Isolated version trees
The optional version adapter SHALL support root, `next/`, `v/<minor>/` and `latest/` trees, preserve each tree's content and search independently, and reject source routes that collide with reserved version prefixes.

#### Scenario: Assembled diagrams deployment
- **WHEN** the consumer supplies checked root, next and release trees under `/diagrams.mbt/`
- **THEN** each tree's docs, articles, API, assets and search resolve within that tree
- **AND** the root and latest selection follow the consumer's supplied release metadata

#### Scenario: Reserved route collision
- **WHEN** a content source claims a top-level `next`, `v` or `latest` route
- **THEN** validation reports the reserved-prefix collision before assembly

#### Scenario: Latest documentation canonical links
- **WHEN** supplied release trees include the same page in the latest release and a canonical site URL is configured
- **THEN** assembled pages without an authored canonical link receive a link to that page under `latest/`
- **AND** next-only or removed pages receive no invented latest canonical link

### Requirement: Version navigation and banners
The version adapter SHALL preserve version selection, static release or unreleased banners, and same-page links across trees with a fallback when the destination page is absent.

#### Scenario: Page missing from older release
- **WHEN** a reader switches from a next-only docs page to an older release
- **THEN** the version control falls back to that tree's docs index rather than a broken page
- **AND** article and other sections use their documented section or home fallback

#### Scenario: No release yet
- **WHEN** the consumer supplies no released documentation tree
- **THEN** root content can show next with an unreleased banner
- **AND** the selector does not invent a release URL

### Requirement: Consumer-owned release selection
The version adapter SHALL assemble supplied checked trees without deciding release policy, fetching git tags, publishing sites or requiring access to another checkout.

#### Scenario: Offline assembly
- **WHEN** a consumer supplies all tree outputs and release metadata without network access
- **THEN** assembly completes using those inputs
- **AND** no tag fetch, checkout mutation or deployment occurs
