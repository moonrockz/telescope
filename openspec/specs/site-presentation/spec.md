# site-presentation Specification

## Purpose
Provide a configurable static project site presentation that remains useful
without browser scripting and adds optional controls where they help readers.

## Requirements

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

#### Scenario: Enabled gallery navigation
- **WHEN** a consumer supplies a gallery manifest
- **THEN** the shared header links to that tree's gallery from landing, docs, articles and API pages
- **AND** gallery index and detail pages identify Gallery as the current primary link

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

### Requirement: Smithy-aligned default palette

The default shell SHALL use Smithy's indigo accents and cool neutral light and dark surfaces across landing, docs, articles, API and gallery pages. Explicit light and dark selection and system fallback MUST use the same palette mapping. Text, controls and focus indicators MUST retain accessible contrast.

#### Scenario: Default palette across page types

- **WHEN** an uncustomized consumer builds landing, docs, article, API and gallery pages
- **THEN** light mode uses background `#f9fafb`, surface `#ffffff`, text `#111827` and accent `#4f46e5`
- **AND** dark mode uses background `#0f1014`, surface `#17181f`, text `#e5e7eb` and accent `#a5b4fc`
- **AND** normal text meets a contrast ratio of at least 4.5:1 and essential control boundaries and focus indicators meet at least 3:1 against adjacent surfaces

#### Scenario: Explicit theme overrides the operating system

- **WHEN** a reader selects light mode on a dark system or dark mode on a light system
- **THEN** all default shell colors use the selected palette before the first styled paint
- **AND** denied preference storage retains a readable system palette without breaking other controls

### Requirement: Gallery browse controls

An enabled gallery SHALL offer local text filtering and family selection as progressive enhancements. Filtering MUST combine the selected family with a case-insensitive match on title, family and description. It SHALL report the number of matches and offer a clear reset when no examples match. Core example links MUST work without these controls.

#### Scenario: Combine family and text

- **WHEN** a reader selects a family and enters text in the gallery filter
- **THEN** only matching cards in that family remain visible
- **AND** a result count is announced without moving keyboard focus
- **AND** no network search or renderer execution is required

#### Scenario: No matches

- **WHEN** no card matches the active filters
- **THEN** a visible empty state provides an accessible reset action

#### Scenario: No JavaScript

- **WHEN** JavaScript is unavailable
- **THEN** all cards, family anchors and detail links remain available, with no inactive filtering controls

### Requirement: Accessible gallery inspection controls

Enhanced example pages SHALL offer keyboard-operable Preview and Source controls with correct selected state and focus behavior. The Source view SHALL show the supplied text and provide copy and download actions. Without JavaScript both preview and source content MUST remain available. Clipboard denial MUST leave selectable source and downloads usable.

#### Scenario: Inspect and copy a source with the keyboard

- **WHEN** a reader uses the keyboard to switch between Preview and Source
- **THEN** the selected control and panel are identified programmatically and arrow keys follow the tab order
- **AND** the source text and download match the supplied artifact
- **AND** copy succeeds with feedback or leaves a clear fallback when clipboard access fails

#### Scenario: Static and narrow example inspection

- **WHEN** scripting is disabled or the viewport narrows to 360 CSS pixels
- **THEN** the preview, source, scope statement and downloads remain reachable
- **AND** page controls do not require horizontal page scrolling
- **AND** any motion respects the reader's reduced-motion preference
