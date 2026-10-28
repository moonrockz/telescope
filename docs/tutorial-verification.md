# Tutorial candidate verification

Candidate 0.3.0 adds opt-in TOML courses, a general editor with a public Formatter,
MoonBit rich editing and explicit consumer execution/check contracts. It is a
prerelease candidate until the owner approves its exact merge commit/version and
the Actions publication and real published-consumer checks pass.

The accepted 0.2.1 site records and extension registry remain source compatible.
General editor packages import no tutorial packages. Tests use a neutral text
engine; they make no claim about Smithy engine correctness or downstream adoption.

Local verification passes strict portable/native checks, 282 native tests, two
release-gate tests, 18 JS unit tests and compiled native/worker wire parity.
Chromium passes all 108 scenarios in Linux CI. Fresh packaged consumers pass at
both bases on Linux x64 and macOS arm64. See the [candidate CI evidence](release/candidate-0.3.0-ci.json)
and [qualification run](https://github.com/moonrockz/telescope/actions/runs/40635105037).

## Scenario coverage

| Contract/scenarios | Automated evidence |
| --- | --- |
| Explicit opt-in and unchanged version-one consumers | Existing model/site/extensions tests, existing packaged consumer and browser fixtures |
| TOML comments, strict keys/types/versions, identity/order, canonical revisions | `tutorial/model/model_test.mbt`; host `tutorial_wbtest.mbt` |
| Containment, symlinks, route/asset collisions and staged failure | Host tutorial tests plus existing host path/output tests |
| Course contents, same-slug courses, neighbors, source links, search and version bases | Native tutorial tests, `tests/browser/tutorial.spec.ts`, independent consumer driver |
| Static/no-script reading, downloads and policy-covered includes | Native include tests, tutorial Chromium no-script test, independent consumer browser smoke |
| Standalone editor, aliases, incomplete tokens, themes, text/selection/history and language switches | `tests/editor/moonbit.test.mjs`, editor pure tests and `tests/browser/editor.spec.ts` |
| Open Formatter replacement/bindings, plain/rich undo, unchanged results and normal changes | Editor pure/config/bridge tests, compiled standalone fixture, editor/tutorial Chromium |
| Formatting target/context/reset/replacement/disposal races, malformed/error/timeout and explicit retry | Editor pure tests and editor Chromium lifecycle scenarios |
| Execution debounce/coalescing/revision/generation/reset/disposal and one timeout retry | Workspace pure tests, `tests/tutorial/runtime.test.mjs`, stalled-worker Chromium |
| Scoped storage, input revision, corrupt/denied storage and Reset retaining layout | Runtime tests, tutorial Chromium and older version tree scenarios |
| Literal diagnostics/output, blocked results, output changes and keyboard/narrow layout | Runtime validation tests, neutral engine tests, tutorial/editor Chromium |
| Comparison groups, steps, requested-position replay, empty/shorter input and Run all | Neutral engine tests, workspace/runtime tests and tutorial Chromium |
| Opaque options, mutually exclusive forms and workbench limits | Neutral engine tests, runtime handoff tests and tutorial Chromium |
| Independent overlays, complete diagnostic keys with multiplicity, needles, verdict and steps | Portable check tests and native consumer case driver |
| Missing/version-mismatched/failed/timed-out evaluators and deterministic reports | Native host tests, portable protocol tests, compiled consumer process runner |
| Region markers, fence-contained text, malformed/duplicate/unapproved/escaping sources | Portable include tests and native host containment tests |
| Structural coverage versus successful matching source evidence | Portable source-evidence tests and native source-report tests |
| Reference revisions, stale required evidence and retained difference reasons/tracking | Portable reference tests and host reference hook contract |
| Clean packaged APIs, assets and actual worker execution under `/` and `/sample/v/1/` | `scripts/test-tutorial-consumer.mbtx` and `tests/tutorial/consumer/` |

## Smithy parity boundary

The source inventory is pinned in the active OpenSpec design to Smithy main
`caa78a677b88fdf506eb77953453d2519f1f4786` and codec workspace
`e3c140d11dba72b5f642c1e634bd94ec4adc2c94`.

| Observed behavior | Telescope implementation | Reserved for a Smithy-owned adoption |
| --- | --- | --- |
| Sectioned courses, links and search | TOML catalogs, host/site composition and static lesson views | Lesson order, prose and translation of existing metadata |
| Independent files and rich editing | General editor, document histories and language registrations | Smithy language mode and domain file roles |
| Findings, output and changed lines | Neutral diagnostics, text panels and lifecycle | Severity-to-blocking rules and transformations |
| Saved edits, Reset, expansion and phone layout | Scoped tutorial caller state and shared editor controls | Any old storage migration |
| Slow runtime recovery and stale replies | Generation/revision/request guards, deadlines and bounded retry | Bounded domain engine work |
| Old/New inputs and comparison | Named groups and neutral outputs | Domain comparison and blocking semantics |
| Step/Run all and edit replay | Session/position contracts and workspace scheduler | Transcript interpretation and summaries |
| Values, messages and codec profiles | Opaque options and consumer validation | Shapes, services, profile semantics and conflicts |
| CLI/API source tabs | Policy-covered static includes and explicit evidence reports | Approved source inventory, runner and command/API guards |
| Start/overlay cases and reference claims | Independent runners, comparator and reference hook | Smithy engine, Java/reference tooling and Morphir claims |
| Open in workbench | Explicit consumer encoding with destination/size checks | Supported modes, encoding and destination |

Telescope does not edit Smithy, its codec workspace or diagrams.mbt. Publication
and real public installs are separate evidence gates. The active OpenSpec change
and release story remain open until that evidence exists.
