## ADDED Requirements

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
