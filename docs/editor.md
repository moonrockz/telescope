# General code editor

The general editor is usable on an ordinary page without tutorial imports,
configuration or execution providers. Its public MoonBit contracts are in
`moonrockz/telescope/editor`; static Rabbita fallback views are in
`moonrockz/telescope/editor/views`. The JS browser component mounts the same
editor for standalone pages and tutorials.

## Standalone browser use

Build the optional browser entry `pkgs/telescope/editor/browser/editor.js` with
the pinned dependencies. Telescope's build produces `assets/editor/editor.js`,
a lazy rich-editor chunk and `assets/editor/editor.css`. Distribute the matching
`THIRD-PARTY-LICENSES.txt` with those assets. A page using only the plain adapter
does not request the rich chunk. A page with no configured editor requests
neither bundle.

```js
import { mountEditor } from '/assets/editor/editor.js';

const editor = await mountEditor(document.querySelector('#editor'), {
  id: 'playground',
  adapter: 'rich',
  documents: [{
    id: 'main', name: 'main.mbt', language: 'moonbit',
    text: 'pub fn answer() -> Int { 42 }\n'
  }],
  onChange(event) {
    // event.document is the changed document. event.documents is a snapshot.
    console.log(event.id, event.text, event.origin);
  }
});
```

Use deployment-relative asset URLs under a project or version base. An authored
`[data-telescope-editor]` element can instead contain a JSON configuration in
`data-config` or a child `<script type="application/json" data-editor-config>`.
The module mounts only those explicit elements and retains their static
fallback until its dependencies load. Escape JSON appropriately for the HTML
attribute or script context. The mounted API is available as
`element.telescopeEditor`.

Declared languages `moonbit` and `mbt` select the shipped MoonBit mode. It styles
keywords, numbers, strings, character literals, line and documentation comments,
annotations, package references and `#|` multiline string lines. Incomplete live
source remains editable. Highlighting and language changes emit no content
change, and preserve text, selection, focus and Undo. Plain editing and unknown
languages keep readable source. No formatter or compiler is required.

`languageAdapters` can map additional language IDs to CodeMirror extensions when
mounting the rich adapter. An explicit entry can replace either MoonBit alias.
Consumers can supply an adapter factory through `adapters` and select it with
`adapter`; factories receive the input element and normal change, selection,
Undo and Redo callbacks. The built-in `plain` and `rich` adapters share the same
document contract.

## Documents and changes

Each instance keeps independent text, selection and history for every document
ID. Virtual names are normalized relative paths. Use:

- `getDocuments()` and `getDocument(id)` for immutable snapshots.
- `selectDocument(id)` for file switching, including optional group labels.
- `edit(id, text)`, `undo(id)` and `redo(id)` for normal content changes.
- `getSelection(id)` and `setSelection(id, {anchor, head})` for selections.
- `setLanguage(id, language)` for highlighting changes.
- `setAdapter('plain' | 'rich')` to switch presentation while retaining state.
- `reset()` to restore the original documents and clear all histories.
- `reset(documents)` or `replaceDocuments(documents)` to replace a document set
  and invalidate pending formatting even when text is unchanged.
- `dispose()` to terminate pending work and remove the mounted component.

Changed edits, Undo, Redo and formatting call `onChange` and dispatch
`editor-change` with `{id, text, document, documents, origin}`. No-op edits and
unchanged formatting emit no event and add no history. Reset is a caller action
and does not emit synthetic file edits. `editable: false` makes a document
read-only and hides Format.

## Consumer-owned Formatter

A formatter computes one document's text. The open trait and every formatting
document, input, output, error and request type belong to the general editor:

```moonbit
pub(open) trait Formatter {
  format(Self, FormatInput) -> Result[FormatOutput, FormatError]
}
```

`FormatInput` has `target : Document`, immutable `context : Array[Document]` and
consumer `options : Json`. `Document` contains stable `id`, virtual `name`, exact
`text` and declared `language`. `FormatOutput` returns `text`; `FormatError`
returns a displayable `code` and `message`. Implementations receive no mutable
editor, course, storage or engine handle.

The independent fixture in `tests/editor/fixture/whitespace` implements this
trait and imports no tutorial package. Its worker entry calls
`@browser.install_formatter(WhitespaceFormatter::{})` from
`moonrockz/telescope/editor/browser`. Compile that consumer worker for JS and
bundle it as a prebuilt module. The host validates and copies its declared
assets, and never invokes formatting while rendering.

Register a formatter explicitly when mounting:

```js
{
  formatters: [{
    id: 'my.whitespace', contract_version: 1, formatter_version: '1.0.0',
    languages: ['text'], worker: 'format-worker.js', assets: ['format-worker.js']
  }],
  languages: { text: { provider: 'my.whitespace', options: {} } },
  assetBase: '/project/v/1/assets/my-formatter/'
}
```

A document's `formatter: {provider, options}` overrides its language default.
An unbound document has no Format action. The editor never infers a provider
from a filename. Unique IDs, contract versions, declared assets and compatible
language bindings are validated before mounting. Portable registrations use
`Registry`, `FormatterRegistration` and `Binding`; `validate_registry` and
`validate_binding` provide the same compatibility boundary for host adapters.

`format(id)` is explicit and asynchronous. It uses a dedicated terminable local
worker, allows one request per instance, and defaults to a 10-second deadline.
Use `formatTimeout` for a shorter bounded deployment policy. The bridge echoes
instance, provider/version, generation, request ID, target identity and captured
revisions of every input document. Edits, resets, replacement, formatter changes
and disposal invalidate pending replies. Tab switching alone permits a valid
reply to update its originating document without changing focus in another.

A changed reply is one undoable edit with a mapped valid selection and an
ordinary change event. Unchanged replies leave state intact. Worker errors,
invalid responses and timeouts preserve documents and histories, announce a
literal failure message without moving focus, and allow an explicit Format
retry. `setFormatters(registrations, languageBindings)` replaces providers and
invalidates in-flight formatting.

A JS consumer can use `installFormatterWorker(handler)` around a synchronous
compiled callback. The portable `formatter_reply` helper produces the same
wire response around an externally implemented MoonBit Formatter. Responses
are `{request, output: {text}}` or `{request, error: {code, message}}`; the
request is echoed unchanged.

## Tutorial composition

Tutorial workspaces translate their files into the general document API and
listen to normal changes for persistence, result invalidation, rechecking and
step replay. They call document reset when Reset is requested. The editor does
not derive lesson storage keys or initiate execution. Standalone callers decide
their own change handling. Tutorial authoring is documented separately.

## Qualification

Focused portable checks run with
`moon -C pkgs/telescope test editor --target native --deny-warn` under the pinned
mise Moon home. `node --test tests/editor/moonbit.test.mjs` exercises token classes,
incomplete literals and exact source preservation. `mise run test:browser`
includes actual Chromium tests of both adapters, the compiled standalone
Formatter worker, theme styling, aliases, Undo, document and context races,
malformed replies, errors, timeouts, reset, replacement and 360-pixel layouts.
The packaged consumer fixture must also run outside the checkout against the
candidate package. A workspace test alone is not publication evidence.

## Declared editing and language modules

Prebuilt consumer adapters can be registered through the same general editor
contract on standalone pages and tutorials. Registrations have this wire shape:

```js
{
  editors: [{
    id: 'my.editor', contract_version: 1, kind: 'editor',
    module: 'custom-editor.js', languages: ['text'], assets: ['custom-editor.js']
  }, {
    id: 'my.language', contract_version: 1, kind: 'language',
    module: 'custom-language.js', languages: ['my-language'],
    assets: ['custom-language.js']
  }],
  adapter: 'my.editor',
  assetBase: '/project/assets/'
}
```

Native `EditorRegistration` calls the module field `module_path` because
`module` is reserved in MoonBit. Its JSON and TOML key is `module`.
`validate_registry` rejects unknown kinds, duplicate IDs or language bindings,
unsupported versions, empty capabilities and undeclared or escaping modules.
`validate_editor_binding` checks a selected adapter against document languages.
The built-in plain and rich adapters retain readable fallback for unknown modes.

An editor module exports `createAdapter(parent, callbacks, options)`. It returns
`show(document, selection, focus)`, `setLanguage(language)`,
`selection({anchor, head})`, `focused()`, `focus()` and `dispose()`. It reports
normal edits through `callbacks.change(text, selection)`, selection changes
through `callbacks.selection(selection)`, and Undo/Redo through
`callbacks.undo()` and `callbacks.redo()`. The general component retains history,
Formatter handling and normal change notifications. Only the selected editor
module loads. A custom adapter must support every configured document language.

A language module exports `createLanguages({StreamLanguage})`, returning the
complete map of its declared language IDs to CodeMirror extensions. The rich
bundle injects its own `StreamLanguage` so consumer modules do not bundle a
second CodeMirror state system. Declare additional module imports and companions
in `assets`. A language registration can explicitly replace the shipped
`moonbit` or `mbt` mode. Each language has at most one declared registration.
The component loads language modules only for languages used by configured rich
documents. Selecting a new language loads its module before reconfiguring the
mode; this may return a promise. Text, selection and history remain intact and
no content event is emitted by the language change.

Direct `adapters` and `languageAdapters` factories remain available to compiled
JS consumers and take precedence over declarative modules. Tests in
`tests/editor/adapters` demonstrate a custom editor, an unrelated lexical mode
and an explicit MoonBit replacement without tutorial imports or domain engines.
