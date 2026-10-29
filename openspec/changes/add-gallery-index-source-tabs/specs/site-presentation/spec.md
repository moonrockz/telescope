## ADDED Requirements

### Requirement: Independent gallery index inspection

Implemented gallery index cards SHALL provide independent accessible Preview/Source tabs with unique relationships. Source SHALL offer labeled filename selection, exact escaped text when available, copy and download actions. Tabs SHALL retain mounted preview state. Without scripting both sections SHALL remain readable. Planned entries SHALL retain their explicit placeholder.

#### Scenario: Independent keyboard inspection

- **WHEN** a reader selects Source on one index card with click, arrows, Home or End
- **THEN** only that card changes selected panel with correct tab roles, relationships and roving focus
- **AND** returning to Preview preserves its viewer instance, zoom and pan
- **AND** each card retains its selected filename across tabs and filters
- **AND** filtering, detail links, fullscreen and export remain usable

#### Scenario: Multiple exact declared sources

- **WHEN** a card declares multiple sources containing whitespace, markup, quotes and literal URLs
- **THEN** each file is labeled and its text and copy match the supplied source exactly
- **AND** source text cannot execute markup or change version-tree URLs
- **AND** unavailable inline source retains an explicit message and labeled artifact download
- **AND** clipboard denial leaves selection and download available

#### Scenario: Static source and responsive themes

- **WHEN** JavaScript is disabled or either theme is viewed at 360, 768 or 1440 CSS pixels
- **THEN** source and preview remain reachable without horizontal page scrolling
- **AND** wide source scrolls within its own panel
- **AND** shared styling hooks support consumer customization
