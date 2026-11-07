# Compiler metadata fixture

Generated from this Telescope module with `moon doc`, using:

```shell
MOON_HOME="$(mise where http:moonbit)" "$(mise which moon)" doc --target-dir ../../_build/library-doc
```

`content-package.json` is the compiler's `doc/moonrockz/telescope/content/package_data.json`.
`module-index.json` is the compiler's `doc/moonrockz/telescope/module_index.json`.
These inputs exercise the current compiler in addition to the attributed notebooks
baseline embedded in `model/api_fixture_test.mbt`. They contain documentation
metadata, not a dependency on another project.

Checked with the pinned toolchain `moonc v0.10.20+65efd5b93`, Moon CLI
`0.1.20261104`: `content-package.json` is the fresh output, recorded again
because the `#derive(...)` attribute moved the source lines. `module-index.json`
has the same format as the fresh output. The fresh index also lists the packages
that were added to the module after the fixture was recorded.
