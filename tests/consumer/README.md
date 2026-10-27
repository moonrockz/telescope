# Independent consumer fixture

This fixture belongs to an unrelated project and contains mixed Markdown, a
standalone reviewed HTML document and its local CSS. It is copied outside the
workspace by `scripts/test-consumer.mbtx`. The harness creates its own exact
versioned library manifest without a workspace or path override and installs the
CLI by extracting the packaged archive after checksum verification.

Run `mise run test:consumer` to package and qualify, or `-- --prepared` to consume
already prepared artifacts. `-- --published ACTUAL_VERSION` uses only the real
registry and GitHub release and must run after approved publication. Candidate
cache seeding is never a substitute for that final test.
