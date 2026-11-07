# OpenSpec

## Shared OpenSpec bundle

`html-design` comes from Mission Control's tools CLI, `mission-control-tools`
0.1.1, pinned in `.config/mise/config.toml`. The schema, templates and licenses
are generated snapshots; keep repository overrides in `openspec/config.yaml` and
`AGENTS.md`. The binary is released separately, so a MoonBit toolchain change in
this repository cannot break the OpenSpec tasks.

- Run `mise run openspec:check` to verify the committed file hashes, the default
  schema and that the files match the pinned tools version.
- Run `mise run openspec:setup` to regenerate the six core agent skills with isolated global preferences.
- Run `mise run openspec:validate` (schema and `openspec validate --all --strict`)
  before review, or `mise run openspec:verify` for the check and the validation.
- New designs are offline `design.html` with inline CSS. Existing changes keep
  their schema metadata and original designs, including Markdown designs.
- OpenSpec requirements and change artifacts are committed project documentation.
  Scratch documents remain local under the existing repository rules.

To update the snapshots, change the `github:moonrockz/mission-control` version in
`.config/mise/config.toml`, then run:

```shell
mise install
mise exec -- mission-control-tools openspec install
mise run openspec:verify
```

`install` refuses a local edit of a managed file. Change the shared source in
Mission Control instead. See
[the tools guide](https://github.com/moonrockz/mission-control/blob/tools-v0.1.1/apps/tools/README.md).
