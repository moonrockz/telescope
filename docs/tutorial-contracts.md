# Tutorial contracts

Tutorials are optional. Site JSON selects the authored manifest with
`"tutorials": "site/tutorials.toml"`. The manifest is TOML, parsed with
`moonbit-community/toml@0.5.0` under Telescope's pinned MoonBit compiler.
The parser is Apache-2.0; its implementation is a package dependency.
Site configuration, worker envelopes, expectations and generated reports remain JSON.

```toml
# Paths below root are explicit inputs, never discovered engine modules.
schema_version = 1
root = "site/learning"

[[providers]]
id = "sample.text"
contract_version = 1
engine_version = "1.0.0"
operations = ["evaluate"]
worker = "assets/text-worker.js"
assets = ["assets/text-worker.js"]

[[courses]]
id = "getting-started"
title = "Getting started"
route = "/learn/"

[[courses.lessons]]
slug = "reading"
title = "Read first"
section = "Basics"
prose = "reading.md"

[[courses.lessons]]
slug = "first-check"
title = "First check"
section = "Basics"
prose = "first.md"
editor = "plain" # or rich, with the same document contract
files = [{ name = "input.txt", source = "input.txt", language = "text" }]
execution = { provider = "sample.text", operation = "evaluate", options = {} }
cases = [{ id = "start", expect = "cases/start.json" }]
```

The public `tutorial/model` package decodes this into `Manifest`, `Course`,
`Lesson`, `FileSource`, `Execution` and `CaseSource`. `Course::lesson_route`
uses the configured course prefix and stable lesson slug. `Course::neighbors`
uses lesson order. Two courses can reuse a lesson slug under different prefixes.
Reordering lessons changes navigation without changing URLs.

All structural fields are strict. Only provider-owned options tables are open.
Duplicate keys, malformed TOML, unsupported versions, date/time values,
non-finite numbers, wrong types and unknown fields fail decoding. Semantic errors
name their field; syntax errors retain the parser's source location. Provider
workers and workbench modules must appear in their complete asset inventory.
Static lessons reject files, cases and editor configuration. Executable lessons
need starting files and a named `start` case.

TOML comments, whitespace and table-key order do not affect normalized input.
`canonical(Json)` sorts object keys recursively and retains array order.
`input_revision` covers schema, provider identity/version, operation, options and
ordered files, including text, language and group. Revisions are freshness
identities, not cryptographic integrity evidence.

General editor and language modules can also be declared explicitly:

```toml
[[editors]]
id = "sample.editor"
contract_version = 1
kind = "editor"
module = "assets/custom-editor.js"
languages = ["text"]
assets = ["assets/custom-editor.js"]
```

A lesson selects that adapter with `editor = "sample.editor"`. The module exports
`createAdapter` and implements the general editor adapter contract. A
`kind = "language"` module exports `createLanguages({StreamLanguage})` and supplies
its declared rich-editor languages. Module files must appear in the full asset
inventory. Unknown IDs, duplicate language bindings, unsupported versions,
missing modules and incompatible document languages fail before promotion.
The native registration field is `module_path`; authored and runtime JSON use
`module`. Built-in `plain` and `rich` adapters remain available without these
registrations. A repeated prose path is rejected because each lesson source must
map to exactly one published route.

Formatter declarations use the general editor's `FormatterRegistration` and
`Binding` types. A language binding in `[formatting.languages.text]` contains
`provider` and an optional `options` table. A file's `formatter` table overrides
its language default. Both are checked against the registered supported
languages. See [the standalone editor API](editor.md). The general editor owns
Formatter and has no tutorial dependency.

## Execution and checking

An execution `Provider` declares its contract version, engine version, supported
operations and prebuilt assets. `Request` identifies provider, engine version,
worker generation, request ID and complete input revision. It supplies current
virtual files, options, operation and optional session/position. `Response`
echoes those identities and returns a status, diagnostic list, ordered outputs,
optional blocked reason/verdict and optional steps. Status is `success`,
`blocked` or `error`. Severity and diagnostic keys are consumer strings.

Diagnostics have an opaque comparison key, display code, severity, message and
optional virtual file/one-based span. Outputs have an ID, label, language and
exact text. Steps carry a session, ordered rows, checked count, completion and
optional summary. Optional wire fields are JSON null or omitted; present values are scalars or
objects, never MoonBit Option arrays. Required integer identities reject
fractional values. Native and browser revisions use the same lexical UTF-16 key
ordering. `response_problems` rejects protocol mismatches, stale
identities and malformed result metadata. Text remains literal in presentation.

The open `Evaluator` trait computes a response from a request. A compiled
consumer supplies `EvaluatorRegistration` callbacks explicitly; the stock CLI
never imports an engine named in configuration. `validate_evaluators` verifies
identity, version and declared capabilities before callbacks run. Render-only
builds make no case-pass claim. Built-site link checking and executable case
checking have separate entry points.

`overlay_files` replaces matching virtual names and appends new files without
mutating starting files. Every case starts independently from the same inputs.
The host orders cases by ID and creates a fresh evaluation/session for each.
A domain-negative case passes when its expected findings match.

```json
{
  "diagnostic_keys": ["invalid-input", "invalid-input"],
  "blocked": "cannot convert",
  "verdict": "invalid"
}
```

`diagnostic_keys` is required and complete. It compares a multiset, so duplicate
keys retain multiplicity. Successful output assertions use
`"outputs": [{"id":"result","contains":["nonempty needle"]}]`.
Empty needles and simultaneous blocked/successful-output assertions are invalid.
A step assertion contains `checked`, `complete` and complete `diagnostic_keys`
for the returned rows. Unsupported assertions fail explicitly.

`CaseReport` retains source, course, lesson, case, provider/version, input revision,
pass state and mismatches. `reports_text` and JSON serialization produce reports
without rewriting expectations. The optional reference hook receives pinned
`ReferenceEvidence`; required stale evidence fails. Every declared difference
retains its reason and tracking reference. Domain engines and reference runners
remain consumer-owned.

## Tested source includes

An explicit include fence contains labeled, contained source references:

````markdown
```tutorial-include
CLI = tests/cli.md#start
API = tests/api.md#start
```
````

A source policy supplies the exact source path, allowed regions, allowed fence
languages and runner identity. Neutral boundaries are complete comment lines:

````markdown
<!-- tutorial:start start -->
```sh
sample check input.txt
```
<!-- tutorial:end start -->
````

`source_policy` creates those defaults. A consumer may explicitly map
`marker_start` and `marker_end` to its existing names. `extract_region` ignores
marker-like text inside fences, rejects nested/repeated/missing/unclosed regions
and requires approved code fences. Every extracted block retains its exact code
text, language and source reference. Rendering executes no command. Extraction
without an expected `input_revision` is coverage only and sets `verified` false.
A verified extraction additionally requires that explicitly supplied revision to
match the selected successful runner evidence and exact source bytes.

Policy coverage alone is structural evidence. `SourceEvidence` must identify a
successful runner, exact source revision and relevant input revision before a
verification claim is valid. `source_evidence_problems` fails required stale or
unsuccessful evidence. A policy's `evidence_by_input` map can supply independent
reports for starting and overlay revisions. `source_evidence` selects a matching
revision first and then the default `evidence`; an unmatched required default
still fails. Optional consumer guards can reject hand-written domain
examples outside approved includes. Telescope does not infer coverage from a
fence language or require Java, Smithy or Morphir.
