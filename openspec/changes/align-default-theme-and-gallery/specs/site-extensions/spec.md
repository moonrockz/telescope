## ADDED Requirements

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
