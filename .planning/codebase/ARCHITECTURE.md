# Architecture

**Analysis Date:** 2026-09-08

## Pattern Overview

**Overall:** Layered spec-reference monorepo — pure numeric Haskell twin, optional Cairo plotting, Lean 4 proofs, and protocol design docs — with no runtime server or persistent application state.

**Key Characteristics:**
- Single Stack package (`cfmm-vol-markets-spec`) split into a **plot-free public library** and an **internal `plot` library**
- Domain modules mirror CFMM / Panoptic / vol-instrument concepts in EVM-fixed-point types (`SqrtPriceX96`, `PayoffX96`, `Integer` mulDiv chains)
- Batch executable generates PNG evidence under `outputs/`; test suite is one long IO regression script
- Lean layer (`lean/`) formalizes theorems referenced in `README.md` and `notes/`; `protocol/` holds reactive-system design separate from Haskell
- Downstream consumers (e.g. `evm-spec-bridge` per `package.yaml`) depend only on the pure `src/` library

## Layers

**Numeric core (`src/`):**
- Purpose: Executable reference implementation of tick math, payoffs, liquidity, pricing, and Panoptic encodings in Solidity-compatible fixed-point arithmetic
- Contains: Domain modules (`SqrtGrid`, `Liquidity/*`, `Payoffs/*`, `Pricing/*`, `Trading/*`, `Greeks/*`, `Volatility/*`, `Panoptic/*`, `Hedge/*`) plus root helpers (`TickPath`, `StrikeX96`, `OptionRatio`, `TargetVega`, `State`)
- Depends on: `base`, `vector`, `mwc-random` only — no Chart, no IO in library modules
- Used by: `plot/` adapters, `app/Main.hs`, `test/Spec.hs`, external packages

**Visualization (`plot/`):**
- Purpose: Turn numeric functions into Chart layouts and PNG panels without polluting the public library
- Contains: `Plotting/*` (layout utilities, sqrt-axis helpers) and `Plot/*` (domain-specific layout functions mirroring `src/` structure)
- Depends on: `cfmm-vol-markets-spec`, `Chart`, `Chart-cairo`, `colour`
- Used by: `app/Main.hs`, `test/Spec.hs` (canvas size checks)

**Application shell (`app/`):**
- Purpose: Batch plot generation — comparative statics and spec evidence figures
- Contains: `Main.hs` only — wires `src/` payoffs/pricing to `plot/` layouts, writes to `outputs/`
- Depends on: public library + internal `plot` + `directory`
- Used by: Stack executable `cfmm-vol-markets-spec-exe`

**Regression harness (`test/`):**
- Purpose: Numeric identity checks, Panoptic bit-packing regressions, finite-difference witnesses, and layout smoke tests
- Contains: `Spec.hs` — monolithic `main :: IO ()` with custom `assertEqual` / `assertThrows` (not HUnit/Tasty)
- Depends on: public library + `plot` + `Chart` (inline layout construction)
- Used by: `stack test` in CI

**Formal proofs (`lean/`):**
- Purpose: Machine-checked theorems for vol markets, eta experiments, and TAO tokenomics
- Contains: Three Lake libs — `exp.*`, `vol_markets.*`, `tao.*` (see `lakefile.toml` roots)
- Depends on: Mathlib 4.28; LeanEVM was removed (2026-07-16) pending on-chain proof work
- Used by: `lake build` CI job; cross-referenced from `notes/agents/vol_markets/LEAN_TRACEABILITY.md`

**Notation & agent specs (`notes/`):**
- Purpose: Human-readable spec anchor (`VOLATILITY_INSTRUMENTS.md`) and role-specific addenda under `notes/agents/{vol_markets,exp,tao}/`
- Contains: Markdown only — bridges README theorems to Lean module names and open design questions
- Depends on: Nothing executable
- Used by: Authors, Lean/Haskell implementers, protocol designers

**Protocol design (`protocol/`):**
- Purpose: Reactive-system architecture for on-chain vol instruments (entities, communication sequences, integration refs)
- Contains: `REQUIREMENTS.md`, `COMMUNICATION/`, `entities/types/`, `protocol_integrations/`, `refs/cfmm-discrete/`, controller examples
- Depends on: Conceptual alignment with `src/` and `notes/` — not compiled
- Used by: Solidity / reactive-contract design; informs what the Haskell twin must remain compatible with

## Data Flow

**Plot generation (primary executable path):**

1. `stack exec cfmm-vol-markets-spec-exe` runs `app/Main.hs`
2. `Main` creates `outputs/{Pricing,Payoffs,Greeks,Liquidity,TickPath,Volatility}/` trees
3. Coordinate primitives come from `SqrtGrid` (`sqrtPriceX96`, `tickFromSqrtPriceX96`, `mulX96`, `mulDiv`) and `State` patterns (`SQRT_PRICE_1_4`, `SQRT_PRICE_4_1`)
4. Domain objects are assembled: `VolOrder` → `Panoptic.Binning` / `NId` mint plans; `LiquidityChunk.createChunk` for unit chunks; `Payoff` functions over `SqrtPriceX96`
5. Pricing layer (`Pricing.Stremia`, `FeeStructure`, `PriceDeformation`) produces bid/ask-deformed quotes and return paths
6. `plot/` modules wrap numeric functions as `Layout` values; `Plotting.PlotUtils.writePanel` renders PNGs
7. Artifacts land in `outputs/` (committed or regenerated locally)

**Numeric regression (test path):**

1. `stack test` runs `test/Spec.hs`
2. Same `src/` modules exercised with fixed fixtures (e.g. `mkNId 32`, `AtmForward (sqrtPriceX96 0)`)
3. Assertions verify: Q96 arithmetic, forward/log payoffs, chunk amounts, Panoptic tokenId bit fields, ladder replication theorems, path accrual identities
4. Failures `error` with descriptive strings; success prints `ok:` lines to stdout

**Tick / sqrtPrice → payoff / liquidity chain (conceptual spine):**

```
Tick i  ──sqrtPriceX96──▶  SqrtPriceX96 p
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
  Payoffs.Payoff        LiquidityChunk      Pricing.Quote
  (p ↦ PayoffX96)       (i⁻, i⁺, L packed)  (bid/ask deformation)
         │                    │                    │
         └──────────┬─────────┴────────────────────┘
                    ▼
           Panoptic.NId / VolOrder / Binning
                    │
         ┌──────────┴──────────┐
         ▼                     ▼
    plot/ layouts          test/Spec assertions
         ▼
    outputs/*.png
```

**Synthetic paths (`TickPath`):**
- `Volatility.VolTermStructure` drives random tick walks via `TickPath.mkTickPath`
- Used for vol-surface and path-dependent accrual plots (`Payoffs.PathAccrual`, `Payoffs.HolderPath`)

**State Management:**
- Stateless per run — no database or session store
- File outputs under `outputs/` and optional `refs/` inputs
- `core/` holds stale GHC artifacts (`.hi`/`.o`), not authoritative state

## Key Abstractions

**Fixed-point grid (`SqrtGrid`):**
- Purpose: Uniswap v3 tick base (λ = 1.0001), Q96 words, tick spacing, and EVM-faithful `mulDiv`
- Examples: `src/SqrtGrid.hs`, `src/StrikeX96.hs`
- Pattern: Newtypes over `Integer`; pattern synonym `Q96`; errors on invalid spacing

**Payoff functor (`Payoffs.Payoff`):**
- Purpose: Underlying-indexed payoff maps `u → PayoffX96` with add/sub/scale and strike variation
- Examples: `src/Payoffs/Payoff.hs`, instrument modules (`Forward`, `Log`, `VolatilityReplica`, `PathAccrual`)
- Pattern: `newtype Payoff u`; composition without committing to a single coordinate until applied

**Liquidity chunk (`Liquidity.LiquidityChunk`):**
- Purpose: Packed `(tickLower, tickUpper, liquidity)` with `amount0`/`amount1` at a sqrt price — CLMM identity carrier
- Examples: `src/Liquidity/LiquidityChunk.hs`, `LiquidityGrid.hs`, `TickLiquidity.hs`
- Pattern: Bit-packed `Integer` newtype; `createChunk` validates u128 bounds

**Panoptic encoding (`Panoptic.NId`, `MintPlan`):**
- Purpose: Hop A (optional-space scale `N_id`) and Hop B (EVM `tokenId` + SFPM `positionSize`) from `VolOrder`
- Examples: `src/Panoptic/NId.hs`, `Binning.hs`, `LegChunk.hs`, `MintPlan.hs`
- Pattern: Bit-field encode/decode; `volOrderToMintPlan` / `volOrderToTokenId` bridge vol spec to on-chain layout

**Mark-up / fee structures (`Pricing.*`):**
- Purpose: Two-sided fees, stremia bid/ask, adaptive fee configs, expected returns along tenor
- Examples: `Pricing.MarkUpStructure`, `FeeStructure`, `Stremia`, `AdaptiveStremia`, `TransactionalFeeCapture`
- Pattern: Typeclass for mark-up (`MarkUpStructure`); concrete fee pips grids for plots

**Vol order & replication ladder (`Volatility.VolOrder`, `Payoffs.LadderPosition`):**
- Purpose: Vol instrument spec → geometric ladder → T0/T1/T2 replication chain (README theorems 7–10)
- Examples: `src/Volatility/VolOrder.hs`, `src/Payoffs/LadderPosition.hs`, `src/Payoffs/VolatilityReplica.hs`
- Pattern: Fixture constructors + span/binning pipeline through `Panoptic.Binning`

**Panel grid (`Plotting.PlotUtils.Panel`):**
- Purpose: Type-level row/column grid for multi-panel PNG exports
- Examples: `plot/Plotting/PlotUtils.hs`, used heavily in `app/Main.hs`
- Pattern: GADT `Panel r c` with `Cell`, `Beside`, `Above`, `Vacant`

## Entry Points

**Plot executable:**
- Location: `app/Main.hs` (Stack target `cfmm-vol-markets-spec-exe`)
- Triggers: `stack exec cfmm-vol-markets-spec-exe` or CI build (exe compiled, not always run in CI)
- Responsibilities: Generate full `outputs/` figure set — pricing deformation, payoffs, Greeks, liquidity grids, path accrual panels, Panoptic replication sweeps

**Test suite:**
- Location: `test/Spec.hs` (Stack target `cfmm-vol-markets-spec-test`)
- Triggers: `stack test` (required CI job alongside `stack build --pedantic`)
- Responsibilities: Regression gate for numeric twin — Panoptic packing, payoff identities, ladder theorems, chart layout dimensions

**Lean build:**
- Location: `lakefile.toml` → libs `exp`, `vol_markets`, `tao`
- Triggers: `lake build` in CI (~7 min with Mathlib cache)
- Responsibilities: Compile proof modules; CI fails on `sorry`/`admit`

**Library API (for downstream):**
- Location: `src/` modules exported via implicit module list (no central re-export bar stub `Lib.hs`)
- Triggers: `build-depends: cfmm-vol-markets-spec` in external packages
- Responsibilities: Pure numeric API for tick math, payoffs, and Panoptic encodings without plotting deps

## Error Handling

**Strategy:** Fail fast with `error "Module.function: …"` on invariant violations; no structured error monad in the numeric core.

**Patterns:**
- Guard clauses in smart constructors (`mkNId`, `mkTickSpacing`, `createChunk`, `mkTickPath`)
- Test harness uses `assertThrows` wrapping `Control.Exception.try` for expected failures
- Plot executable assumes valid fixtures — no recovery path for bad parameters
- Lean CI treats compiler `sorry`/`admit` warnings as build failures

## Cross-Cutting Concerns

**EVM fidelity:**
- All new model arithmetic in `src/` should use `SqrtGrid.mulDiv` staged chains (comment in `SqrtGrid.hs` references FullMath / Solidity twin)
- `Payoffs.Log` documents EVM `sdiv`/`byte` semantics on unbounded `Integer`
- Types (`SqrtPriceX96`, `PayoffX96`) map directly to on-chain word sizes

**Plot / core separation:**
- Enforced in `package.yaml`: public library has no Chart dependency; `plot` is `internal-libraries`
- Keeps `evm-spec-bridge` and similar consumers lightweight

**Spec traceability:**
- `README.md` theorems cite Lean module names and Haskell modules
- `notes/agents/vol_markets/LEAN_TRACEABILITY.md` maps open proof obligations
- `TODO.md` tracks GitHub issues/PRs per open item (workflow in `AGENTS.md`)

**CI:**
- `.github/workflows/ci.yml`: parallel Stack (build+test) and Lean (lake build, no sorry) jobs
- Cairo system libs required for Chart-cairo on Ubuntu

**Formal vs executable gap:**
- LeanEVM removed from `lakefile.toml`; on-chain proof harness not yet restored
- Haskell twin is the primary executable reference until HEVM/LeanEVM layer returns

---

*Architecture analysis: 2026-09-08*
*Update when major patterns change*
