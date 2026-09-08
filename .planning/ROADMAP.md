# Roadmap: HEVM Bit-Identical Vol-Markets Twin

## Overview

Stand up a Foundry `evm/` twin, consume `evm-spec-bridge` as a submodule for `hevm.call`, drive a Seaport-style TickMath differential (TDD) over existing TickMath unit tests, then rewrite Haskell `SqrtGrid` until plots and `stack test` stay green under exact EVM bit-identity. Vertical MVP: each phase leaves a runnable slice.

## Phases

- [x] **Phase 1: Forge `evm/` + v4-core** - Scaffold Foundry project and pin `Uniswap/v4-core@v4.0.0`
- [ ] **Phase 2: Seaport differential base** - Wire `DifferentialTest` pattern (vol-markets style)
- [ ] **Phase 3: Bridge submodule** - Add `evm-spec-bridge`, docs, failure→issue protocol
- [ ] **Phase 4: TickMath diff RED** - Corpus from existing TickMath tests; Seaport exec; non-vacuity / skip doctrine
- [ ] **Phase 5: `hevm.call` seam** - Second oracle via stdcheats; TICK-03 RED→probe
- [ ] **Phase 6: SqrtGrid TickMath port** - Bit-identical `sqrtPriceX96` / inverse under the oracle
- [ ] **Phase 7: SqrtGrid `mulDiv`** - FullMath word + revert parity on gated paths
- [ ] **Phase 8: Compat + scope ledger** - Spec/plots green; lib HEVM-free; BITWIDTHS updated

## Phase Details

### Phase 1: Forge `evm/` + v4-core

**Goal:** `evm/` Foundry project builds and imports Uniswap v4 TickMath from `Uniswap/v4-core@v4.0.0`
**Mode:** mvp
**Depends on:** Nothing (first phase)
**Requirements:** EVM-01, EVM-02
**Success Criteria** (what must be TRUE):

  1. `forge build` succeeds under `evm/`
  2. TickMathHarness imports the v4 TickMath API through the committed `v4-core/` remapping
  3. The exact v4.0.0 tag and resolved SHA are recorded in remappings, lock, and README

**Plans:** 1/1 plans complete

Plans:

- [x] 01-01-PLAN.md
- [x] 01-01: Pinned Foundry TickMath walking skeleton

### Phase 2: Seaport differential base

**Goal:** Diff-test infrastructure matching vol-markets Seaport `DifferentialTest` pattern
**Mode:** mvp
**Depends on:** Phase 1
**Requirements:** EVM-03
**Success Criteria** (what must be TRUE):

  1. A base contract (or remapped Seaport utils) provides `DifferentialTest` / `assertPass`-style helpers
  2. A trivial smoke `.diff.t.sol` compiles and demonstrates swap-context + non-vacuity counters

**Plans:** 1/2 plans executed

Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Trace one upstream TickMath case through Seaport to the intentional RED HEVM seam

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 02-02-PLAN.md — Enforce exact pins, green compilation, and cause-specific RED in CI

### Phase 3: Bridge submodule

**Goal:** `evm-spec-bridge` submodule provides `hevm.call`; failure protocol documented
**Mode:** mvp
**Depends on:** Phase 2
**Requirements:** BRIDGE-01, BRIDGE-02, BRIDGE-03
**Success Criteria** (what must be TRUE):

  1. Submodule is present and pinned; `hevm.call` is importable from the Forge tree
  2. Docs state relay / `FOUNDRY_PROFILE=hevm` (or equivalent) prerequisites
  3. AGENTS/REQUIREMENTS submodule failure protocol is referenced from `evm/` README

**Plans:** TBD

Plans:

- [ ] 03-01: Add submodule at agreed branch/commit
- [ ] 03-02: Remap `Hevm.sol` / profile notes
- [ ] 03-03: Document BRIDGE-03 issue+notify protocol in `evm/`

### Phase 4: TickMath diff RED

**Goal:** Seaport TickMath differential suite exists over existing TickMath unit-test corpus (RED/scaffold OK)
**Mode:** mvp
**Depends on:** Phase 3
**Requirements:** TICK-01, TICK-02, TICK-04
**Success Criteria** (what must be TRUE):

  1. Suite reuses existing TickMath.sol test cases as input corpus
  2. Same `Context` executed twice with swapped sides; tol-0 assert pattern; `diffComparisons > 0` when run
  3. Skip/probe doctrine documented — no silent green when HEVM/relay unavailable

**Plans:** TBD

Plans:

- [ ] 04-01: Map TickMath.t.sol corpus → FuzzArgs/Context
- [ ] 04-02: `TickMath.diff.t.sol` / `t.sol` Seaport exec scaffold
- [ ] 04-03: Skip/probe + non-vacuity guards

### Phase 5: `hevm.call` seam

**Goal:** Second side of the differential reaches HEVM via `hevm.call` (TICK-03)
**Mode:** mvp
**Depends on:** Phase 4
**Requirements:** TICK-03
**Success Criteria** (what must be TRUE):

  1. With relay up, differential exercises `hevm.call` for at least one TickMath vector path
  2. With relay down, suite skips or fails loudly per doctrine (never vacuous green)
  3. Bridge defects follow BRIDGE-03 (issue on submodule + user notify)

**Plans:** TBD

Plans:

- [ ] 05-01: HEVM-side oracle adapter via `hevm.call`
- [ ] 05-02: Wire into TickMath differential Context
- [ ] 05-03: CI/profile notes for relay-up job

### Phase 6: SqrtGrid TickMath port

**Goal:** Haskell `sqrtPriceX96` / inverse match TickMath bit-for-bit under the oracle
**Mode:** mvp
**Depends on:** Phase 5
**Requirements:** SQRT-01, SQRT-02, SQRT-04
**Success Criteria** (what must be TRUE):

  1. TickMath extrema vectors pass exact equality vs Haskell
  2. Inverse tick-from-sqrt matches including half-open max bound
  3. No tolerance on HEVM-/diff-gated assertions

**Plans:** TBD

Plans:

- [ ] 06-01: Integer TickMath port in `SqrtGrid.hs`
- [ ] 06-02: Inverse port + domain guards
- [ ] 06-03: Differential GREEN for tick↔sqrt

### Phase 7: SqrtGrid `mulDiv`

**Goal:** Staged `mulDiv` matches FullMath words and revert classes on gated paths
**Mode:** mvp
**Depends on:** Phase 6
**Requirements:** SQRT-03, SQRT-04
**Success Criteria** (what must be TRUE):

  1. Success cases match FullMath words exactly
  2. Denom-zero / overflow cases match revert classification
  3. Staged chains are not fused contrary to BITWIDTHS discipline

**Plans:** TBD

Plans:

- [ ] 07-01: FullMath vectors under differential / oracle
- [ ] 07-02: Align `SqrtGrid.mulDiv` + callers
- [ ] 07-03: Revert-class assertions

### Phase 8: Compat + scope ledger

**Goal:** Consumers green; public lib HEVM-free; BITWIDTHS marks exact vs deferred
**Mode:** mvp
**Depends on:** Phase 7
**Requirements:** COMPAT-01, COMPAT-02, COMPAT-03, SCOPE-01
**Success Criteria** (what must be TRUE):

  1. `stack test` (existing Spec) passes
  2. Plot/`app` APIs unchanged and smoke OK
  3. Public library deps remain plot-/HEVM-free
  4. `docs/BITWIDTHS.md` (or manifest) updated for TickMath/`mulDiv` paths

**Plans:** TBD

Plans:

- [ ] 08-01: Spec + plot smoke after SqrtGrid rewrite
- [ ] 08-02: Verify package.yaml public lib constraints
- [ ] 08-03: Update BITWIDTHS / scope ledger

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Forge `evm/` + v4-core | 1/1 | Complete    | 2026-09-08 |
| 2. Seaport differential base | 1/2 | In Progress|  |
| 3. Bridge submodule | 0/TBD | Not started | - |
| 4. TickMath diff RED | 0/TBD | Not started | - |
| 5. `hevm.call` seam | 0/TBD | Not started | - |
| 6. SqrtGrid TickMath port | 0/TBD | Not started | - |
| 7. SqrtGrid `mulDiv` | 0/TBD | Not started | - |
| 8. Compat + scope ledger | 0/TBD | Not started | - |

---
*Roadmap created: 2026-09-08 — Vertical MVP, fine granularity*
