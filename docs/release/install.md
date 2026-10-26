# Candidate installation and qualification

No Telescope version is published yet. Candidate 0.1.0 is a local prerelease
qualification input and is not an adoption dependency.

```sh
mise run package
mise run test:consumer -- --prepared
```

The package task creates `_build/publish/moonrockz-telescope-0.1.0.zip` and the
current platform's archive under `_build/package/`. Supported qualification
platforms are Linux x64 and macOS arm64. The native archive contains `telescope`,
LICENSE, NOTICE, README and resolved third-party license records. CSS and generic islands are embedded in the binary.

The consumer harness creates a temporary directory outside this checkout and an
isolated Moon home. It reuses only the pinned compiler's bin/lib/include as tools.
For candidate mode it copies public registry index/cache data, inserts the exact
packaged ZIP and an explicitly identified prerelease index entry with its real
archive checksum and pinned dependency metadata. This is an isolated cached
candidate, not a registry publication and not a simulated claim of registry
availability.

The consumer manifest pins `moonrockz/telescope@0.1.0`, has no moon.work or local
path dependency, compiles two library tests, including public host.build with a compiled custom fence provider, verifies the CLI archive SHA-256 and
version, then builds and checks its own mixed content at `/` and `/example/`.
No reference checkout is consulted. Evidence is written to
`_build/evidence/consumer-<platform>.json`; temporary consumers and caches are
removed afterwards.

To install the current candidate archive manually:

```sh
cd _build/package
shasum -a 256 -c telescope-0.1.0-macos-arm64.tar.gz.sha256
tar -xzf telescope-0.1.0-macos-arm64.tar.gz
./telescope-0.1.0-macos-arm64/telescope --version
```

Use `linux-x64` instead on a qualified Linux x64 host. Archive extraction is the
CLI installation path; no MoonBit installation or source checkout is needed to
run that binary. The library needs the matching supported MoonBit toolchain.

After an explicitly approved publication, run:

```sh
mise run test:consumer -- --published ACTUAL_VERSION
```

Replace ACTUAL_VERSION with the actual published semantic version. Published
mode creates an empty registry home, resolves the real Mooncakes version, fetches
the matching GitHub CLI release archive/checksum and repeats qualification.
It never seeds the local candidate entry. Failure to find either distribution
keeps adoption blocked. Record real registry and release URLs only after this
command succeeds. No such published proof exists now.
