# Requirements: HEVM Bit-Identical Vol-Markets Twin

**Defined:** 2026-09-08  
**Refined:** 2026-09-08 — Forge `evm/` + Seaport-style TickMath differential (TDD); monitor `JMSBPP/evm-spec-bridge` `feat/2-hevm-call-stdcheats`  
**Source:** PROJECT.md + research SUMMARY.md + user refinement  

## Process (TDD)

1. Stand up **`evm/`** as a Foundry project inside this repo.  
2. **`forge install` Uniswap `v4-core@v4.0.0`** with the `v4-core/` remapping and locked release revision.
3. First RED→GREEN wedge: a **Seaport-pattern differential test** (vol-markets `*.diff.t.sol` / `DifferentialTest` style) over the **already-written `TickMath.sol` unit-test corpus**, in a `t.sol` / `TickMath.diff.t.sol` suite.  
4. Drive HEVM through **`hevm.call`** from **`evm-spec-bridge` as a git submodule** (`feat/2-hevm-call-stdcheats`: StdCheats-style `vm.ffi` → relay → HEVM). Do not reinvent the cheat surface. **On submodule failure → open an issue on the bridge repo and notify the user** (forwardable to the bridge agent).  
5. Only after the TickMath differential is meaningful: rewrite Haskell `SqrtGrid` so plots/`stack test` stay green **and** match the EVM side bit-for-bit.

## v1 Requirements

### Forge `evm/` scaffold
- [x] **EVM-01**: `evm/` is a working Foundry project (`foundry.toml`, `src/`, `test/`, remappings) under this repo root
- [x] **EVM-02**: Uniswap **`v4-core@v4.0.0`** is installed as a Forge dependency and v4 TickMath is importable
- [ ] **EVM-03**: Seaport (or vendored `DifferentialTest` equivalent matching vol-markets) is available for the diff-test base — same pattern as `vol-markets` `test/diff/PlankDiffTestBase.sol`

### TickMath differential (first component — TDD)
- [ ] **TICK-01**: Differential suite (`*.diff.t.sol` / `t.sol`) reuses the **existing TickMath.sol test cases** as the input corpus (not a hand-waved new vector set)
- [ ] **TICK-02**: Seaport-style exec: run the same `Context` twice with swapped oracles / implementations, then assert **exact** equality (tol 0); non-vacuity (`diffComparisons > 0`)
- [ ] **TICK-03**: One side is canonical v4-core `TickMath`; the other side is reached via **`hevm.call`** (bridge stdcheats path) and/or the Haskell twin once wired — TDD starts RED on the HEVM/Haskell seam
- [ ] **TICK-04**: Suite documents skip/probe doctrine if the HEVM relay is down (vol-markets SpecHelper pattern: no silent green)

### Bridge / HEVM cheat surface
- [ ] **BRIDGE-01**: **`evm-spec-bridge` enters as a git submodule** (pin `feat/2-hevm-call-stdcheats` / agreed commit) providing `hevm.call(method, paramsJson)` via `vm.ffi` → `relay send`
- [ ] **BRIDGE-02**: Local docs note required relay/`FOUNDRY_PROFILE=hevm` (or equivalent) for the diff suite CI job
- [ ] **BRIDGE-03**: **Submodule failure protocol** — if anything fails that is attributable to the bridge (build, `hevm.call`, relay, ffi, stdcheats surface):
  1. **Open a GitHub issue on the submodule repo** (`JMSBPP/evm-spec-bridge` / upstream as appropriate) with repro, expected vs actual, and this package’s commit/submodule SHA
  2. **Notify the user in-chat** with the issue URL and a short paste-ready brief so they can **forward it to the bridge agent**
  3. Do **not** silently patch around bridge bugs inside this package unless the user directs a temporary workaround

### SqrtGrid bit-identity (after TickMath diff is green)
- [ ] **SQRT-01**: `sqrtPriceX96` matches TickMath bit-for-bit under the differential oracle
- [ ] **SQRT-02**: Inverse tick-from-sqrt matches TickMath bit-for-bit
- [ ] **SQRT-03**: `mulDiv` matches FullMath words **and** revert classes where in scope
- [ ] **SQRT-04**: HEVM-/diff-gated paths use exact equality — no tolerance

### Compatibility
- [ ] **COMPAT-01**: Existing `test/Spec.hs` stays green after SqrtGrid rewrite
- [ ] **COMPAT-02**: Existing plot/`app` consumers keep working (same public APIs)
- [ ] **COMPAT-03**: Public Haskell library remains plot-free and does not take HEVM as a library dependency

### Scope ledger
- [ ] **SCOPE-01**: `docs/BITWIDTHS.md` (or linked manifest) marks paths as exact / oracle-tested / deferred / off-chain

## v2 Requirements (deferred)

- Full in-process Haskell `hevm` library suite as a second oracle (optional parallel to Foundry path)
- Differential QuickCheck / proof-carrying fixture corpus expansion
- Cross-layer parity ladder (`LiquidityChunk`, replica)
- Integer `OptionRatio` / density→Panoptic mapping
- Mass `Double` purge across Greeks/RAN/κ

## Out of Scope

- Running all of `src/` inside the EVM  
- Reinventing `hevm.call` / relay (use `feat/2-hevm-call-stdcheats`)  
- Foundry↔HEVM relay product ownership (stays on `evm-spec-bridge`)  
- Tolerance-based “parity” on diff-gated paths  
- Parent `cfmm-theory` Shreve/discrete GSD track  

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| EVM-01 | 1 | Complete |
| EVM-02 | 1 | Complete |
| EVM-03 | 2 | Pending |
| BRIDGE-01 | 3 | Pending |
| BRIDGE-02 | 3 | Pending |
| BRIDGE-03 | 3 | Pending |
| TICK-01 | 4 | Pending |
| TICK-02 | 4 | Pending |
| TICK-04 | 4 | Pending |
| TICK-03 | 5 | Pending |
| SQRT-01 | 6 | Pending |
| SQRT-02 | 6 | Pending |
| SQRT-04 | 6–7 | Pending |
| SQRT-03 | 7 | Pending |
| COMPAT-01 | 8 | Pending |
| COMPAT-02 | 8 | Pending |
| COMPAT-03 | 8 | Pending |
| SCOPE-01 | 8 | Pending |

## User Stories & Acceptance Criteria

- **As** the package maintainer, **I want** a Forge `evm/` TickMath Seaport-style differential test driven by existing TickMath unit cases and `hevm.call`, **so that** TDD proves EVM bit-identity before rewriting `SqrtGrid`.
  - AC: EVM-01..03, TICK-01..04, BRIDGE-01..02.
- **As** a downstream pure-library consumer, **I want** no HEVM forced into the Haskell public lib, **so that** RPC adapters stay lightweight.
  - AC: COMPAT-03.

## Definition of Done (v1)

- `evm/` Forge project builds; `Uniswap/v4-core@v4.0.0` installed
- TickMath Seaport differential suite exists and is non-vacuous when HEVM relay is up  
- `hevm.call` path uses `feat/2-hevm-call-stdcheats`  
- SqrtGrid rewritten to pass that oracle; Spec/plots green  
- BITWIDTHS/scope ledger updated  

---
*Requirements defined: 2026-09-08; refined 2026-09-08*
