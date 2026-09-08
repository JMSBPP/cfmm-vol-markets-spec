---
phase: 1
slug: forge-evm-v3-core
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-08
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `01-RESEARCH.md` § Validation Architecture. CONTEXT locks `Uniswap/v4-core@v4.0.0` (not roadmap `v3-core@0.8`).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Foundry / Forge |
| **Config file** | `evm/foundry.toml` — Wave 0 creates it |
| **Quick run command** | `forge build --root evm` |
| **Full suite command** | `forge build --root evm && forge test --root evm` |
| **Estimated runtime** | ~30–90 seconds (cold), ~5–15s warm |

---

## Sampling Rate

- **After every task commit:** Run `forge build --root evm`
- **After every plan wave:** Run `forge build --root evm && forge test --root evm`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | 01 | 1 | EVM-01 | T-1-01 | No cache/out committed | build smoke | `forge build --root evm` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | EVM-02 | T-1-02 | Pin SHA = v4.0.0 tip | compile + pin check | `forge build --root evm && git -C evm/lib/v4-core rev-parse HEAD` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Required assertions (from research):**
1. `forge build --root evm` exits zero
2. `forge remappings --root evm` includes `v4-core/=lib/v4-core/` (or equivalent alias documented in plan)
3. `git -C evm/lib/v4-core rev-parse HEAD` equals `e50237c43811bd9b526eff40f26772152a42daba`
4. `git diff --check` clean after tracking files added

---

## Wave 0 Requirements

- [ ] `evm/foundry.toml` — pinned compiler and explicit remapping
- [ ] `evm/src/TickMathHarness.sol` (or equivalent) — import/linkage smoke for EVM-02
- [ ] `evm/remappings.txt` and/or `evm/foundry.lock` — reproducibility records
- [ ] Root `.gitignore` or `evm/.gitignore` for `cache/`, `out/`, `broadcast/`
- [ ] No unit/differential test file required for Phase 1 — compiling wrapper is the smoke

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ROADMAP/REQUIREMENTS wording v3→v4 | docs chore | Text review | Confirm install phrase cites `v4-core@v4.0.0` |

*All build/import behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
