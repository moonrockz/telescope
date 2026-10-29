# Proposal

## Why

Moon-Lander's Windows consumer cannot use the released native host because
canonical Windows paths do not match its slash-based containment and staging
rules. Fix the shared boundary so consumers can keep Windows docs tooling.

## What Changes

- Normalize native Windows drive and UNC paths at filesystem boundaries.
- Preserve source containment, symlink rejection and staged output promotion.
- Exercise build, check and supplied-tree assembly on an actual Windows runner.
- Gate release publication on the Windows host qualification as well as the
  existing Linux and macOS distribution qualification.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `site-tooling`: Windows native-library host paths and qualification.

## Tracking

The owner approved the upstream fix through Moon-Lander PR 138. Create local
Telescope beads before implementation. Publication needs separate owner approval
for the exact release commit and version.

## Impact

The native host, native host fixtures, CI/release qualification and host docs.
Public signatures and the Linux/macOS CLI archive targets stay unchanged.
Moon-Lander adopts only a real published version after qualification.
