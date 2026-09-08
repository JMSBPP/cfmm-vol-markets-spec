# HEVM Bit-Identical Vol-Markets Twin

## What This Is

A GSD track inside `cfmm-vol-markets-spec` (`scratchpad/`) to make the Haskell `src/` twin of CFMM vol/variance instruments **fully EVM bit-identical**. TDD starts in a local Foundry tree **`evm/`**: Seaport-style differential tests (vol-markets pattern) over Uniswap **`TickMath`**, with HEVM reached via **`JMSBPP/evm-spec-bridge` `feat/2-hevm-call-stdcheats`** (`hevm.call`). Once that oracle is RED/GREEN, rewrite **`SqrtGrid`** so the **same plots and tests** stay green under bit-identical arithmetic — then expand outward so EVM-adapted code can replace today’s non-identical `.hs` paths.

## Core Value

**Plots and tests stay green, and the numeric core is bit-identical to the EVM** — the Forge TickMath differential + `hevm.call` is the oracle that makes that guarantee real, not aspirational.

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

- [ ] Create **`evm/`** Foundry project; `forge install` **`v3-core@0.8`**
- [ ] First TDD wedge: **Seaport-style TickMath differential** (`*.diff.t.sol` / `t.sol`) over existing TickMath.sol unit-test corpus (vol-markets pattern)
- [ ] Drive HEVM via **`evm-spec-bridge` submodule** (`feat/2-hevm-call-stdcheats` / `hevm.call`) — on bridge failure: **issue on submodule + notify user** (forward to bridge agent)
- [ ] Make **`SqrtGrid`** EVM bit-identical in Haskell so the differential goes green
- [ ] Existing **plots and `stack test` stay green** after the rewrite (same consumer APIs)
- [ ] Document which `Double` leaks are closed vs deferred (`docs/BITWIDTHS.md` alignment)
- [ ] Expand the same hybrid pattern to later EVM-realizable modules after TickMath/SqrtGrid

### Out of Scope

- Replacing the entire `src/` surface with on-VM execution in v1 — hybrid: Forge diff + Haskell rewrite; in-VM hot paths only if needed later
- Owning the Foundry↔HEVM **relay product** — consume `feat/2-hevm-call-stdcheats`, do not fork the relay
- Continuum `VariancePortfolio` as an on-chain object — not EVM-realizable; replica remains the realizable path
- Parent `cfmm-theory` GSD project (Shreve / discrete-calculus) — separate planning root
- Rewriting Lean proofs or Chart/`plot/` internals for their own sake

## Context

- **Repo:** `cfmm-vol-markets-spec` (git root = this directory). Canonical upstream `d2p-finance/cfmm-vol-markets-spec`; fork `JMSBPP`.
- **Intent:** Multiple `src/` modules are an EVM-semantics twin of vol_markets (payoffs, variance/vol, Panoptic packing). HEVM is being brought in so that twin is *provably* EVM-faithful.
- **Bridge:** `evm-spec-bridge` as a **git submodule** (branch **`feat/2-hevm-call-stdcheats`**) — `hevm.call` via ffi→relay. Local reference worktree: `apps/evm_spec_rpc/.worktrees/hevm-call-stdcheats`.
- **Submodule failure protocol:** file issue on the bridge repo + notify user with URL/brief for forwarding to the bridge agent — do not silently absorb bridge bugs here.
- **Pattern ref:** vol-markets `test/diff/PlankDiffTestBase.sol` + `*.diff.t.sol` (Seaport `DifferentialTest`).
- **Known debt (from map):** `OptionRatio`/`StrikeX96`/tick→sqrt `Double` leaks; `SqrtGrid.sqrtPriceX96` not TickMath-identical; chunk×density EVM mul open.
- **Phase-1 wedge:** Forge `evm/` TickMath Seaport differential (TDD); then Haskell `SqrtGrid`.

## Constraints

- **Tech:** Stack LTS 24.55 / GHC 9.10.3; public library must remain plot-free (`base`, `vector`, `mwc-random` only today)
- **Compatibility:** Consumer APIs used by `plot/`, `app/`, `test/Spec.hs` must not break — same plots and tests
- **Bit-identity:** No “close enough” on HEVM-gated paths — fixtures must match EVM words
- **Submodule:** `evm-spec-bridge` is a submodule; bridge defects → issue on submodule + user notify (forward to bridge agent)
- **Planning:** Local `.planning/` only; do not overwrite parent `cfmm-theory/.planning/`

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local GSD project in `scratchpad/` | Distinct from parent Shreve verification track | — Pending |
| First TDD component = Seaport TickMath differential in `evm/` | Reuse existing TickMath.sol tests; vol-markets `DifferentialTest` pattern | — Pending |
| Forge `evm/` + `v3-core@0.8` | Local Foundry twin; pin Uniswap TickMath as Solidity reference | — Pending |
| `evm-spec-bridge` as submodule + `hevm.call` | Consume `feat/2-hevm-call-stdcheats`; do not reinvent relay/cheats | — Pending |
| Bridge failures → submodule issue + user notify | Keeps ownership on bridge agent; this package does not silent-patch | — Pending |
| Then rewrite `SqrtGrid` | Foundation for all Q96/tick math once the Forge oracle is RED/GREEN | — Pending |
| Done bar = bit-identical + same plots/tests | EVM-adapted code aims to *replace* non-identical `.hs` arithmetic under stable consumers | — Pending |
| Hybrid replacement (option 3) | Forge+HEVM differential first; Haskell bit-identical rewrite; on-VM later only if needed | — Pending |

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
*Last updated: 2026-09-08 after requirements refinement (Forge TickMath diff + hevm-call-stdcheats)*
