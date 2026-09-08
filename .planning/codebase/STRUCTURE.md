# Codebase Structure

**Analysis Date:** 2026-09-08

## Directory Layout

```
scratchpad/                          # cfmm-vol-markets-spec repo root
├── app/                             # Stack executable entry (plot batch job)
├── src/                             # Pure numeric library (EVM-typed twin)
│   ├── Greeks/
│   ├── Hedge/
│   ├── Liquidity/
│   ├── Panoptic/
│   ├── Payoffs/
│   ├── Pricing/
│   ├── Trading/
│   └── Volatility/
├── plot/                            # Internal Chart library (mirrors src domains)
│   ├── Plot/
│   ├── Plotting/
│   └── Volatility/
├── test/                            # Regression harness (Spec.hs)
├── lean/                            # Lean 4 proof sources (Lake srcDir)
│   ├── exp/
│   ├── vol_markets/
│   └── tao/
├── notes/                           # Spec notation + agent addenda
│   └── agents/
├── protocol/                        # Reactive protocol design (not compiled)
│   ├── COMMUNICATION/
│   ├── entities/
│   ├── model/
│   ├── protocol_integrations/
│   └── refs/
├── outputs/                         # Generated PNG figures (from app/)
├── refs/                            # External reference markdown
├── docs/                            # Superpowers specs/plans
├── .planning/                       # GSD planning artifacts
├── package.yaml                     # Cabal/Stack package manifest
├── stack.yaml                       # Stackage snapshot
├── lakefile.toml                    # Lean 4 build config
└── README.md                        # Theorem catalog + model closure
```

Excluded from this map (per scope): `.worktrees/` (git worktrees), `.lake/packages/` (Mathlib vendoring), `.stack-work/`, `dist-newstyle/`, `core/` (stale `.hi`/`.o` only).

## Directory Purposes

**`src/`**
- Purpose: Plot-free Haskell reference for CFMM vol instruments — the authoritative numeric twin
- Contains: `*.hs` modules grouped by domain; root files for grid math and paths
- Key files:
  - `SqrtGrid.hs` — tick / Q96 / mulDiv primitives
  - `Payoffs/Payoff.hs` — payoff algebra
  - `Liquidity/LiquidityChunk.hs` — packed CLMM chunks
  - `Panoptic/NId.hs` — tokenId and mint plan encoding
  - `Volatility/VolOrder.hs` — vol instrument orders
  - `TickPath.hs` — synthetic tick paths for accrual demos
- Subdirectories: Eight domain folders plus loose root modules (`State.hs`, `OptionRatio.hs`, `TargetVega.hs`, `StrikeX96.hs`)

**`plot/`**
- Purpose: Visualization adapters; must not be imported by external consumers of the public library
- Contains: `Plotting/*` (shared layout/writePanel) and `Plot/*` (domain layouts parallel to `src/`)
- Key files:
  - `Plotting/PlotUtils.hs` — `Panel` GADT, `writePanel`, `canvasSize`
  - `Plotting/PlotSqrt.hs` — sqrt-axis plotting conventions
  - `Plot/Payoffs/PathAccrual.hs` — accrual panel layouts
  - `Plot/Liquidity/LiquidityGrid.hs` — liquidity surface plots
- Subdirectories: `Plot/{Payoffs,Pricing,Greeks,Liquidity}/`, `Plotting/`, `Volatility/CevField.hs`

**`app/`**
- Purpose: Single executable that generates the full `outputs/` figure set
- Contains: `Main.hs` (~650 lines) — imports both `src/` and `plot/`
- Key files: `Main.hs` — only entry point for the exe target

**`test/`**
- Purpose: Numeric and layout regression gate (CI required)
- Contains: `Spec.hs` (~2100 lines) — one `main` with sequential assertions
- Key files: `Spec.hs` — mirrors coverage of `src/` domains; no separate test modules

**`lean/`**
- Purpose: Lean 4 formalization; three libraries declared in `lakefile.toml`
- Contains: `.lean` proof modules under `exp/`, `vol_markets/`, `tao/`
- Key files:
  - `vol_markets/Main.lean` — vol markets entry
  - `vol_markets/LadderPrincipal.lean`, `ClmmIdentity.lean`, `LadderLimit.lean` — ladder replication chain
  - `vol_markets/MevOptimization.lean`, `MevJointProgram.lean` — MEV/tax algebra
  - `exp/EtaReplication.lean`, `MeanVarianceEta.lean` — eta experiments
- Subdirectories: Flat module folders per Lake lib root list

**`notes/`**
- Purpose: Human spec and traceability from prose → Lean → Haskell
- Contains: `VOLATILITY_INSTRUMENTS.md` (notation anchor) and `agents/{vol_markets,exp,tao}/*.md`
- Key files:
  - `VOLATILITY_INSTRUMENTS.md`
  - `agents/vol_markets/LEAN_TRACEABILITY.md`
  - `agents/vol_markets/VOLATILITY_INSTRUMENTS_*_ADDENDUM.md` (MEV, Greeks, IV, etc.)

**`protocol/`**
- Purpose: Reactive-system / on-chain integration design (SuD-oriented docs)
- Contains: Requirements, entity types, communication sequences, discrete CFMM refs
- Key files:
  - `REQUIREMENTS.md` — tick grid / variance market pseudocode
  - `COMMUNICATION/00_SEQUENCE.md`
  - `refs/cfmm-discrete/*.md` — coordinate and finance integration notes
  - `entities/types/{pos_spec,risk,exposure}.md`
  - `01_STATE_DELTA_ELASTICITY_CONTROLLER/EXAMPLES.md`

**`outputs/`**
- Purpose: PNG artifacts from `app/Main.hs`
- Contains: Subtrees `Pricing/`, `Payoffs/` (with `Replica/`, `Returns/`, `Accrual/`), `Greeks/`, `Liquidity/`, `TickPath/`, `Volatility/`
- Key files: Named by plot (e.g. `outputs/Payoffs/Replica/panel-t1-vs-t0.png`)

**`refs/`**
- Purpose: Imported external reference documents (MEV notes, volume path, GAMS inputs)
- Contains: Standalone markdown and auxiliary files (e.g. `volume_path.gms`)

**`docs/`**
- Purpose: Superpowers design specs and execution plans (scratchpad feature designs)
- Contains: `docs/superpowers/specs/`, `docs/superpowers/plans/`

## Key File Locations

**Entry Points:**
- `app/Main.hs` — plot batch executable (`cfmm-vol-markets-spec-exe`)
- `test/Spec.hs` — regression test main (`cfmm-vol-markets-spec-test`)
- `lakefile.toml` — Lean build roots (`exp`, `vol_markets`, `tao`)

**Configuration:**
- `package.yaml` — library/exe/test/plot split, GHC pedantic flags, dependencies
- `stack.yaml` — Stackage LTS 24.55 snapshot
- `lakefile.toml` — Mathlib pin, Lean lib roots; LeanEVM intentionally removed
- `lean-toolchain` — Lean compiler version pin (referenced by CI)
- `.github/workflows/ci.yml` — Stack build+test and `lake build` jobs

**Core Logic (by domain):**

| Domain | Primary location | Role |
|--------|------------------|------|
| SqrtGrid | `src/SqrtGrid.hs`, `src/StrikeX96.hs`, `src/State.hs` | Tick / Q96 coordinate system |
| Liquidity | `src/Liquidity/*.hs` | Chunks, grid, density, tick liquidity |
| Payoffs | `src/Payoffs/*.hs` | Instruments, accrual, replication, LVR |
| Pricing | `src/Pricing/*.hs` | Fees, stremia, returns, deformation |
| Trading | `src/Trading/*.hs` | Quotes, kappa coordinate, price impact |
| Greeks | `src/Greeks/*.hs` | Delta, gamma, vega, theta |
| Volatility | `src/Volatility/*.hs` | Vol orders, grids, IV, term structure |
| Panoptic | `src/Panoptic/*.hs` | NId, binning, leg chunks, mint plans |
| Hedge | `src/Hedge/Ledger.hs` | Hedging ledger |

**Testing:**
- `test/Spec.hs` — all Haskell regressions in one file

**Documentation:**
- `README.md` — theorems, model closure, implementation status
- `TODO.md` — open/done items with GitHub issue links
- `AGENTS.md` / `CLAUDE.md` — agent workflow for TODO → issue → PR
- `notes/VOLATILITY_INSTRUMENTS.md` — notation source of truth for Lean

## Naming Conventions

**Files:**
- PascalCase module names matching file stem: `LiquidityChunk.hs` → `module Liquidity.LiquidityChunk`
- Domain prefix directories mirror Haskell module hierarchy: `src/Payoffs/VolatilityReplica.hs`
- Plot modules prefix with `Plot.`: `plot/Plot/Payoffs/VolatilityReplica.hs`
- Markdown specs: `SCREAMING_SNAKE` or dated kebab in `docs/superpowers/specs/`

**Directories:**
- Singular domain names at top level (`app`, `plot`, `test`, `lean`, `notes`, `protocol`)
- Plural for output collections (`outputs`, `refs`, `docs`)
- Agent subfolders under `notes/agents/` match Lean lib names (`vol_markets`, `exp`, `tao`)

**Special Patterns:**
- `mk*` / `un*` smart constructors for newtypes (`mkNId`, `unLiquidityChunk`)
- `pattern Q96` and sqrt-price patterns in `SqrtGrid` / `State`
- PNG outputs named by phenomenon: `panel-*`, `*-vs-*`, domain subfolders under `outputs/`

## Where to Add New Code

**New payoff or instrument (numeric):**
- Primary code: `src/Payoffs/NewInstrument.hs`
- Plot (if needed): `plot/Plot/Payoffs/NewInstrument.hs`
- Wire into exe: `app/Main.hs` (add `writePanel` / `plotSqrtFunction` call)
- Tests: new assertion block in `test/Spec.hs`
- Notes: cross-link in `notes/VOLATILITY_INSTRUMENTS.md` if notation changes

**New pricing / fee primitive:**
- Primary code: `src/Pricing/NewModule.hs`
- Plot: `plot/Plot/Pricing/NewModule.hs` if visual evidence needed
- Tests: `test/Spec.hs`

**New Panoptic or encoding logic:**
- Primary code: `src/Panoptic/` (keep bit-layout docs in module header)
- Tests: `test/Spec.hs` (bit-field roundtrips are heavily tested today)

**New vol surface / grid feature:**
- Primary code: `src/Volatility/`
- Plot: `plot/Volatility/` or `plot/Plot/Volatility/`
- Lean (if proving): `lean/vol_markets/` + register in `lakefile.toml` roots

**New Greek:**
- Primary code: `src/Greeks/`
- Plot: `plot/Plot/Greeks/`
- Tests: `test/Spec.hs`

**New Lean theorem:**
- Implementation: `lean/vol_markets/NewModule.lean` (or `exp/`, `tao/`)
- Config: add root to `lakefile.toml` `[[lean_lib]]` roots list
- Traceability: update `notes/agents/vol_markets/LEAN_TRACEABILITY.md`

**Protocol / reactive design doc:**
- Implementation: `protocol/` (entity types under `entities/types/`, sequences under `COMMUNICATION/`)
- Do not mix executable Haskell into `protocol/`

**Utilities shared only by plots:**
- `plot/Plotting/` — not `src/` (keeps public library plot-free)

### Where new HEVM harness code should live

There is **no HEVM harness in this repo today**. `lakefile.toml` notes LeanEVM was removed (2026-07-16); `package.yaml` references downstream `evm-spec-bridge` as a consumer of the **pure** library only.

Recommended layout when adding EVM symbolic execution tests:

1. **New top-level package component** (preferred) — e.g. `hevm/` or `evm-test/` as a separate Stack/Cabal stanza:
   - `hevm/src/` — thin wrappers that call HEVM and parse results (no duplication of tick math)
   - `hevm/test/` — property tests comparing `src/` `Integer` outputs to EVM execution traces
   - `package.yaml`: new `tests:` or `internal-libraries:` entry with `hevm` dependency; **do not** add HEVM to the public `library:` stanza

2. **Keep oracle in `src/`** — HEVM tests should import existing modules (`SqrtGrid.mulDiv`, `Liquidity.LiquidityChunk`, `Payoffs.Log`, `Panoptic.NId`) as the reference; only put bytecode fixtures and RPC/HEVM runners outside `src/`

3. **Avoid `test/Spec.hs` for HEVM** — current file is a long IO script for pure numeric regressions; HEVM suites need isolated targets (slow, optional deps, different CI job)

4. **CI split** — add a optional workflow job (e.g. `hevm-test`) distinct from `stack test`; mirror how Lean has its own job

5. **Lean on-chain proofs** — when restoring EVM formalization, re-add LeanEVM to `lakefile.toml` alongside a `lean/evm/` or dedicated import tree; keep separate from Haskell HEVM harness

6. **Solidity twin alignment** — new EVM tests should target the same staged `mulDiv` chains documented in `src/SqrtGrid.hs` and chunk packing in `src/Liquidity/LiquidityChunk.hs`; open TODO #14 (`Chunk × density EVM mul`) marks known parity gaps

## Special Directories

**`outputs/`**
- Purpose: Generated PNG figures
- Source: Written by `app/Main.hs` via `Plotting.PlotUtils.writePanel`
- Committed: Often yes (spec evidence in README); safe to regenerate locally

**`core/`**
- Purpose: Stale GHC object files (`.hi`, `.o`) — **not** a source tree
- Source: Accidental/local build artifact
- Committed: Should be gitignored; do not add new source here

**`.worktrees/`**
- Purpose: Git worktree checkouts (e.g. feature branches with duplicate tree)
- Source: Local git configuration
- Committed: No — exclude from architecture analysis

**`.lake/`**
- Purpose: Lean build cache and package checkout
- Source: `lake exe cache get` / `lake build`
- Committed: No — `.lake/packages/` is large (~7 GB Mathlib)

**`.planning/`**
- Purpose: GSD codebase maps and planning state
- Source: Agent-generated (this document)
- Committed: Project-dependent

**`tmp/`**
- Purpose: Scratch / experimental copies
- Source: Ad hoc
- Committed: Treat as disposable

---

*Structure analysis: 2026-09-08*
*Update when directory structure changes*
