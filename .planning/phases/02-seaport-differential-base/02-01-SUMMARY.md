---
phase: 02-seaport-differential-base
plan: 01
subsystem: testing
tags: [foundry, solidity, seaport, differential-testing, tickmath, hevm]
requires:
  - phase: 01-forge-evm-v3-core
    provides: "Pinned v4-core TickMath source and nested Foundry project"
provides:
  - "Pinned Seaport 1.6 DifferentialTest dependency and top-level forge-std v1.16.1"
  - "A local Seaport DiffTestBase with stateless-pass and non-vacuity helpers"
  - "A compiling upstream-shaped TickMath minimum-tick tracer that fails only at the explicit HEVM seam"
affects: [02-02-ci-red-gate, 03-bridge-submodule, 04-tickmath-diff-red]
tech-stack:
  added: [ProjectOpenSea/seaport@1.6, foundry-rs/forge-std@v1.16.1]
  patterns:
    - "Top-level gitlink, lockfile, and remapping jointly pin every Foundry dependency"
    - "Seaport stateless Side A followed by raw HEVM Side B preserves a cause-specific RED failure"
key-files:
  created:
    - evm/test/diff/DiffTestBase.sol
    - evm/src/HevmTickMathHarness.sol
    - evm/test/diff/TickMath.Hevm.diff.t.sol
  modified:
    - .gitmodules
    - evm/foundry.lock
    - evm/foundry.toml
    - evm/remappings.txt
    - evm/README.md
key-decisions:
  - "Use Seaport 1.6 at e9c5a9f17cb5ee658ccc9cb1a8eeab02c1f5a4cd and a dedicated forge-std v1.16.1 at 620536fa5277db4e3fd46772d5cbc1ea0696fb43."
  - "Run Side A through Seaport's stateless success encoding and invoke Side B directly so the intentional hevm.call not wired marker remains observable."
patterns-established:
  - "Local differential suites live under evm/test/diff, while the replaceable HEVM adapter lives under evm/src."
requirements-completed: [EVM-03]
coverage:
  - id: D1
    description: "Seaport 1.6 DifferentialTest and dedicated forge-std v1.16.1 are reproducibly pinned for the local Forge project."
    requirement: EVM-03
    verification:
      - kind: integration
        ref: "git submodule update --init --recursive; forge build --root evm"
        status: pass
    human_judgment: false
  - id: D2
    description: "The upstream-named TickMath minimum-tick tracer compiles, executes canonical Side A, and reaches the explicit HEVM boundary."
    requirement: EVM-03
    verification:
      - kind: integration
        ref: "forge test --root evm --match-contract HevmDiffTest -vv"
        status: pass
    human_judgment: false
  - id: D3
    description: "Operator documentation distinguishes the green build from the intended cause-specific RED HEVM suite."
    requirement: EVM-03
    verification:
      - kind: other
        ref: "README provenance and command acceptance checks; forge build --root evm"
        status: pass
    human_judgment: false
duration: 3 min
completed: 2026-09-08
status: complete
---

# Phase 2 Plan 01: Seaport Differential Base Summary

**Seaport 1.6 now supplies a pinned differential-test base for a v4 TickMath minimum-tick tracer whose HEVM side fails loudly and reproducibly at the Phase 3 adapter seam.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-08T16:19:56Z
- **Completed:** 2026-09-08T16:23:10Z
- **Tasks:** 2/2
- **Files modified:** 10

## Accomplishments

- Pinned Seaport 1.6 and a dedicated forge-std v1.16.1 as top-level Forge gitlinks, with lockfile and remapping metadata.
- Added `DiffTestBase`, `HevmTickMathHarness`, and `HevmDiffTest` at the prescribed local layout.
- Proved `forge build --root evm` is green while the exact upstream-named minimum-tick test is intentionally RED with `hevm.call not wired`.
- Documented dependency provenance, execution commands, and the Phase 3/4 boundaries.

## Task Commits

Each task was committed atomically:

1. **Task 1: Trace one upstream TickMath case through Seaport to the RED HEVM seam** - `b3ebe57` (test)
2. **Task 2: Document dependency provenance and the intentional RED contract** - `f4b31fc` (docs)

## Files Created/Modified

- `.gitmodules` - records Seaport and top-level forge-std provenance beside v4-core.
- `evm/foundry.lock` - records all three resolved dependency revisions.
- `evm/foundry.toml` and `evm/remappings.txt` - configure consistent Seaport, forge-std, and v4-core imports without aliasing local `src/`.
- `evm/test/diff/DiffTestBase.sol` - exposes Seaport `assertPass`, `_runDiff`, and comparison non-vacuity helpers.
- `evm/src/HevmTickMathHarness.sol` - explicit Phase 3 replacement seam that always reverts.
- `evm/test/diff/TickMath.Hevm.diff.t.sol` - upstream-shaped minimum-tick Context/FuzzArgs differential tracer.
- `evm/README.md` - documents pin provenance and the green-build/RED-suite doctrine.

## Decisions Made

- Used a dedicated top-level forge-std so local diff infrastructure and suite imports share one `Test.sol`.
- Preserved the HEVM adapter's original revert on Side B instead of catching it, ensuring the RED gate can prove its cause rather than merely report a generic differential failure.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The differential architecture, dependency metadata, and intentional RED signal are ready for the Phase 2 CI gate. Phase 3 must replace only `HevmTickMathHarness` with the live bridge; Phase 4 expands the upstream TickMath corpus.

## Self-Check: PASSED

- All three planned Solidity artifacts exist and task commits `b3ebe57` and `f4b31fc` are present.
- `git submodule update --init --recursive` and `forge build --root evm` passed.
- `forge test --root evm --list` finds `test_getSqrtPriceAtTick_isValidMinTick`; the matched `HevmDiffTest` run exits non-zero and contains `hevm.call not wired`.

---
*Phase: 02-seaport-differential-base*
*Completed: 2026-09-08*
