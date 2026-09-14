# Phase 3: Bridge submodule - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-08
**Phase:** 3-Bridge submodule
**Areas discussed:** Harness wire-up (only)

---

## Gray area selection

| Option | Description | Selected |
|--------|-------------|----------|
| 1 Submodule path + pin | Where under repo; tip vs floating branch | |
| 2 Solc / remapping | Bump to ≥0.8.34 vs isolate bridge | |
| 3 Harness wire-up | Live `hevm.call` vs import-only | ✓ |

**User's choice:** `3`

---

## Area — Harness wire-up

### Q1 — What should Phase 3 change in the harness?

| Option | Description | Selected |
|--------|-------------|----------|
| 1 Live `hevm.call` | Replace stub; GREEN with relay; loud fail without | ✓ (with 3) |
| 2 Import-only | Submodule + remaps; stub stays RED | |
| 3 Dual path | Profile/env live path; else distinct “relay down” revert | ✓ (with 1) |

**User's choice:** `1 and 3` plus freeform prerequisite: `EVM.hs` as dependency for `SqrtGrid.hs` so it is queryable under `hevm.call`.

**Notes:** User clarified `EVM.hs` is **already** under the Hackage **`hevm`** Cabal dependency — not a greenfield file in this repo.

### Q2 — How does Phase 3 attach `SqrtGrid` to `hevm`’s `EVM`? (reframed)

| Option | Description | Selected |
|--------|-------------|----------|
| 1 Declare `hevm` + thin adapter | build-depends + small surface for one method | ✓ |
| 2 Depend only | Add `hevm`; leave SqrtGrid API unchanged | |
| 3 Defer Cabal wire | Submodule + Solidity only; Haskell later | |

**User's choice:** `1`

### Q3 — Where does the thin adapter live?

| Option | Description | Selected |
|--------|-------------|----------|
| 1 This package | `src/` imports `EVM`; owns HEVM-facing entry | ✓ |
| 2 Bridge / evm_spec_rpc | Method registration on bridge side | |
| 3 Both | Pure entry here + bridge method | |

**User's choice:** `1`

### Q4 — How thin is Phase 3’s Haskell surface?

| Option | Description | Selected |
|--------|-------------|----------|
| 1 One method only | `getSqrtPriceAtTick` / min-tick GREEN | ✓ |
| 2 Full TickMath API mirror | All methods; stubs OK | |
| 3 Adapter shell only | Wiring through `EVM`; float SqrtGrid body | |

**User's choice:** `1`

### Q5 — Default / CI behavior for the dual path?

| Option | Description | Selected |
|--------|-------------|----------|
| 1 Default stays RED | Optional GREEN job with relay | |
| 2 CI requires GREEN | CI starts relay+HEVM; min-tick must pass | ✓ |
| 3 CI build-only | Docs for local live path | |

**User's choice:** `2`

---

## Done

User replied **`done`** — remaining gray areas (submodule path, solc) left to agent discretion / planning.

## the agent's Discretion

- Submodule path + pin SHA vs floating branch
- Solc 0.8.28 vs bridge `^0.8.34`
- Exact `hevm` Cabal/Stack wiring and adapter module naming
- Dual-path gate string and CI relay bring-up details

## Deferred Ideas

- Full TickMath corpus → Phase 4
- Bit-identical SqrtGrid → Phases 6–7
- Undiscussed gray areas 1–2 still required as implementation choices
