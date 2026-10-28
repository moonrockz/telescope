# site-tutorial-workspaces Specification

## Purpose

Provide a reusable browser workspace for interactive lessons while consumers retain ownership of the language engine and its meaning.

## Requirements

### Requirement: Independent file editing

An interactive workspace SHALL expose the lesson's starting files by name, declared language and optional group. Switching files MUST preserve each file's text, selection and undo history independently. The workspace MUST NOT infer an execution engine from a file extension.

#### Scenario: Switch and undo
- **WHEN** a reader edits one file, switches to a second file and invokes Undo there
- **THEN** only the second file's own history is used
- **AND** switching back restores the first file's edited text and selection

### Requirement: Scoped saved edits and reset

Saved edits SHALL be scoped to the site, deployment tree, course and lesson, and accepted only for the same starting-file revision and file identities. Reset SHALL restore starting files, clear their saved edits and histories, and request fresh results while retaining pane layout. Unavailable or invalid storage MUST leave in-memory editing usable.

#### Scenario: Updated or different course
- **WHEN** stored edits belong to another base path, version, course or starting-file revision
- **THEN** they are not applied to this lesson
- **AND** a changed lesson starts from its declared files

#### Scenario: Storage denied and reset
- **WHEN** storage access throws and the reader edits files and presses Reset
- **THEN** editing remains usable and Reset restores all starting texts and file histories
- **AND** the active pane layout is retained

### Requirement: Shared code editor integration

Tutorial workspaces SHALL compose the general code editor and its formatting contract. Applied formatting SHALL enter normal lesson edit handling for persistence, result invalidation, rechecking and step replay. An unchanged result MUST cause no storage write or check. Reset MUST invalidate pending editor formatting. Formatting MUST NOT rewrite starting fixtures, case expectations or output text.

#### Scenario: Format and undo a lesson file
- **WHEN** the shared editor applies changed formatting to a lesson file
- **THEN** the workspace persists the edit and rechecks the current lesson revision
- **AND** Undo restores the previous text through the same normal lesson edit handling
- **AND** the editor uses the same formatter trait as an editor outside tutorials

#### Scenario: Unchanged formatting result
- **WHEN** the shared editor returns the file's current text unchanged
- **THEN** the workspace creates no storage update or additional lesson check

#### Scenario: Lesson reset during formatting
- **WHEN** a reader resets the lesson before its formatting request completes
- **THEN** the editor invalidates the older result and the starting files remain intact

### Requirement: Current-revision results

The workspace SHALL debounce edits, bound concurrent work and display execution results only for the current file revision and active runtime instance. Edits or Reset during execution MUST invalidate older replies and schedule the newest revision. Diagnostic and output panels MUST identify pending, successful, blocked and failed execution distinctly.

#### Scenario: Slow reply after another edit
- **WHEN** a reply arrives after the reader has edited or reset the lesson files
- **THEN** the old reply cannot replace the current diagnostics, output or step progress
- **AND** the newest revision is checked once pending work can run

### Requirement: Bounded execution recovery

The workspace SHALL enforce a finite execution timeout, restart a failed runtime when recovery is possible and retry a timed-out revision at most once automatically. A second timeout, malformed reply or protocol mismatch MUST show a useful failure state. Readers MUST retain their current files and be able to retry after an edit.

#### Scenario: Repeated timeout
- **WHEN** the same revision times out on its original request and automatic retry
- **THEN** automatic execution stops with a visible explanation
- **AND** lesson reading, file editing and navigation remain available

#### Scenario: Replaced runtime replies
- **WHEN** a terminated worker replies or a worker returns an incompatible protocol version
- **THEN** the former cannot update the workspace and the latter produces a visible compatibility error
- **AND** neither result is reported as a successful check

### Requirement: Diagnostics and output inspection

The workspace SHALL present consumer-supplied diagnostics with their code, severity, message and available file location, and expose labeled text outputs or blocked reasons. It SHALL highlight changed output lines after a successful edit result without changing output text. Diagnostic and output strings MUST display literally rather than execute markup.

#### Scenario: Consumer blocks conversion
- **WHEN** the consumer reports diagnostics and a blocked output with its reason
- **THEN** both remain inspectable without Telescope guessing which severity caused the block
- **AND** a later successful output replaces the blocked state

#### Scenario: Changed output includes markup
- **WHEN** a new result changes one line and includes script-like text
- **THEN** the line change is identified and the complete text remains selectable
- **AND** the script-like text does not execute

### Requirement: Capability-driven comparison and stepping

The workspace SHALL support grouped comparison files and ordered execution steps when explicitly declared by a provider and lesson. Step SHALL advance one unit and Run all SHALL finish the remaining units. Editing step inputs MUST invalidate prior progress and recompute up to the reader's requested position before showing current results. Unavailable actions MUST be absent.

#### Scenario: Comparison lesson
- **WHEN** a lesson declares Old and New file groups and a comparison operation
- **THEN** both groups retain independent editor histories
- **AND** comparison diagnostics and output belong to the current revision of both groups

#### Scenario: Edit after stepping
- **WHEN** a reader steps twice and then edits the input
- **THEN** old step findings are invalidated and checking restarts against the new input
- **AND** results resume at the requested second unit or the new end, whichever comes first

### Requirement: Accessible workspace controls

File and result selectors, Reset, step actions and pane expansion SHALL work with a keyboard, identify their state programmatically and preserve meaningful focus. The workspace SHALL remain usable in light and dark themes at 360 CSS pixels without horizontal page scrolling. Pane changes MUST preserve editor state, and status announcements MUST NOT move focus.

#### Scenario: Keyboard and narrow viewport
- **WHEN** a reader switches files and results, expands the output and restores the split view using a keyboard at a narrow viewport
- **THEN** labels, selected and expanded states remain available to assistive technology
- **AND** file contents and histories remain intact without horizontal page scrolling

### Requirement: Optional external workbench handoff

A lesson SHALL expose an external workbench action only when its consumer explicitly supports transferring the current lesson state. The consumer SHALL determine the destination and encoding limits. Unsupported or oversized transfers MUST leave files intact and explain the limitation without navigating to an incomplete state.

#### Scenario: Unsupported lesson or oversized state
- **WHEN** a consumer cannot represent a multi-file or oversized lesson in its workbench link
- **THEN** the action is absent or explains the limitation
- **AND** no files are silently dropped and no incomplete workbench URL opens
