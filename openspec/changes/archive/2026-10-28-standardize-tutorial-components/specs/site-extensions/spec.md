# Tutorial extension contracts

## ADDED Requirements

### Requirement: Explicit tutorial provider registration

Tutorial execution providers SHALL use explicit versioned registrations with unique identifiers and declared capabilities. Tutorial editor configuration SHALL use the general code editor's editor and formatter registrations. Unknown references, duplicate identifiers, unsupported versions and undeclared operations MUST fail validation before output promotion. Existing page, fence and island registrations MUST remain valid without tutorial registrations.

#### Scenario: Unsupported operation
- **WHEN** a lesson requests stepping from a provider that declares only evaluate
- **THEN** validation names the lesson, provider and unsupported operation
- **AND** no successful output replaces the previous site

#### Scenario: Existing extension consumer
- **WHEN** a consumer passes only its existing version-one page, fence and island registry
- **THEN** its adapters continue to work without new required registry fields or tutorial setup

### Requirement: Domain-neutral tutorial execution

Tutorial providers SHALL receive the current virtual files, declared operation and consumer options, and return versioned results containing diagnostics, outputs, blocked reasons or step progress. Consumers SHALL own language semantics, severity-to-blocking decisions, engine options, reference tools and external workbench encoding. Telescope MUST remain usable without importing those engines.

#### Scenario: Non-Smithy engine
- **WHEN** an unrelated project registers a small text-processing engine
- **THEN** the same tutorial components render and execute its lessons
- **AND** no Smithy file suffix, shape identifier, output enum, reference domain or branding is required

#### Scenario: Consumer-defined serialization profile
- **WHEN** a provider accepts a profile option with domain-specific validation rules
- **THEN** the consumer validates and interprets that option
- **AND** Telescope does not add the profile or its conflicts to the common lesson schema

### Requirement: Declared tutorial asset execution

Tutorial browser assets SHALL be explicit contained build inputs, loaded only on lessons that use them. Site builds MUST NOT discover packages or load consumer modules as native code. Browser checking SHALL execute locally without sending lesson files to a remote service. A page MUST NOT load editor, formatter or execution assets unless it explicitly uses the corresponding component.

#### Scenario: Stock CLI with prebuilt assets
- **WHEN** a manifest supplies an explicitly registered runtime and its prebuilt browser assets
- **THEN** the stock CLI validates and copies them without executing the engine
- **AND** only interactive lessons referencing that runtime load them in the browser

### Requirement: Composable tutorial components

The library SHALL expose tutorial content planning, workspace state and views, and case comparison independently of the stock CLI. Consumers SHALL be able to compose these through the reusable host and supply compatible editor or execution adapters without copying the site host or replacing tutorial navigation and verification.

#### Scenario: Consumer-built driver
- **WHEN** an independent consumer imports the public host and tutorial contracts and registers its own evaluator and editor
- **THEN** it builds, checks and presents lessons using the shared tutorial components
- **AND** it requires neither sibling workspace membership nor copied Telescope host code
