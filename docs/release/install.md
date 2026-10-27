# Installation and qualification

Telescope 0.2.0 is published. Use the exact library pin, native CLI downloads,
checksums and supported toolchain in [the version-specific instructions](0.2.0.md).
Repeat actual released-install qualification with:

```sh
mise run test:consumer -- --published 0.2.0
```

Linux x64 and macOS arm64 passed. Retained reports are linked from the
[release verification](verification.md). The candidate workflow below is a
separate development check and cannot satisfy a published dependency gate.

```sh
mise run package
mise run test:consumer -- --prepared
```

The current development candidate is 0.2.1; it is not published.
The package task creates `_build/publish/moonrockz-telescope-0.2.1.zip` and the
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

The candidate consumer pins `moonrockz/telescope@0.2.1`; published mode uses the
explicitly requested public version. Neither has a moon.work or local path
dependency. The harness compiles three library tests, including public host.build with a compiled custom
fence provider and static gallery source inspection, verifies the CLI archive
SHA-256 and
version, then builds and checks its own mixed content at `/` and `/example/`.
No reference checkout is consulted. Evidence is written to
`_build/evidence/consumer-<platform>.json`; temporary consumers and caches are
removed afterwards.

To install a locally packaged candidate archive manually:

```sh
cd _build/package
shasum -a 256 -c telescope-0.2.1-macos-arm64.tar.gz.sha256
tar -xzf telescope-0.2.1-macos-arm64.tar.gz
./telescope-0.2.1-macos-arm64/telescope --version
```

Use `linux-x64` instead on a qualified Linux x64 host. Archive extraction is the
CLI installation path; no MoonBit installation or source checkout is needed to
run that binary. The library needs the matching supported MoonBit toolchain.

For any later owner-approved published version, run:

```sh
mise run test:consumer -- --published ACTUAL_VERSION
```

Replace ACTUAL_VERSION with the actual published semantic version. Published
mode creates an empty registry home, resolves the real Mooncakes version, fetches
the matching GitHub CLI release archive/checksum and repeats qualification.
It never seeds the local candidate entry. Failure to find either distribution
keeps adoption blocked. Record real registry and release URLs only after this
command succeeds. Actual 0.1.0 and 0.1.1 proofs are retained beside these instructions.
