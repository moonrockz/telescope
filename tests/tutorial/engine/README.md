# Neutral tutorial qualification engine

This original fixture proves Telescope's public tutorial contracts without a
language compiler. `qualification/tutorial-engine` exports `evaluate`,
`registration` and an implementation of the public `Evaluator` trait.

The engine identity is `sample.text`, engine version `1.0.0`, protocol version 1.
It declares `evaluate`, `start`, `step` and `run-all`. Ordinary evaluation returns
an output named `text`, preserving markup literally. An `ERROR` on a line produces
a diagnostic keyed by `filename:ERROR`; repeated lines retain multiplicity.
Options `uppercase` and `lowercase` are consumer-owned mutually exclusive forms.
Old/New file groups return an additional `comparison` output with `same` or
`changed`. Steps advance through input lines and reconstruct their session from
`text:N`; a requested position clamps to shorter edited inputs.

The native `cmd` package reads one JSON request from stdin and writes one JSON
response. Its caller owns subprocess timeout and case isolation. The JS `worker`
package installs an `onmessage` bridge around the same compiled `evaluate`
function. Browser transport sends no source to a server.

From the repository with pinned mise tools:

```sh
mise exec -- moon -C tests/tutorial/engine test . --target native --deny-warn
mise exec -- moon -C tests/tutorial/engine check cmd --target native --deny-warn
mise exec -- moon -C tests/tutorial/engine check worker --target js --deny-warn
```

The repository's task runner sets `MOON_HOME` and places the pinned compiler
first on PATH. The consumer qualification copies this fixture outside the
checkout and resolves the packaged public Telescope library. A candidate cache
is an explicit prerelease input, never publication evidence.
