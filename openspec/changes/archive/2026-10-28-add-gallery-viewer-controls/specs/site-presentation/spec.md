# Spec Delta

## ADDED Requirements

### Requirement: Consumer brand assets

Site configuration SHALL accept optional normalized local output paths for a header logo and favicon. The shared shell SHALL resolve them within the active deployment and version tree. Invalid paths SHALL give configuration diagnostics and absent settings SHALL retain the text brand.

#### Scenario: Versioned brand

- **WHEN** a consumer supplies logo and favicon paths and builds root and next trees
- **THEN** header and favicon URLs resolve inside the respective base paths
- **AND** a consumer without these fields retains its existing text header
