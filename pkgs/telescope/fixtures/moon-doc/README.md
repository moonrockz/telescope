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

Checked with the pinned toolchain `moonc v0.10.18+6c83a7f62`, Moon CLI
`0.1.20261028`: `content-package.json` is byte-identical to the fresh output.
`module-index.json` has the same format as the fresh output. The fresh index also
lists the packages that were added to the module after the fixture was recorded.
