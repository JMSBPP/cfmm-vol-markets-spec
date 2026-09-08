# HEVM Bit-Identical Vol-Markets Twin

## What This Is

A GSD track inside `cfmm-vol-markets-spec` (`scratchpad/`) to make the Haskell `src/` twin of CFMM vol/variance instruments **fully EVM bit-identical**, proven under in-process **HEVM** (`hevm` → `EVM.hs`). The destination is hybrid: rewrite the numeric core so the **same plots and tests** keep working, but every hot path is guaranteed to match EVM semantics — starting with `SqrtGrid`, then expanding outward so EVM-adapted code can eventually replace today’s non-identical `.hs` arithmetic.

## Core Value

**Plots and tests stay green, and the numeric core is bit-identical to the EVM** — HEVM is the oracle that makes that guarantee real, not aspirational.

## Requirements

### Validated

<!-- Inferred from existing codebase map (.planning/codebase/). Relied upon today. -->

- ✓ Plot-free public Haskell library under `src/` with EVM-oriented fixed-point types (`SqrtPriceX96`, `PayoffX96`, `mulDiv`) — existing
- ✓ Internal `plot/` + `app/Main.hs` produce PNG evidence under `outputs/` — existing
- ✓ Monolithic regression suite `test/Spec.hs` gates CI — existing
- ✓ Lean 4 proofs (`lean/`) and notation anchor (`notes/VOLATILITY_INSTRUMENTS.md`) — existing
- ✓ Downstream consumers (`evm-spec-bridge` / `evm_spec_rpc` cfmm-adapter) depend on the pure library only — existing
- ✓ Codebase map for this repo — `.planning/codebase/` (2026-09-08)

### Active

<!-- Hypotheses until shipped and validated. -->

- [ ] Wire **in-process `hevm`** into this package (test/extra-dep; keep public lib plot-free)
- [ ] Make **`SqrtGrid`** (Q96 / `mulDiv` / tick↔sqrt) **EVM bit-identical** in Haskell
- [ ] HEVM **oracle tests** prove `SqrtGrid` fixtures match EVM / reference bytecode semantics
- [ ] Existing **plots and `stack test` stay green** after the rewrite (same consumer APIs)
- [ ] Document which `Double` leaks are closed vs deferred (`docs/BITWIDTHS.md` alignment)
- [ ] Expand the same hybrid pattern to the next EVM-realizable modules (e.g. `LiquidityChunk`, replica paths) after SqrtGrid

### Out of Scope

- Replacing the entire `src/` surface with on-VM execution in v1 — hybrid: Haskell rewrite + HEVM oracle first; in-VM hot paths only if needed later
- Full Foundry↔HEVM relay product work (lives in `evm_spec_rpc`; may integrate later, not this milestone’s core)
- Continuum `VariancePortfolio` as an on-chain object — not EVM-realizable; replica remains the realizable path
- Parent `cfmm-theory` GSD project (Shreve / discrete-calculus) — separate planning root
- Rewriting Lean proofs or Chart/`plot/` internals for their own sake

## Context

- **Repo:** `cfmm-vol-markets-spec` (git root = this directory). Canonical upstream `d2p-finance/cfmm-vol-markets-spec`; fork `JMSBPP`.
- **Intent:** Multiple `src/` modules are an EVM-semantics twin of vol_markets (payoffs, variance/vol, Panoptic packing). HEVM is being brought in so that twin is *provably* EVM-faithful.
- **Dependency:** Hackage `hevm` (e.g. 0.58.0) exposes `EVM.hs` — symbolic/concrete EVM evaluator. Not yet in `package.yaml` / `stack.yaml`.
- **Known debt (from map):** `OptionRatio`/`StrikeX96`/tick→sqrt `Double` leaks; `SqrtGrid.sqrtPriceX96` not TickMath-identical; chunk×density EVM mul open.
- **Phase-1 wedge:** `SqrtGrid` — foundation every other bit-identical path sits on.

## Constraints

- **Tech:** Stack LTS 24.55 / GHC 9.10.3; public library must remain plot-free (`base`, `vector`, `mwc-random` only today)
- **Compatibility:** Consumer APIs used by `plot/`, `app/`, `test/Spec.hs` must not break — same plots and tests
- **Bit-identity:** No “close enough” on HEVM-gated paths — fixtures must match EVM words
- **Planning:** Local `.planning/` only; do not overwrite parent `cfmm-theory/.planning/`

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local GSD project in `scratchpad/` | Distinct from parent Shreve verification track | — Pending |
| First component = `SqrtGrid` | Foundation for all Q96/tick math; map flags tick→sqrt as non-identical | — Pending |
| In-process `hevm` in this repo | Direct oracle next to `src/`; not deferred entirely to bridge | — Pending |
| Done bar = bit-identical + same plots/tests | EVM-adapted code aims to *replace* non-identical `.hs` arithmetic under stable consumers | — Pending |
| Hybrid replacement (option 3) | Rewrite Haskell to bit-identical + HEVM tests first; on-VM execution later only if needed | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-08 after initialization*
