---
phase: 2
slug: seaport-differential-base
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-09-08
---

# Phase 2 — Validation Strategy

> Observed locally on 2026-09-08 after Plans 02-01 and 02-02. The Phase 2 contract deliberately has two outcomes: D-12/D-15 require a green compile, while D-16 requires the matched runtime suite to fail non-zero with the named HEVM-stub marker.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Foundry / Forge |
| **Config file** | `evm/foundry.toml` |
| **Quick run command** | `forge build --root evm` |
| **Full phase command** | `git submodule update --init --recursive && forge build --root evm && out="$(forge test --root evm --match-contract HevmDiffTest -vv 2>&1)"; rc=$?; printf '%s\n' "$out"; test "$rc" -ne 0 && grep -q 'hevm.call not wired' <<< "$out"` |
| **Estimated runtime** | ~1–3 minutes cold (Seaport submodule) |

---

## Sampling Rate

- **After every task commit:** `forge build --root evm`
- **After every plan wave:** build + assert HevmDiffTest still fails
- **Before `$gsd-verify-work`:** same
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | EVM-03 | T-2-01 | Pin `v4-core@v4.0.0`, `seaport@1.6`, and dedicated `forge-std@v1.16.1` with committed remappings | integration | `git submodule update --init --recursive && test "$(git -C evm/lib/seaport rev-parse HEAD)" = e9c5a9f17cb5ee658ccc9cb1a8eeab02c1f5a4cd && forge build --root evm` | ✅ observed | ✅ pass |
| 02-01-02 | 01 | 1 | EVM-03 | T-2-03 | Reach the explicit HEVM adapter boundary rather than silently skipping Side B | intentional fail | `out="$(forge test --root evm --match-contract HevmDiffTest -vv 2>&1)"; rc=$?; test "$rc" -ne 0 && grep -q 'hevm.call not wired' <<< "$out"` | ✅ observed | ✅ pass |
| 02-02-01 | 02 | 2 | EVM-03 | T-2-01, T-2-03, T-2-04 | CI rejects pin/remapping drift, compilation failure, an unrelated test failure, and a silently green HEVM stub | workflow integration | `git submodule update --init --recursive && forge build --root evm && out="$(forge test --root evm --match-contract HevmDiffTest -vv 2>&1)"; rc=$?; test "$rc" -ne 0 && grep -q 'hevm.call not wired' <<< "$out"` | ✅ observed | ✅ pass |
| 02-02-02 | 02 | 2 | EVM-03 | T-2-01, T-2-03, T-2-04 | Validation evidence remains executable and records the distinct green-build/intentional-RED outcomes | documentation gate | `grep -q 'nyquist_compliant: true' .planning/phases/02-seaport-differential-base/02-VALIDATION.md && grep -q 'wave_0_complete: true' .planning/phases/02-seaport-differential-base/02-VALIDATION.md && ! grep -q 'TBD' .planning/phases/02-seaport-differential-base/02-VALIDATION.md` | ✅ observed | ✅ pass |

---

## Wave 0 Requirements

- [x] Install `seaport@1.6` + dedicated `forge-std`; remappings
- [x] `evm/test/diff/DiffTestBase.sol`
- [x] `evm/src/HevmTickMathHarness.sol` stub revert
- [x] `evm/test/diff/TickMath.Hevm.diff.t.sol` with `test_getSqrtPriceAtTick_isValidMinTick`
- [x] CI pin asserts + RED assert step
- [x] `evm/README` notes Phase 2 RED doctrine

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Same `test_*` name as Uniswap | EVM-03 / D-05 | Source review | Compare to `TickMath.t.sol` name |

---

This source-name comparison is supplementary evidence only; every Phase 2 task has the automated gate recorded above.

## Observed Evidence

- `git submodule update --init --recursive` completed with the committed top-level gitlinks at `e50237c43811bd9b526eff40f26772152a42daba` (`v4-core`), `e9c5a9f17cb5ee658ccc9cb1a8eeab02c1f5a4cd` (Seaport), and `620536fa5277db4e3fd46772d5cbc1ea0696fb43` (forge-std).
- All three committed remappings were observed in `evm/remappings.txt`.
- `forge build --root evm` completed successfully.
- The matched `HevmDiffTest` command exited non-zero and its output contained `hevm.call not wired`.

## Validation Sign-Off

- [x] All tasks have an automated verification command and observed artifact status
- [x] Wave 0 requirements completed and verified locally
- [x] D-12/D-15 green compilation and D-16 matched runtime failure are separately asserted
- [x] `nyquist_compliant: true` after complete local validation

**Approval:** automated evidence recorded; ready for phase verification.
