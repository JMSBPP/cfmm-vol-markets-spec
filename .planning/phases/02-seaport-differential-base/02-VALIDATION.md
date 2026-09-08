---
phase: 2
slug: seaport-differential-base
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-08
---

# Phase 2 — Validation Strategy

> Seeded from `02-CONTEXT.md` (research skipped by user). Update after execute if commands change.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Foundry / Forge |
| **Config file** | `evm/foundry.toml` |
| **Quick run command** | `forge build --root evm` |
| **Full suite command** | `forge build --root evm && (forge test --root evm --match-contract HevmDiffTest; test $? -ne 0)` |
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
| TBD | 01 | 1 | EVM-03 | T-2-01 | Pin seaport@1.6 | build | `forge build --root evm` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | EVM-03 | T-2-02 | HevmDiffTest RED | intentional fail | `forge test --root evm --match-contract HevmDiffTest` exits ≠0 | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] Install `seaport@1.6` + dedicated `forge-std`; remappings
- [ ] `evm/test/diff/DiffTestBase.sol`
- [ ] `evm/src/HevmTickMathHarness.sol` stub revert
- [ ] `evm/test/diff/TickMath.Hevm.diff.t.sol` with `test_getSqrtPriceAtTick_isValidMinTick`
- [ ] CI pin asserts + RED assert step
- [ ] `evm/README` notes Phase 2 RED doctrine

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Same `test_*` name as Uniswap | EVM-03 / D-05 | Source review | Compare to `TickMath.t.sol` name |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 deps
- [ ] `nyquist_compliant: true` after execute validates

**Approval:** pending
