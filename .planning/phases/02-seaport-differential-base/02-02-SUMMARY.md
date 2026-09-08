---
phase: 02-seaport-differential-base
plan: 02
subsystem: ci
tags: [github-actions, foundry, forge, solidity, supply-chain, differential-testing]
requires:
  - phase: 02-seaport-differential-base
    provides: "Pinned Seaport differential tracer with an explicit HEVM stub boundary"
provides:
  - "Recursive CI checkout with exact v4-core, Seaport, and forge-std provenance assertions"
  - "A required green Forge compilation gate followed by a cause-specific intentional-RED differential gate"
  - "Nyquist-compliant Phase 2 validation evidence for EVM-03"
affects: [03-bridge-submodule, 04-tickmath-diff-red, ci]
tech-stack:
  added: []
  patterns:
    - "CI preserves and inspects expected-failure status and output rather than treating any non-zero exit as success"
    - "Dependency gitlinks, lockfile revisions, and remappings are asserted together before compilation"
key-files:
  created:
    - .planning/phases/02-seaport-differential-base/02-02-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - .planning/phases/02-seaport-differential-base/02-VALIDATION.md
key-decisions:
  - "Require the matched HevmDiffTest suite to exit non-zero and emit hevm.call not wired, keeping the Phase 2 adapter seam intentionally RED."
  - "Treat exact gitlink revisions, lockfile entries, and remapping aliases as a single provenance contract before Forge compilation."
patterns-established:
  - "Forge CI gates an expected runtime failure only when both its status and its stable cause marker are verified."
requirements-completed: [EVM-03]
coverage:
  - id: D1
    description: "Forge CI recursively initializes dependencies and rejects drift in v4-core, Seaport, forge-std, lockfile revisions, and remappings."
    requirement: EVM-03
    verification:
      - kind: integration
        ref: "git submodule update --init --recursive; revision/remapping assertions; forge build --root evm"
        status: pass
    human_judgment: false
  - id: D2
    description: "CI accepts the Phase 2 differential suite only when HevmDiffTest fails at the explicit hevm.call not wired seam."
    requirement: EVM-03
    verification:
      - kind: integration
        ref: "forge test --root evm --match-contract HevmDiffTest -vv; non-zero status plus hevm.call not wired marker"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Phase 2 validation map records executable evidence for every task and the separate compile-success and runtime-failure contracts."
    requirement: EVM-03
    verification:
      - kind: other
        ref: "02-VALIDATION.md frontmatter, task map, and sign-off assertions"
        status: pass
    human_judgment: false
duration: 4 min
completed: 2026-09-08
status: complete
---

# Phase 2 Plan 02: CI Red Gate Summary

**Forge CI now proves all Phase 2 dependency pins, requires a clean compilation, and accepts the differential tracer only when it reaches the named unwired HEVM seam.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-08T16:24:00Z
- **Completed:** 2026-09-08T16:28:00Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Extended the Forge CI job's recursive checkout with exact gitlink, lockfile, and remapping assertions for v4-core, Seaport 1.6, and dedicated forge-std v1.16.1.
- Kept `forge build --root evm` as its own required green gate, then added a matched `HevmDiffTest` gate that requires both non-zero status and `hevm.call not wired` output.
- Replaced all validation-map TBD entries with observed automated evidence, marked Wave 0 complete, and documented the distinct compile-success and intentional-runtime-failure outcomes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Gate exact dependency provenance, green compilation, and cause-specific RED** - `a894c02` (chore)
2. **Task 2: Finalize the executable Phase 2 validation contract** - `54a8c4e` (docs)

## Files Created/Modified

- `.github/workflows/ci.yml` - verifies exact dependency provenance, retains the independently green Forge build, and tests the intentional RED seam by status and marker.
- `.planning/phases/02-seaport-differential-base/02-VALIDATION.md` - supplies the Nyquist-compliant per-task evidence and completed Wave 0 sign-off.

## Decisions Made

- A non-zero differential result alone is insufficient: the CI gate also requires `hevm.call not wired`, so unrelated failures cannot satisfy Phase 2's RED contract.
- The workflow asserts gitlinks, lockfile revisions, and remapping aliases together because any one source alone cannot prove the resolved import provenance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Normalized state-plan fields for the GSD lifecycle command**
- **Found during:** Plan close-out
- **Issue:** The existing `STATE.md` used a prose `Plans` row, so `state.advance-plan` could not parse the current and total plan counts.
- **Fix:** Added the canonical `Current Plan` and `Total Plans in Phase` fields, then reran the lifecycle transition successfully.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `state.advance-plan` returned `reason: "last_plan"` and `status: "ready_for_verification"`.
- **Committed in:** plan metadata commit

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** The state-format normalization was necessary for reliable close-out metadata only; CI behavior and Phase 2 scope are unchanged.

## Issues Encountered

`git diff --check` reports whitespace errors in the user-modified root `README.md` and `TODO.md`. Those files are outside this plan and were not changed or staged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 2's reproducible CI contract is complete. Phase 3 can replace only the stub body in `HevmTickMathHarness` with bridge wiring; when that happens, this intentionally RED CI assertion must be updated as part of the phase contract change.

## Self-Check: PASSED

- Task commits `a894c02` and `54a8c4e` exist.
- The CI workflow and validation map exist at their planned paths.
- Recursive submodule initialization, exact top-level revision/remapping checks, `forge build --root evm`, and the non-zero/marker HevmDiffTest assertion passed locally.

---
*Phase: 02-seaport-differential-base*
*Completed: 2026-09-08*
