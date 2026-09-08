---
phase: 03-bridge-submodule
plan: 01
subsystem: bridge
tags: [foundry, ffi, hevm, unix-sockets, git-submodule]
requires:
  - phase: 02-seaport-differential-base
    provides: "A compiling Foundry differential seam with pinned dependencies"
provides:
  - "Pinned evm-spec-bridge gitlink and mirrored Foundry remapping"
  - "Opt-in HEVM profile with default-profile FFI isolation"
  - "Consumer-owned raw JSON hevm.call transport probe with bounded relay lifecycle"
affects: [03-02, 03-03, bridge, ci]
tech-stack:
  added: [JMSBPP/evm-spec-bridge]
  patterns:
    - "Bridge provenance is asserted across gitlink, lock metadata, and remappings"
    - "Host FFI is enabled only through profile.hevm"
    - "Relay processes use finite readiness loops and EXIT-trap cleanup"
key-files:
  created:
    - evm/lib/evm-spec-bridge
    - evm/test/bridge/HevmCallProbe.t.sol
    - scripts/hevm-bridge-transport-smoke.sh
  modified:
    - .gitmodules
    - evm/foundry.lock
    - evm/foundry.toml
    - evm/remappings.txt
    - evm/src/TickMathHarness.sol
key-decisions:
  - "Pin evm-spec-bridge directly under evm/lib at aad230528f93be04a00d0209f10eaa3084d84de5."
  - "Use solc 0.8.34 globally while retaining FFI as an explicit profile.hevm opt-in."
patterns-established:
  - "Transport probes compare hevm.call output as raw JSON bytes, never ABI returndata."
  - "Consumer smoke scripts derive trusted executables from the pinned bridge Stack install root."
requirements-completed: [BRIDGE-01, BRIDGE-02]
coverage:
  - id: D1
    description: "The consumer pins and imports evm-spec-bridge at the reviewed commit through one mirrored remapping."
    requirement: BRIDGE-01
    verification:
      - kind: integration
        ref: "gitlink/lock/remapping assertions and forge build --root evm"
        status: pass
    human_judgment: false
  - id: D2
    description: "The default Forge profile keeps FFI disabled while profile.hevm enables the trusted bridge path."
    requirement: BRIDGE-02
    verification:
      - kind: integration
        ref: "forge config --root evm --json and FOUNDRY_PROFILE=hevm forge config --root evm --json"
        status: pass
    human_judgment: false
  - id: D3
    description: "A bounded consumer smoke proves hevm.call returns exact raw JSON result bytes through relayd."
    requirement: BRIDGE-01
    verification:
      - kind: e2e
        ref: "bash scripts/hevm-bridge-transport-smoke.sh"
        status: pass
    human_judgment: false
duration: 3 min
completed: 2026-09-08
status: complete
---

# Phase 3 Plan 01: Bridge Transport Tracer Summary

**A pinned `evm-spec-bridge` now supplies an opt-in FFI transport whose bridge-owned and consumer-owned raw JSON probes both pass end to end.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-08T19:03:04Z
- **Completed:** 2026-09-08T19:05:41Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Pinned `JMSBPP/evm-spec-bridge` at `aad230528f93be04a00d0209f10eaa3084d84de5` across the direct gitlink and Foundry lock metadata.
- Compiled the consumer graph with solc 0.8.34 using one mirrored bridge remapping, with FFI false by default and true only under `profile.hevm`.
- Added a consumer-owned transport diagnostic that starts pinned relay processes, proves exact raw JSON bytes `[1]`, and deterministically reaps processes and sockets.

## Task Commits

Each task was committed atomically:

1. **Task 1: Pin and execute the bridge-owned hevm.call transport tracer** - `d1b402c` (chore)
2. **Task 2 RED: Add the failing consumer raw JSON contract** - `817827c` (test)
3. **Task 2 GREEN: Add the bounded transport runner** - `35a719a` (feat)

## Files Created/Modified

- `.gitmodules` - registers the direct bridge submodule.
- `evm/lib/evm-spec-bridge` - records the reviewed bridge gitlink.
- `evm/foundry.lock` - records the bridge revision.
- `evm/foundry.toml` - selects solc 0.8.34, adds the bridge remapping, and defines `profile.hevm`.
- `evm/remappings.txt` - mirrors the bridge import alias.
- `evm/src/TickMathHarness.sol` - widens the local pragma range for the required compiler.
- `evm/test/bridge/HevmCallProbe.t.sol` - asserts exact raw JSON output through imported `hevm.call`.
- `scripts/hevm-bridge-transport-smoke.sh` - owns the bounded relayd/echo lifecycle for the consumer probe.

## Decisions Made

- The bridge remains an immutable direct submodule under `evm/lib`; no bridge source was copied or modified.
- Solc 0.8.34 is the shared compiler because the imported bridge requires `^0.8.34`; FFI remains disabled unless the HEVM profile is selected.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Widened the exact local compiler pragma**
- **Found during:** Task 1
- **Issue:** `TickMathHarness.sol` pinned exactly Solidity 0.8.28, preventing the required 0.8.34 consumer build.
- **Fix:** Changed the local harness pragma to compatible `^0.8.28` without altering runtime behavior.
- **Files modified:** `evm/src/TickMathHarness.sol`
- **Verification:** Default and HEVM-profile `forge build --root evm` both pass with solc 0.8.34.
- **Committed in:** `d1b402c`

**2. [Rule 3 - Blocking] Normalized the plan position after lifecycle parsing**
- **Found during:** Plan close-out
- **Issue:** The pre-existing prose value `03-01 (next to execute)` parsed as plan 3, causing `state.advance-plan` to report the three-plan phase complete after only 03-01.
- **Fix:** Normalized the current position to plan 2 of 3 and restored the in-progress phase status after the roadmap correctly counted one summary.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `STATE.md` points to plan 03-02, while `ROADMAP.md` reports Phase 3 as 1/3 In Progress.
- **Committed in:** plan metadata commit

---

**Total deviations:** 2 auto-fixed (2 blocking).
**Impact on plan:** Both fixes were required for compilation and correct GSD lifecycle ownership; no bridge code or numerical behavior changed.

## Issues Encountered

None beyond the compiler-pragma deviation documented above. The bridge-owned transport smoke passed, so BRIDGE-03 escalation was not triggered.

## TDD Gate Compliance

- RED commit `817827c`: the probe failed at `hevm.call: ffi failed` before lifecycle wiring.
- GREEN commit `35a719a`: the bounded HEVM-profile runner made the exact raw JSON probe pass.

## User Setup Required

None - the smoke runner builds and provisions its short-lived local relay stack.

## Next Phase Readiness

The transport tracer and trust boundary are ready for 03-02's EVM-backed TickMath peer. Fake echo remains limited to this transport diagnostic and is not TickMath acceptance.

## Self-Check: PASSED

- All eight planned or required compatibility artifacts exist.
- Task commits `d1b402c`, `817827c`, and `35a719a` exist.
- Gitlink, lock SHA, remappings, compiler, profile flags, both transport smokes, and the final default build passed.

---
*Phase: 03-bridge-submodule*
*Completed: 2026-09-08*
