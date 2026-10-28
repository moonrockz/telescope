# Spec Delta

## Purpose

Let readers inspect complete gallery images and call consumer-provided offline raster conversion without changing supplied artifacts.

## ADDED Requirements

### Requirement: Gallery viewport inspection

Gallery cards and details SHALL offer fixed corner Fullscreen, Zoom in, Zoom out and Fit controls, visible 25 to 800 percent fitted scale, pointer and keyboard pan, and 44 pixel targets. Viewer state SHALL remain independent and SHALL NOT change source, filtering or title navigation.

#### Scenario: Inspect one preview

- **WHEN** a reader zooms and pans a card at 360 CSS pixels then selects Fit
- **THEN** only that preview changes and its complete image returns at 100 percent
- **AND** its title still links to the detail page

### Requirement: Fullscreen fallback and styling

Native fullscreen failure SHALL open an accessible modal fallback and restore focus and page scrolling on exit. Public diagram-viewer root and part classes, namespaced CSS variables and per-instance themes SHALL work inline and expanded.

#### Scenario: Denied fullscreen

- **WHEN** native fullscreen is rejected on a custom-skinned viewer
- **THEN** an expanded modal retains its skin, traps focus and closes with Escape
- **AND** focus and scrolling return to their prior state

### Requirement: Local raster adapter

An optional consumer-supplied local adapter SHALL enable PNG and JPEG downloads from canonical SVG with size, background and quality options and accessible busy or error feedback. Telescope SHALL NOT implement consumer rendering. Original SVG and source actions SHALL remain usable after failure.

#### Scenario: Download and fail

- **WHEN** a consumer adapter exports or rejects an image after zoom and pan
- **THEN** a complete canonical image downloads or an accessible error appears
- **AND** viewport state and original artifact actions remain unchanged

### Requirement: Static and print compatibility

Without scripting, complete previews and links SHALL remain usable and inactive controls SHALL be absent. Printing SHALL show complete untransformed images without toolbars. Theme and deployment tree changes SHALL preserve supplied image bytes and URLs.

#### Scenario: No-script narrow gallery

- **WHEN** the gallery opens without JavaScript at 360 CSS pixels
- **THEN** previews, source and SVG downloads remain available without inactive viewport buttons
