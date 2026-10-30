# site-tooling Specification

## Purpose
Give independent projects reproducible site commands and a released dependency
contract that does not depend on the Telescope development workspace.

## Requirements

### Requirement: Independent packaged consumer
The toolkit SHALL support an independent fresh consumer using its packaged library and CLI without sibling workspace members, absolute developer paths or consumer engine dependencies.

#### Scenario: First implementation tracer bullet
- **WHEN** a candidate library and CLI are packaged and installed into a new temporary consumer outside the Telescope checkout
- **THEN** that consumer builds and checks a minimal site from its own content
- **AND** the evidence records the package version and package source
- **AND** no local path dependency or workspace override resolves Telescope

### Requirement: Reproducible build and diagnostics
The build command SHALL produce the same site files from the same declared inputs and report a failed stage, source and nonzero exit status on error.

#### Scenario: Repeated successful build
- **WHEN** a consumer builds the same configuration and content twice
- **THEN** generated file paths and file bytes match
- **AND** the output records the toolkit version and declared extension inputs

#### Scenario: Broken content input
- **WHEN** a source cannot be rendered or an artifact input is missing
- **THEN** the command identifies the failing source and build stage
- **AND** it exits unsuccessfully without advertising a completed site

### Requirement: Built site checks
The check command SHALL verify internal page, asset and fragment links against the built output within its configured deployment tree, with machine-readable and human-readable diagnostics.

#### Scenario: Broken anchor and asset
- **WHEN** generated content links to a missing heading and a missing image
- **THEN** checks report both originating pages and destinations
- **AND** the command exits with a nonzero status

### Requirement: Local preview
The serve command SHALL serve an existing output at the configured base path on loopback, support an explicit port and shut down cleanly without publishing or fetching releases.

#### Scenario: Project-path preview
- **WHEN** the consumer previews a build at `/example/` with an explicit available port
- **THEN** the home page and nested assets load beneath `/example/`
- **AND** a shutdown signal releases the listening port

### Requirement: Published library and CLI contract
The release SHALL provide a library package and matching CLI with the same real semantic version, installation instructions, license notices, CLI checksums and a supported platform list. Publication SHALL require explicit repository-owner approval.

#### Scenario: Publication approval absent
- **WHEN** release artifacts pass validation but the owner has not approved publication
- **THEN** publication remains blocked
- **AND** no downstream adoption is marked ready

#### Scenario: Released consumer qualification
- **WHEN** the owner-approved library and CLI are actually published
- **THEN** a clean consumer pins and installs that exact published version and builds and checks its site
- **AND** it uses no local registry, local path, placeholder version or workspace override
- **AND** release evidence records the registry package, CLI download and verified checksum

### Requirement: Windows native library host paths

The native library host SHALL build, check, preview and assemble sites on
Windows using drive and UNC filesystem paths. Path handling MUST retain
source and output containment, symlink checks and staged promotion. Site URLs
and authored relative-path restrictions MUST retain their existing behavior.

#### Scenario: Windows canonical paths
- **WHEN** a Windows consumer builds and checks content below a drive or UNC root
- **THEN** contained files resolve despite native separators and extended path prefixes
- **AND** generated links use the configured URL base

#### Scenario: Escaping source
- **WHEN** a source resolves outside its declared root on Windows
- **THEN** the host rejects it before copying or promoting output

#### Scenario: Supplied Windows trees
- **WHEN** a Windows consumer assembles checked next and release trees
- **THEN** staging uses a valid sibling directory and preserves binary asset bytes

### Requirement: Windows host qualification gates publication

Release publication SHALL require successful Windows native-host qualification
for the exact candidate in addition to the existing Linux and macOS distribution
checks. A Windows host result MUST NOT imply that Windows CLI archives exist.

#### Scenario: Windows regression
- **WHEN** a candidate's Windows host checks fail or do not finish
- **THEN** the publication job cannot run

#### Scenario: Qualified host
- **WHEN** Windows host checks pass and owner-approved publication succeeds
- **THEN** release evidence identifies the checked source and Windows result
