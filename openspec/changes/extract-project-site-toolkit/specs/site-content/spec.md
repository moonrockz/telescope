## Purpose

Define project content independently of a consumer's domain libraries, with
stable routes and document metadata shared by rendering and checks.

## ADDED Requirements

### Requirement: Validated site configuration
The toolkit SHALL validate project metadata, source roots, navigation and deployment base paths before writing a site, reporting all configuration problems with their source location.

#### Scenario: Invalid configuration
- **WHEN** a configuration has a malformed base path and duplicate navigation entries
- **THEN** validation reports both problems and the build exits unsuccessfully
- **AND** no successful output replaces the previous site

### Requirement: Deployment-relative routes
The toolkit SHALL generate internal page, asset, search and feed URLs under the configured base path without assuming deployment at the domain root.

#### Scenario: Project deployment
- **WHEN** the same content builds at `/` and `/diagrams.mbt/`
- **THEN** internal links resolve within the respective deployment
- **AND** a nested document's relative links and heading fragments resolve correctly

### Requirement: Explicit content discovery boundaries
The toolkit SHALL discover configured public content deterministically, exclude development templates and planning artifacts by default, and reject duplicate output routes.

#### Scenario: Development templates beside public docs
- **WHEN** a project has public docs, `docs/templates/`, `.agents/`, `openspec/` and `docs/superpowers/`
- **THEN** only configured public content enters navigation and search
- **AND** development documents and their assets are absent from public output unless explicitly opted in

#### Scenario: Conflicting sources
- **WHEN** an HTML page and a Markdown page map to the same output route
- **THEN** the build reports both sources and rejects the collision

#### Scenario: Stable consumer resource URLs
- **WHEN** a consumer explicitly maps a project-relative static directory to an output directory
- **THEN** its regular files are copied without byte changes and existing resource URLs resolve under the deployment base
- **AND** development exclusions, declared-root containment and output collision checks also apply to those copies

### Requirement: Markdown and HTML document facts
The toolkit SHALL accept Markdown, HTML fragments and complete HTML pages, preserve explicit heading IDs and relative resources, and derive title, summary, headings and search text without discarding reviewed content.

#### Scenario: Mixed content formats
- **WHEN** content contains Markdown tables, code fences, front matter, an HTML fragment and a complete HTML design page
- **THEN** Markdown and fragments receive the configured shell
- **AND** the complete HTML document keeps its own head and structure without a second shell
- **AND** its referenced local resources remain reachable at the published route

#### Scenario: Repeated and explicit headings
- **WHEN** a document repeats heading text and supplies an explicit heading ID
- **THEN** generated IDs are deterministic and unique
- **AND** the supplied ID remains unchanged and resolves from navigation links

### Requirement: Navigation and source links
The toolkit SHALL support ordered navigation groups, package chapter order, table of contents and source links qualified by a consumer-supplied repository ref.

#### Scenario: Ordered package documentation
- **WHEN** the consumer specifies navigation groups and a package chapter order
- **THEN** sidebars follow that order and mark the current page
- **AND** source links use the configured repository and build ref rather than Telescope's repository
