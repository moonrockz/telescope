# Authoring tutorials

Tutorial support is opt-in. Add a `tutorials` path to site JSON and author that
manifest in TOML. Existing site JSON and extension registrations remain valid.

```json
{"tutorials":"site/tutorials.toml"}
```

This fragment belongs alongside the site's existing title, paths and repository
configuration. A complete commented example lives in
[the qualification manifest](../tests/tutorial/tutorials.toml).

```toml
# Paths in this manifest are relative to the declared input root.
schema_version = 1
root = "site/learning"

[[courses]]
id = "basics"
title = "Getting started"
route = "/learn/"

[[courses.lessons]]
slug = "reading"
title = "Read first"
section = "Introduction"
prose = "reading.md"
references = [{ label = "Project reference", url = "https://example.test/reference" }]
```

The lesson route is `/learn/reading/`. Moving this lesson within the ordered
lesson array changes contents and neighbors while retaining that URL. Another
course may use `reading` under a different configured route prefix. Links to
lesson Markdown resolve to its published tutorial route, including under an
archived base such as `/sample/v/1/`.

Static lessons need only prose. They render without an editor or execution
provider. A course index, lesson text, references, source links and neighbors
remain readable without JavaScript. All paths must stay inside declared roots;
failed validation or builds preserve the last completed output.

## Editable lessons

Declare a provider explicitly and list all of its prebuilt worker, module and
WASM assets. The stock CLI validates and copies these inputs. It does not compile
or execute a consumer engine during rendering.

```toml
[[providers]]
id = "sample.text"
contract_version = 1
engine_version = "1.0.0"
operations = ["evaluate"]
worker = "assets/text-worker.js"
assets = ["assets/text-worker.js"]

[[courses.lessons]]
slug = "editing"
title = "Edit text"
section = "Introduction"
prose = "editing.md"
editor = "plain" # rich selects the optional CodeMirror adapter
files = [{ name = "input.txt", source = "input.txt", language = "text" }]
execution = { provider = "sample.text", operation = "evaluate", options = {} }
cases = [{ id = "start", expect = "cases/start.json" }]
```

Place provider declarations before the course array, as in the complete fixture.
Files have normalized virtual names, optional groups and declared languages.
Rich editors ship MoonBit highlighting for `moonbit` and `mbt`; no formatter or
compiler is required. Formatting uses the general [editor contract](editor.md).
Provider options remain consumer-owned data. Optional `[[editors]]` registrations
can provide an editor adapter or rich language module. They declare a unique ID,
contract version, kind, module, languages and complete asset inventory. A lesson
selects a custom editor by its registered ID. The host checks capabilities and
copies module assets; the browser loads a selected adapter or language only where
used. The complete fixture includes both custom registration forms.

Editor assets load only for configured editors. Workers evaluate on the reader's
device. Edits debounce, invalidate old results and save under the deployment,
course and lesson identity. Reset restores starting files and histories while
retaining layout. Unavailable storage leaves editing usable. A slow worker gets
one automatic timeout retry; later failure leaves files readable and editable.

For comparison, files use explicit `Old` and `New` groups. Stepping providers
declare `start`, `step` and `run-all`; editing invalidates the session and replays
to the requested position or the new end. External workbench modules must return
a safe complete destination or a useful unsupported/oversized result. They must
preserve every current file.

## Structural build and executable checks

These commands build and check published pages:

```sh
telescope build --config site/site.json --out _site
telescope check --config site/site.json --out _site --format json
```

The built-site checker checks links and output structure. Case execution requires
a compiled consumer runner, registered through the public host API. This native
composition uses a precompiled engine process and a finite deadline:

```moonbit
let runner = @host.process_runner(provider, engine_executable, [])
let reports = @host.check_tutorials(
  root,
  "site/site.json",
  runners=[runner],
  timeout_ms=10000,
)
```

Inspect every `CaseReport.passed` value and return failure for mismatches.
`reports_text` and JSON serialization retain course, lesson, case, provider,
version and input revision. Keep reports outside public output because revisions
can contain private overlay inputs. No check command rewrites expectations.

The [independent driver](../tests/tutorial/consumer/cmd/main.mbt) demonstrates
build, include policies and case execution using the packaged host. The
[neutral engine](../tests/tutorial/engine/README.md) compiles the same evaluator
for a browser worker and a native command. A `start` expectation is mandatory.
Overlays replace or add files independently by virtual name.

```json
{"diagnostic_keys":[],"outputs":[{"id":"text","contains":["expected text"]}]}
```

Keys form a complete multiset; repeated keys retain multiplicity. Negative
teaching cases pass when their expected diagnostics match. Needles must be
nonempty. Blocked reasons, verdicts and step progress have explicit assertions.
See [tutorial contracts](tutorial-contracts.md) for the complete public shapes.

## Tested source includes

An explicit include fence references labeled regions:

````markdown
```tutorial-include
CLI = tested.md#cli
API = tested.md#api
```
````

A compiled consumer supplies the source-policy allowlist to `host.build` through
`tutorial_policies`. Policies identify source, regions, allowed fence languages
and runner. The stock CLI cannot invent that policy. Region contents remain
static-readable; rendering executes no command. Policy coverage is structural.
A verification claim also needs successful runner evidence matching exact source
and relevant inputs. Required missing or stale evidence fails checking.

Optional consumer guards can reject hand-written domain CLI/API examples outside
approved regions. Optional reference callbacks own external comparison and retain
pinned source/input revisions, difference reasons and tracking links. Neither
path introduces a particular domain compiler or reference runtime into Telescope.

## Packaged qualification and publication

After packaging, run the repository qualification command:

```sh
mise run test:consumer -- --prepared
```

It resolves the candidate in an isolated registry home, copies standalone
editor/Formatter and tutorial fixtures outside the checkout, compiles their
native and JS entry points without workspace overrides, executes independent
cases and checks both `/` and `/sample/v/1/`. Chromium edits the installed
artifact and waits for the current result. Repeated builds must preserve bytes.
The stock CLI separately proves structural tutorial builds without include
policies. The parent command records the package source and matching CLI archive.

An isolated candidate registry is prerelease evidence. Publication still requires
owner approval of the exact version and commit through the Actions release gate.
Fresh installs of the actual published registry package and checksum-verified CLI
archives require separate post-publication evidence. No downstream migration is
implied by candidate qualification.

Published 0.3.0 passes that separate gate on Linux x64 and macOS arm64; see the
[actual release and consumer reports](release/0.3.0.md). Repeat it with
`mise run test:consumer -- --published 0.3.0`.
