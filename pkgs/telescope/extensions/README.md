# Extension contract version 1

Consumers compile page, fence and island adapters into their own drivers. Register
them explicitly in `Registry {pages, fences, islands}` and pass `providers~` to
`site.prepare` or `site.build`. The stock CLI reads standard config and prebuilt
gallery artifacts. There is no package discovery, runtime loading or binary ABI.

Every adapter has `id` and `contract_version: 1`. IDs are unique across all three
adapter categories. Page adapters declare one normalized route. Fence adapters
declare nonempty unique labels. Islands declare explicit routes, a mount ID, a
script artifact, optional stylesheet and readable `fallback_html`. Duplicate IDs,
versions, page routes, fence labels and per-route mount IDs fail validation before
callbacks run. Islands load only on their registered routes.

Page and fence callbacks have this signature:

```moonbit
(RenderInput) -> Result[RenderOutput, AdapterError]
```

`RenderInput` contains `source`, `route`, `base_path`, `body`, `language` and `ordinal`.
The ordinal starts at one for each fence adapter in a document, so repeated
diagrams can use distinct SVG ID prefixes without mutable callback state.
Page adapters receive zero.
`RenderOutput` contains reviewed `body_html`, plain `text`, heading facts
`{id,text,level}`, declared assets `{path,media_type}` and shared model `problems`.
`AdapterError {message,stage}` becomes a diagnostic with the adapter ID and input
source. Invalid output asset paths and invalid or duplicate heading facts fail.
There is no ambient filesystem handle; consumers supply text through their driver.
Declared asset files still require host regular-file/containment/collision checks.

`validate_registry` returns all registration diagnostics. `render_page` returns an
optional output for an exact route. `render_fence` dispatches by exact label and
returns escaped `<pre><code>` for unknown labels. It escapes every occurrence of
HTML metacharacters in both source and language attributes. No guessed renderer
claims support for an unknown language. `islands_for_route` filters an already
validated registry. Registration is checked again by the rendering entry points.

Consumer output HTML and island fallback HTML share the reviewed repository
content trust model. The shared Rabbita shell renders the complete document.
Fallback content must communicate useful information without scripts. A script
must not be required merely to read documentation or source downloads.

`examples/` contains a compiled consumer-owned note adapter with a static fallback
island. The unit tests exercise its same callback shape. The native site package
owns integration tests for callback invocation and route-local script inclusion.
All sample code is original Telescope material under Apache-2.0.
