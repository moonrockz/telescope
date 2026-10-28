# Site tutorial checks

## Purpose

Keep tutorial examples reproducible through deterministic named cases and source-region includes tied to explicit consumer test evidence.

## ADDED Requirements

### Requirement: Deterministic lesson cases

Every executable lesson SHALL declare a start case and unique named cases whose file overlays replace or add files by normalized virtual name. Checking SHALL evaluate cases independently in deterministic order against the declared provider and options. Static lessons MUST NOT require executable cases.

#### Scenario: Overlay isolation
- **WHEN** one case replaces a starting file and adds another file
- **THEN** that case receives exactly those merged files
- **AND** the start case and later cases receive no leaked file or runtime state

### Requirement: Observable result expectations

Case checks SHALL compare declared complete diagnostic keys, output substrings, blocked reasons, verdicts and step results against normalized execution results. Duplicate diagnostic keys MUST retain their multiplicity. Empty output needles, incompatible expectations and unsupported assertions MUST fail explicitly. A domain-negative case SHALL pass when its expected diagnostics match.

#### Scenario: Teaching an invalid input
- **WHEN** a case expects an error diagnostic and the provider returns exactly that diagnostic
- **THEN** the case passes even though the lesson input is invalid
- **AND** an unexpected additional diagnostic or missing duplicate causes a mismatch

#### Scenario: Blocked output and steps
- **WHEN** a case declares a blocked reason or a step-position expectation
- **THEN** checks require that actual state and its declared text or findings
- **AND** a successful output or an unsupported step assertion cannot pass in its place

### Requirement: Checked source-region includes

Lessons SHALL be able to include labeled source regions as static-readable code groups. Each region MUST resolve uniquely inside a declared root and be covered by an explicit consumer test-source policy. Missing, duplicate, malformed or unapproved regions MUST fail with the lesson and source location. Rendering MUST NOT execute included commands.

#### Scenario: Tested CLI and API tabs
- **WHEN** a lesson includes two labeled regions that the consumer's CLI and API test policies cover
- **THEN** both regions display their exact code text, language and source reference
- **AND** both remain readable without scripting and do not execute during a site build

#### Scenario: Apparently executable but untested block
- **WHEN** a region contains a command fence but has no matching consumer test-source declaration
- **THEN** inclusion fails rather than labeling the block as tested from its language alone
- **AND** consumer-configured guards can reject hand-written CLI or API examples outside includes

### Requirement: Honest verification reporting

The tutorial checker SHALL report case identity, provider identity and version, input revision, assertion mismatches and unavailable checks in text and machine-readable forms. A missing evaluator, failed evaluator or stale required evidence MUST cause an unsuccessful check. A build-only render MUST NOT claim that tutorial cases passed.

#### Scenario: No native evaluator
- **WHEN** the stock CLI renders a lesson with prebuilt browser execution assets but no compiled case evaluator
- **THEN** its build can succeed after structural validation without a case-pass claim
- **AND** a request to execute its cases fails explicitly until an evaluator is supplied

#### Scenario: Required evidence is stale
- **WHEN** supplied required check evidence describes an older input revision
- **THEN** the checker reports the stale evidence and exits unsuccessfully
- **AND** it does not rewrite expectations or substitute a successful report

### Requirement: Consumer-owned reference comparisons

Consumers SHALL be able to attach additional reference checks to normalized case results. Reference evidence MUST identify its source revision and covered input revision. Any declared differences MUST retain the consumer's reason and tracking reference. Telescope MUST NOT require a particular language reference tool or silently remove differences.

#### Scenario: Pinned external reference
- **WHEN** a consumer supplies reference results and a documented difference for a case
- **THEN** its registered comparison can report agreement or the explicit remaining differences alongside the case result
- **AND** the report retains the pinned reference identity and does not attribute domain conformance to Telescope itself
