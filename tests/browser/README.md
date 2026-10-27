# Browser qualification

`verification.json` retains the initial 0.1.0 candidate qualification as a
historical record. Current runs write evidence under `_build/browser/`; released
distribution results are recorded in [release verification](../../docs/release/verification.md).

These tests use pinned Playwright 1.64.1 and Chromium. They exercise actual native
Telescope output at `/` and `/example/`. Setup copies the independent fixture to
`_build/browser/work`, invokes `telescope build` and `check`, assembles supplied
next, 0.2 and 0.1 trees, and starts loopback `telescope serve` processes. It also
assembles a next-only site without a release. No generated HTML is patched by the
test harness. The fixture is original Telescope material under Apache-2.0.

Run from the repository root after `mise run build` or `mise run package`:

```sh
mise run test:browser
```

The task compiles the separate native consumer driver and installs the exact npm
lockfile and Chromium. The equivalent focused commands are:

```sh
mise exec -- sh -c 'MOON_HOME="$(mise where http:moonbit)" PATH="$(mise where http:moonbit)/bin:$PATH" moon -C tests/browser/driver build --target native --release'
mise exec -- npm ci --prefix tests/browser
mise exec -- npm exec --prefix tests/browser -- playwright install --with-deps chromium
mise exec -- npm --prefix tests/browser run typecheck
mise exec -- npm --prefix tests/browser test
```

`TELESCOPE_CLI` overrides the native executable, default
`_build/telescope/telescope`. `TELESCOPE_BROWSER_DRIVER` overrides the compiled
driver, default
`_build/native/release/build/qualification/browser-driver/cmd/cmd.exe`.
Relative overrides are resolved from the repository root. Tests select free
loopback ports; teardown terminates all servers, including on setup failure.
The npm test launcher takes `_build/browser.lock/` before invoking Playwright,
so concurrent workers cannot overwrite shared fixture or evidence destinations.
A second invocation fails with the lock path and leaves the active run alone.
If the launcher is killed before cleanup, inspect the recorded PID before
removing a stale lock.

The stock CLI accepts reviewed content and artifact manifests. Explicit page,
fence and island adapters are a public library API. `driver/` is a separate
consumer module that calls public `host.build` with registered page and island
adapters. The shared host reads sources, copies declared assets, checks the
complete output and promotes it. The CLI then checks and serves this tree. This
verifies actual library registration and browser execution through the same host
pipeline as the CLI.
The driver intentionally uses a workspace dependency for library integration;
distribution qualification remains the separate `tests/consumer` task.

Coverage includes local search and keyboard navigation, draft/template exclusion,
stored theme before stylesheet delivery, throwing storage, theme persistence,
narrow-screen menu and long paths, no-JavaScript reading, skip link and ToC,
clipboard success and rejection, reviewed HTML scripts, registered per-route
script/CSS isolation and static fallback, tree-local search, version selection,
HEAD probing, missing-page section fallback and static version banners. The
0.1.1 suite adds gallery primary/family navigation, SVG downloads, narrow themed
pages, static version-tree reading and canonical-link availability.

Evidence goes under `_build/browser/`:

- `cli-evidence.json` records executable paths, version, platform, commands,
  captured CLI output and served bases.
- `results.json` and `report/index.html` record actual Playwright outcomes.
- `test-results/` retains screenshots and traces for failures.
- `no-js-root.png` and `no-js-nested.png` show narrow static reading.

No gallery hashes or output digest manifests are generated. Native release
archive checksums remain part of the separate packaging workflow.
