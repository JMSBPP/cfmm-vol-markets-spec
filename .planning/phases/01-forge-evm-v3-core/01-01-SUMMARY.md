---
phase: 01-forge-evm-v3-core
plan: 01
subsystem: infra
tags: [foundry, solidity, uniswap-v4, tickmath, git-submodule]
requires: []
provides:
  - "Nested Foundry project with a solc 0.8.28 profile"
  - "Pinned Uniswap/v4-core@v4.0.0 TickMath dependency and import seam"
  - "Phase 1 roadmap and requirement terminology aligned to v4"
affects: [02-seaport-differential-base, 04-tickmath-diff-red]
tech-stack:
  added: [Foundry, Uniswap/v4-core@v4.0.0]
  patterns: ["Git submodule plus lockfile plus remapping for immutable Solidity dependencies", "Pure external harness delegation to preserve upstream error semantics"]
key-files:
  created: [.gitmodules, evm/foundry.toml, evm/foundry.lock, evm/remappings.txt, evm/src/TickMathHarness.sol, evm/README.md]
  modified: [.gitignore, .planning/ROADMAP.md, .planning/REQUIREMENTS.md]
key-decisions:
  - "Use Uniswap/v4-core@v4.0.0 at e50237c43811bd9b526eff40f26772152a42daba as the canonical TickMath oracle."
  - "Expose upstream v4 TickMath through direct pure harness delegation rather than copying arithmetic or translating errors."
patterns-established:
  - "Foundry artifacts remain ignored while dependency gitlinks, locks, and remappings are committed."
requirements-completed: [EVM-01, EVM-02]
coverage:
  - id: D1
    description: "Nested Foundry project compiles a local TickMath harness against the pinned v4 dependency."
    requirement: EVM-01
    verification:
      - kind: integration
        ref: "forge build --root evm && forge test --root evm"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact v4-core release, SHA, remapping, lock metadata, and generated-artifact hygiene are reproducibly verified."
    requirement: EVM-02
    verification:
      - kind: integration
        ref: "SHA, remapping, gitignore, and tracked-artifact verification commands"
        status: pass
    human_judgment: false
duration: 3 min
completed: 2026-09-08
status: complete
---

# Phase 1 Plan 01: Pinned Foundry TickMath Walking Skeleton Summary

**A solc 0.8.28 nested Foundry project now delegates both v4 TickMath APIs through a reproducibly pinned Uniswap/v4-core@v4.0.0 dependency.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-08T15:35:05Z
- **Completed:** 2026-09-08T15:38:41Z
- **Tasks:** 2/2
- **Files modified:** 10

## Accomplishments

- Added the `evm/` Foundry boundary and `TickMathHarness` direct delegation seam.
- Pinned `Uniswap/v4-core@v4.0.0` at `e50237c43811bd9b526eff40f26772152a42daba` with gitlink, lockfile, and remapping.
- Excluded generated Foundry artifacts and corrected Phase 1 documentation to the v4 oracle.

## Task Commits

1. **Task 1: Build the pinned TickMath path end to end** - `e83b77b` (feat)
2. **Task 2: Align roadmap and requirements with the locked oracle** - `7886db2` (docs)

## Files Created/Modified

- `.gitignore` - ignores nested Foundry cache, output, and broadcast artifacts.
- `.gitmodules` - tracks the official v4-core submodule.
- `evm/foundry.toml` - configures the nested solc 0.8.28 Foundry project.
- `evm/foundry.lock` - records the exact v4.0.0 resolved revision.
- `evm/remappings.txt` - provides the stable `v4-core/` alias.
- `evm/src/TickMathHarness.sol` - delegates both TickMath API functions unchanged.
- `evm/README.md` - documents the immutable pin, build command, and scaffold boundary.
- `.planning/ROADMAP.md` - records the one-plan v4 Phase 1 scope.
- `.planning/REQUIREMENTS.md` - replaces stale Phase 1 v3 terminology.

## Decisions Made

- Used the locked v4.0.0 tag and SHA as the canonical arithmetic source.
- Kept the scaffold free of Seaport, bridge, HEVM/FFI, and SqrtGrid work.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed dependency from the nested Foundry root**
- **Found during:** Task 1
- **Issue:** `forge install --root evm` rejected the library path under the parent Git root.
- **Fix:** Ran the same locked Forge installation command from `evm/`, preserving the requested dependency and provenance.
- **Files modified:** `evm/lib/v4-core`, `.gitmodules`, `evm/foundry.lock`
- **Verification:** The dependency resolved to the required SHA and the root-invoked build passed.
- **Committed in:** `e83b77b`

**2. [Rule 3 - Blocking] Removed Forge's incidental default dependency metadata**
- **Found during:** Task 1
- **Issue:** `forge init --empty` installed `forge-std`, conflicting with the plan's single dependency boundary.
- **Fix:** Removed the incidental submodule and its lock entry, leaving only the required `v4-core` pin.
- **Files modified:** `.gitmodules`, `evm/foundry.lock`, `evm/lib/v4-core`
- **Verification:** Lock metadata contains the v4-core pin only; build and artifact checks pass.
- **Committed in:** `e83b77b`

---

**Total deviations:** 2 auto-fixed (2 blocking).
**Impact on plan:** Both changes retained the requested dependency identity and scaffold-only scope.

## Issues Encountered

- The repository had pre-existing whitespace errors in unrelated dirty `README.md` and `TODO.md`; scoped diff checks for all plan files pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The reproducible EVM import boundary is ready for the Phase 2 Seaport differential base. No bridge, FFI, or SqrtGrid integration was introduced.

## Self-Check: PASSED

- All created files exist and both task commits (`e83b77b`, `7886db2`) are present.
- `forge build --root evm`, `forge test --root evm`, SHA, remapping, artifact-hygiene, and scoped diff checks pass.

---
*Phase: 01-forge-evm-v3-core*
*Completed: 2026-09-08*
