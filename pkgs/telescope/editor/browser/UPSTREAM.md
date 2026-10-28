# Editor source and dependency records

The portable document and Formatter contracts, browser lifecycle and fixture
formatter are original Telescope code under Apache-2.0.

The MoonBit tokenizer and live stream integration use the behavior of these
Smithy sources as references at revision
`caa78a677b88fdf506eb77953453d2519f1f4786`:

- `site/highlight/highlight.mbt`, MoonBit keyword and line-limited literal rules.
- `site/playground/editor/smithy.js`, CodeMirror stream-language integration.

These files were read through `git show` at that revision. Their repository is
Apache-2.0. No Smithy engine, grammar, lesson text, test datasets or branding is
included. The implementation adds character literals, package references,
annotations, multiline string lines and incomplete live-edit tests.

The optional rich bundle uses the exact npm dependencies in `package.json` and
`package-lock.json`. CodeMirror and Lezer packages and their transitive runtime
dependencies use the MIT license. `THIRD-PARTY-LICENSES.txt` retains the complete
license text and exact package versions for every bundled dependency. Include
that file when distributing the rich editor assets.
