---
phase: 3
slug: bridge-submodule
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-09-08
---

# Phase 3 — Validation Strategy

> Observed after Plans 03-01 through 03-03. Live min-tick path is GREEN via
> `scripts/hevm-tickmath-relay.sh`; Phase 2 intentional-RED CI contract removed.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Forge + Stack |
| **Config file** | `evm/foundry.toml`, `stack.yaml`, `.github/workflows/ci.yml` |
| **Quick run command** | `forge build --root evm` |
| **Full suite command** | `bash scripts/hevm-tickmath-relay.sh` |
| **Estimated runtime** | ~1–10 minutes (cold Stack/hevm longer) |

---

## Sampling Rate

- **After every task commit:** `forge build --root evm` (+ targeted Stack when Haskell changes)
- **After every plan wave:** `bash scripts/hevm-tickmath-relay.sh`
- **Before `$gsd-verify-work`:** same + pin asserts
- **Max feedback latency:** 600 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | BRIDGE-01 | T-3-01 | Bridge pinned + remapped + builds | build | `test "$(git -C evm/lib/evm-spec-bridge rev-parse HEAD)" = aad230528f93be04a00d0209f10eaa3084d84de5 && forge build --root evm` | ✅ | ✅ pass |
| 03-01-02 | 01 | 1 | BRIDGE-02 | T-3-02 | Transport smoke via fake echo | integration | `bash scripts/hevm-bridge-transport-smoke.sh` | ✅ | ✅ pass |
| 03-02-01 | 02 | 2 | D-05–D-08 | T-3-05 | Probe returns canonical min-tick | Haskell | `stack exec -- hevm-tickmath-peer --probe -887272 --artifact evm/out/TickMathHarness.sol/TickMathHarness.json` = `4295128739` | ✅ | ✅ pass |
| 03-02-02 | 02 | 2 | D-02/D-03/D-09 | T-3-08 | Live GREEN + readiness marker | e2e | `bash scripts/hevm-tickmath-relay.sh` | ✅ | ✅ pass |
| 03-03-01 | 03 | 3 | BRIDGE-02/03 | T-3-11 | README runbook + BRIDGE-03 | docs | `grep -q BRIDGE-03 evm/README.md && grep -q FOUNDRY_PROFILE=hevm evm/README.md` | ✅ | ✅ pass |
| 03-03-02 | 03 | 3 | D-09 | T-3-14 | CI invokes relay runner; no RED assert | workflow | `grep -q hevm-tickmath-relay.sh .github/workflows/ci.yml && ! grep -q 'intentionally RED' .github/workflows/ci.yml` | ✅ | ✅ pass |
| 03-03-03 | 03 | 3 | BRIDGE-01..03 | — | Validation map complete | docs | this file flags true | ✅ | ✅ pass |

---

## Wave 0 Requirements

- [x] `evm/lib/evm-spec-bridge` submodule + remapping + pin
- [x] Private `HevmTickMathAdapter` + peer
- [x] Live harness + `scripts/hevm-tickmath-relay.sh`
- [x] CI GREEN relay-up job
- [x] `evm/README.md` BRIDGE-02/03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Open bridge issue + notify user | BRIDGE-03 | Conditional process | On attributable bridge fault: issue with SHAs/logs; paste URL in chat |

---

## Validation Sign-Off

- [x] All tasks have automated verification commands
- [x] Wave 0 complete
- [x] `nyquist_compliant: true`
- [x] Live min-tick observed GREEN locally via relay runner

**Approval:** 2026-09-08
