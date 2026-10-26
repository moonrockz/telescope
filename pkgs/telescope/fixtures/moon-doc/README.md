# Compiler metadata fixture

Generated from this Telescope module with the pinned MoonBit toolchain
`moonc v0.10.17+093cb8f9c`, Moon CLI `0.1.20261021`, using:

```shell
MOON_HOME="$(mise where http:moonbit)" "$(mise which moon)" doc --target-dir ../../_build/library-doc
```

`content-package.json` is the compiler's `doc/moonrockz/telescope/content/package_data.json`.
`module-index.json` is the compiler's `doc/moonrockz/telescope/module_index.json`.
These inputs exercise the current compiler in addition to the attributed notebooks
baseline embedded in `model/api_fixture_test.mbt`. They contain documentation
metadata, not a dependency on another project.
