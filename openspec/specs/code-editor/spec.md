# code-editor Specification

## Purpose

Provide a reusable code editor with MoonBit highlighting and replaceable editing and formatting providers for tutorials, playgrounds and other applications, independent of tutorial content and execution engines.

## Requirements

### Requirement: General code editor component

The library SHALL expose a reusable code editor that can edit and format documents without tutorial models, a course manifest, lesson identity or an execution engine. The component SHALL accept documents, explicit provider registrations and change listeners from its caller. Tutorial workspaces SHALL compose the same component.

#### Scenario: Standalone editor without tutorials
- **WHEN** a consumer mounts a code editor on an ordinary page with a document and formatter
- **THEN** the editor supports editing, formatting and Undo without tutorial configuration or an evaluator
- **AND** its public editor and formatting imports have no dependency on tutorial packages

#### Scenario: Two different editor uses
- **WHEN** a consumer embeds the component in both a standalone playground and a tutorial
- **THEN** both use the same formatter contract and editor behavior
- **AND** each caller independently handles its change events

### Requirement: Independent document state

The code editor SHALL preserve text, selection and undo history independently by editor instance and document identity. Switching documents MUST NOT mix their histories. Consumers SHALL be able to choose plain-text or rich editing through the shared editor contract without changing formatter implementations.

#### Scenario: Switch and undo across editor instances
- **WHEN** a reader edits documents in two editor instances, switches documents and invokes Undo
- **THEN** only the active document's own history is used
- **AND** the other document and editor instance retain their text, selection and history

### Requirement: MoonBit syntax highlighting

The rich code editor SHALL ship MoonBit syntax highlighting selected by the declared language identifiers `moonbit` and `mbt`. It SHALL distinguish keywords, numeric/string/character literals, line and documentation comments, annotations and multiline string lines. Highlighting MUST update during editing, tolerate incomplete source and remain readable in light and dark themes without requiring a formatter, compiler, execution engine or tutorial configuration.

#### Scenario: Standalone MoonBit editor
- **WHEN** a consumer opens a document declared as `moonbit` or `mbt` in the rich editor without a custom language adapter
- **THEN** both identifiers select the shipped MoonBit mode with the same token behavior
- **AND** representative declarations, literals, comments, annotations and `#|` multiline string lines receive syntax styling in either theme
- **AND** no formatter, execution engine or tutorial configuration is needed

#### Scenario: Highlight during an incomplete edit
- **WHEN** a reader edits MoonBit code into an incomplete expression or unterminated literal and then completes it
- **THEN** highlighting updates for both states without an editor failure or a compilation request
- **AND** incomplete token styling does not incorrectly persist after the reader completes the source

### Requirement: Highlighting preserves document state

Syntax highlighting and language switching SHALL preserve exact document text, selection, focus and undo history without emitting a content-change event by themselves. MoonBit documents SHALL retain highlighting when used in a tutorial through the same general editor component. Unknown language modes and the plain-text adapter MUST retain readable, editable source without fabricated language support.

#### Scenario: Switch language and documents
- **WHEN** a reader switches between MoonBit and another declared language or between documents
- **THEN** the rich editor uses the selected document's language mode
- **AND** text, focus, selection and each document's history remain intact without a content-change event caused by highlighting

#### Scenario: Tutorial uses the shared MoonBit mode
- **WHEN** a tutorial supplies a MoonBit file to the shared rich editor
- **THEN** it receives the same highlighting as a standalone editor
- **AND** switching to the plain-text adapter retains the source and editing behavior

### Requirement: Pluggable formatting trait

The code editor SHALL expose an open public trait for consumer-supplied formatting. A formatter SHALL receive the target document, declared language, optional immutable context documents and options, and return formatted text or an explicit error. These types MUST be independent of tutorial models. Consumers SHALL be able to bind formatters by language with per-document overrides.

#### Scenario: Replace the formatter without replacing the editor
- **WHEN** a consumer supplies another implementation of the formatting trait for a declared language
- **THEN** the same editor uses it in both standalone and tutorial contexts
- **AND** no language-specific formatting dependency is required in Telescope

#### Scenario: Per-document formatter override
- **WHEN** a document explicitly selects a formatter different from its declared language's default
- **THEN** formatting uses that document's explicit provider and options

#### Scenario: Optional formatter
- **WHEN** a consumer registers no formatter for a document
- **THEN** the document remains editable without a formatter or execution engine
- **AND** the toolkit does not guess a formatter from its filename

### Requirement: Explicit undoable formatting

The editor SHALL expose a keyboard-accessible Format action only for editable documents with a registered formatter. A changed result MUST apply to its originating document as one undoable edit, preserve a valid selection and emit the normal change event. An unchanged result MUST add no history or change event. Formatting MUST require an explicit action and change only the target document.

#### Scenario: Format and undo a standalone document
- **WHEN** a reader formats a standalone document and the formatter returns changed text
- **THEN** the editor applies one undoable edit and emits its normal document-change event
- **AND** Undo restores the previous text without changing other histories
- **AND** the editor retains focus and a valid selection

#### Scenario: Unchanged formatting result
- **WHEN** formatting returns the document's current text unchanged
- **THEN** undo history and selection remain unchanged and no change event is emitted

### Requirement: Safe formatting lifecycle

The editor SHALL capture document identity, formatter instance and revisions of all formatting inputs, enforce a finite timeout and discard stale results. Edits, document replacement/reset, formatter replacement or disposal MUST invalidate older requests. Errors, malformed results and timeouts MUST preserve text, selection and history, report the failure accessibly and permit explicit retry. Formatting MUST execute locally without blocking the UI.

#### Scenario: Context changes during formatting
- **WHEN** the target or a supplied context document changes before formatting completes
- **THEN** the older result is discarded without replacing current text or moving focus

#### Scenario: Reset, replace or dispose the editor
- **WHEN** a caller resets/replaces the target document, replaces its formatter or disposes the editor during formatting
- **THEN** the old reply cannot change any document or another editor instance

#### Scenario: Formatter fails or times out
- **WHEN** a formatter reports an error, returns an invalid result or exceeds its time limit
- **THEN** current documents, selections and undo histories remain intact
- **AND** the failure is announced without moving focus and the reader can retry explicitly

### Requirement: Explicit editor and formatter registration

Editor and formatter registrations SHALL declare unique identifiers, supported contract versions, supported languages and any browser assets. Unknown references, duplicate identifiers, unsupported versions and incompatible language bindings MUST fail validation before mounting. Browser assets SHALL load only where the corresponding component is used; a standalone editor MUST require no tutorial registration.

#### Scenario: Unsupported formatter binding
- **WHEN** an editor configuration selects an unknown formatter or a language that formatter does not support
- **THEN** validation identifies the binding and supported capabilities before the component mounts

#### Scenario: Ordinary page with an editor
- **WHEN** an ordinary documentation page explicitly embeds the rich editor and a formatter
- **THEN** its declared editor and formatter assets load without a tutorial manifest or lesson engine
- **AND** unrelated pages do not load those assets
