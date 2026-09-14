---
phase: 02-seaport-differential-base
verified: 2026-09-08T16:28:00Z
status: passed
score: 7/7
behavior_unverified: 0
overrides_applied: 0
---

# Phase 2: Seaport Differential Base Verification Report

**Phase Goal:** Diff-test infrastructure matching vol-markets Seaport `DifferentialTest` pattern  
**Verified:** 2026-09-08T16:28:00Z  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Pinned Seaport 1.6 and dedicated top-level forge-std resolve through the required remappings. | ✓ VERIFIED | `.gitmodules`, `evm/foundry.lock`, `evm/remappings.txt`, and `evm/foundry.toml` agree on Seaport `e9c5a9f17cb5ee658ccc9cb1a8eeab02c1f5a4cd`, forge-std `620536fa5277db4e3fd46772d5cbc1ea0696fb43`, and the required aliases. Recursive submodule status confirms the checked-out top-level gitlinks. |
| 2 | A Seaport-style base supplies `DifferentialTest` / `assertPass` helpers and non-vacuity support. | ✓ VERIFIED | `DiffTestBase` imports and inherits `@seaport/utils/DifferentialTest.sol`; it provides `diffComparisons`, `_requireComparisonRan`, and `_runDiff`. The upstream base implements `assertPass` with the stateless passing-revert encoding. |
| 3 | `HevmDiffTest` compiles an upstream-named minimum-tick client path with swapped `Context` oracle and later non-vacuity guard. | ✓ VERIFIED | The suite imports `v4-core/src/test/TickMathTest.sol`, uses `canonical.MIN_TICK()` and `canonical.MIN_SQRT_PRICE()`, runs Side A, swaps `context.oracle` to `HevmTickMathHarness`, increments `diffComparisons`, and invokes `_requireComparisonRan`. `forge test --root evm --list` discovers exactly `test_getSqrtPriceAtTick_isValidMinTick` under `HevmDiffTest`. |
| 4 | The nested Foundry project builds successfully. | ✓ VERIFIED | `forge build --root evm` exited 0. |
| 5 | The matched skeleton suite is intentionally RED specifically at the unwired HEVM adapter. | ✓ VERIFIED | `forge test --root evm --match-contract HevmDiffTest -vv` exited 1 and reported `[FAIL: hevm.call not wired] test_getSqrtPriceAtTick_isValidMinTick()`. `HevmTickMathHarness.getSqrtPriceAtTick` always reverts with that marker. |
| 6 | CI enforces dependency pins, a green build, and the cause-specific RED contract. | ✓ VERIFIED | `.github/workflows/ci.yml` uses recursive checkout, compares all three gitlink SHAs and lock/remapping metadata, runs `forge build --root evm`, then rejects both an exit-zero `HevmDiffTest` run and any non-zero run lacking `hevm.call not wired`. |
| 7 | No Phase 3–6 implementation was pulled forward. | ✓ VERIFIED | Local Phase 2 Solidity contains no `evm-spec-bridge`, `vm.ffi`, relay, or live `hevm.call` wiring. The only local differential test function is the single minimum-tick skeleton; no full TickMath corpus or SqrtGrid implementation was added. Vendor-library references to unrelated `Hevm`/FFI utilities were excluded from this scope check. |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `evm/test/diff/DiffTestBase.sol` | Thin Seaport wrapper with comparison non-vacuity helpers | ✓ VERIFIED | Exists, is substantive, imports Seaport `DifferentialTest`, and supplies the specified helpers. |
| `evm/src/HevmTickMathHarness.sol` | Deliberately reverting Phase 2 HEVM seam | ✓ VERIFIED | Exists and has a single TickMath-facing method that always reverts `hevm.call not wired`; instantiated by `HevmDiffTest`. |
| `evm/test/diff/TickMath.Hevm.diff.t.sol` | Compiling minimum-tick differential tracer | ✓ VERIFIED | Exists, is the compiled and enumerated `HevmDiffTest`, and executes the canonical client before reaching the HEVM seam. |
| `evm/foundry.lock` | Resolved revisions for v4-core, Seaport, and forge-std | ✓ VERIFIED | Contains all three tag/revision pairs asserted by CI. |
| `.github/workflows/ci.yml` | Recursive provenance, green build, and cause-specific RED gates | ✓ VERIFIED | Implements each gate as executable workflow shell logic. |
| `.planning/phases/02-seaport-differential-base/02-VALIDATION.md` | Executable EVM-03 validation map | ✓ VERIFIED | Identifies EVM-03, all four plan tasks, automated commands, threat references, and separate compile/intentional-failure outcomes. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `DiffTestBase.sol` | `evm/lib/seaport/test/foundry/utils/DifferentialTest.sol` | `@seaport/utils/DifferentialTest.sol` import and inheritance | ✓ WIRED | Import resolves through the checked remapping; `DiffTestBase is DifferentialTest`. |
| `TickMath.Hevm.diff.t.sol` | `evm/lib/v4-core/src/test/TickMathTest.sol` | `v4-core` remapped import used as Side A | ✓ WIRED | `TickMathTest` is imported, instantiated in `setUp`, and used for the minimum tick/value. |
| `TickMath.Hevm.diff.t.sol` | `evm/src/HevmTickMathHarness.sol` | Side B oracle selected through `Context` | ✓ WIRED | The harness is imported, instantiated in `setUp`, assigned to `context.oracle`, and invoked through `this.fn`. |
| CI RED gate | `HevmDiffTest` | matched Forge invocation plus exit/cause assertion | ✓ WIRED | Workflow captures output and checks non-zero exit plus the adapter marker. |

### Data-Flow Trace (Level 4)

Not applicable. The Phase 2 artifacts are Solidity utilities and a deterministic test harness; they do not render or fetch dynamic application data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Foundry compilation | `forge build --root evm` | Exit 0; compilation skipped because artifacts were current. | ✓ PASS |
| Skeleton test discovery | `forge test --root evm --list` | Listed `HevmDiffTest.test_getSqrtPriceAtTick_isValidMinTick`. | ✓ PASS |
| Intentional RED reaches the dedicated seam | `forge test --root evm --match-contract HevmDiffTest -vv` | Exit 1; one failure, marker `hevm.call not wired`. | ✓ PASS |
| Exact top-level dependency state | `git submodule status --recursive` | Top-level forge-std, Seaport, and v4-core match the three locked revisions. | ✓ PASS |

### Probe Execution

No phase-declared or conventional probe scripts were found. This phase’s runnable verification is the Foundry build and matched test command above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| EVM-03 | `02-01-PLAN.md`, `02-02-PLAN.md` | Seaport (or a matching vendored equivalent) is available for the vol-markets-style diff-test base. | ✓ SATISFIED | Installed Seaport 1.6 `DifferentialTest` is directly inherited by the compiled local base; CI locks its provenance and validates the intentional test boundary. |

No Phase 2 orphaned requirements were found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `evm/src/HevmTickMathHarness.sol` | 5 | Explicit Phase 3 replacement seam | ℹ️ Info | Intentional scope boundary, not a placeholder: the method deliberately reverts and the matched test/CI gate proves that specific outcome. |

The Phase-owned Solidity files contain no untracked `TODO`, `TBD`, `FIXME`, `XXX`, `HACK`, or placeholder markers. The working tree has unrelated user changes in root `README.md`, `TODO.md`, `.worktrees/`, and `image.jpeg`; they were not considered phase artifacts.

### Disconfirmation Checks

- The RED test is not treated as a passing test: the workflow explicitly fails if its exit code is zero, and also rejects an unrelated non-zero failure.
- The adapter has no fallback value or revert-catching path that could turn the missing bridge into a vacuous success.
- `diffComparisons` is intentionally reached only after the future Side B returns. In this phase’s RED-only contract, execution instead proves that Side B is reached by surfacing the harness marker; the counter/guard is present for the later GREEN path and no live bridge was falsely claimed.

## Gaps Summary

No blocking gaps found. The phase delivers the requested buildable differential base and deliberately failing HEVM seam; bridge wiring and corpus expansion remain explicitly deferred to Phases 3–5.

---

_Verified: 2026-09-08T16:28:00Z_  
_Verifier: gsd-verifier_

## VERIFICATION PASSED
