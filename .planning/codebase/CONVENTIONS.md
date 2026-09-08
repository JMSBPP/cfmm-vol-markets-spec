# Coding Conventions

**Analysis Date:** 2026-09-08

## Naming Patterns

**Files:**
- Haskell modules use PascalCase paths mirroring module names: `src/Payoffs/Forward.hs` → `Payoffs.Forward`
- One module per file; module name equals file path with dots for slashes
- Domain docs in `docs/`, protocol specs in `protocol/`, Lean proofs in `lean/`
- Agent workflow copies in `AGENTS.md`, `CLAUDE.md`, `QWEN.md` (keep in sync)

**Functions:**
- camelCase for functions and values (`chunkAmount0`, `nakedForwardQ96`, `mkVolStrike`)
- Smart constructors prefixed with `mk` (`mkNId`, `mkQuote`, `mkTickSpacing`)
- Unwrappers prefixed with `un` (`unNId`, `unFeePips`, `unLiquidityChunk`)
- Pattern synonyms for protocol constants (`Q96`, `WAD`, `BASE_ETA`, `SQRT_PRICE_1_4`)

**Variables:**
- camelCase for locals and record fields
- Short math names where the README/spec already defines them (`atm0`, `s10`, `liq`, `phiM`)
- Type synonyms for coordinates: `type Tick = Int`, `type SqrtPrice = Double` (Double only at the plotting/coordinate boundary)

**Types:**
- **newtype** wrappers for every on-chain–relevant quantity — never bare `Integer`/`Int` at API boundaries
  - Examples: `SqrtPriceX96`, `PayoffX96`, `FeePips`, `TargetVega`, `LiquidityChunk`, `VolSkew`
- `Payoff u` is a function newtype: `newtype Payoff u = Payoff { runPayoff :: u -> PayoffX96 }`
- Record types for bundled config (`Quote`, `MintPlan`, `FeeStructure`, `Ledger`)
- Known exception: `OptionRatio` wraps `Double` (brainstorm type; not Panoptic 7-bit ratio — see module TODO)

## EVM / Fixed-Point Arithmetic

**Q96 and PatternSynonyms:**
- Import `pattern Q96` from `SqrtGrid` (value `2^96`)
- Enable `{-# LANGUAGE PatternSynonyms #-}` in modules that pattern-match or re-export Q96 words
- `Q96` means unity in fixed-point: `a^0 = Q96` in `rpowX96`

**mulDiv / mulX96 (mandatory on hot paths):**
- `mulDiv a b d` = `floor(a·b / d)` — twin of Solidity `FullMath.mulDiv`
- `mulX96 a b` = `(a * b) \`div\` Q96` — product of two Q96 words
- Stage arithmetic exactly as the Solidity twin; **bare `a*b*c \`div\` d` is forbidden** in new code
- Reference table: `docs/BITWIDTHS.md` (operand ranges, intermediate max, rounding direction)
- Example (canonical staged form):

```haskell
-- Liquidity.LiquidityChunk.chunkAmount0
amt = mulDiv (chunkLiquidity ch * Q96) (b - a) b `div` a
```

**No Double on EVM hot paths:**
- Core payoff, liquidity, fee, and hedge math uses `Integer` / newtypes only
- `Double` is permitted only at documented boundaries:
  - Coordinate helpers: `sqrtPrice`, `tickBase`, `toDouble`, `payoffToDouble`
  - Vol-term CEV parameters: `InstantaneousVol`, `BarL`, `FlowVol`
  - Plotting layouts under `plot/`
  - Test tolerances in `test/Spec.hs` (`approxEqual`)
- Budgeted leaks listed explicitly in `docs/BITWIDTHS.md` (`OptionRatio`, `sqrtPriceX96`, `Log.nakedLogQ96`)

**Economic Meaning:**
- Every exercise/solution in sibling `cfmm-*/EXERCISES/` folders requires an **Economic Meaning** section (see parent `cfmm-theory/CLAUDE.md`)
- In this repo, economic meaning lives in `README.md` math blocks, `notes/`, and `protocol/` — link formulas to CFMM constructs (liquidity chunks, Panoptic legs, fee capture, LVR)
- When adding a type or formula, state what pool/trader/LP object it represents; if you cannot, the work is incomplete
- Bitwidth choices encode EVM constraints: `uint128` guards (`checkU128`), `uint88` volatility cap, 24-bit tick packing in `LiquidityChunk`

## Code Style

**Formatting:**
- No Ormolu/Fourmolu/hlint config in repo — follow existing module layout
- Explicit export lists on every module (enforced by `-Wmissing-export-lists`)
- LANGUAGE pragmas at top; imports grouped: standard libs, then local modules
- Haddock (`-- |`) on public functions that encode protocol rules

**GHC warnings (package-wide via `package.yaml`):**
```
-Wall -Wcompat -Widentities -Wincomplete-record-updates
-Wincomplete-uni-patterns -Wmissing-export-lists -Wmissing-home-modules
-Wpartial-fields -Wredundant-constraints
```
- CI runs `stack build --pedantic` on the library and executable
- Test suite relaxes three warnings (see TESTING.md)

**Build tooling:**
- `package.yaml` (hpack) generates `cfmm-vol-markets-spec.cabal`
- Stack snapshot: LTS 24.55 (`stack.yaml`)
- Core library is plot-free; Chart/cairo isolated in internal `plot` library

## Import Organization

**Order:**
1. LANGUAGE pragmas
2. `module` declaration with explicit export list
3. External packages (`base`, `vector`, `Data.Bits`, …)
4. Local modules (`SqrtGrid`, `Payoffs.*`, `Panoptic.*`, …)
5. Qualified imports where names clash (`qualified Payoffs.Forward as Fwd`)

**Path aliases:**
- None — use hierarchical module names, not custom import paths

## Error Handling

**Patterns:**
- Fail fast with `error` for invariant violations in pure code
- No `Maybe`/`Either` wrappers for constructor validation — smart constructors call `error` on bad input
- Use `Control.Exception.evaluate` + `try` in tests to assert expected failures (`assertThrows`)

**Error message format (required):**
- Prefix with **module and function**: `"Module.Submodule.functionName: description"`
- Examples:
  - `"SqrtGrid.mulDiv: division by zero"`
  - `"Liquidity.LiquidityChunk.createChunk: tickLower must be < tickUpper"`
  - `"Panoptic.NId.mkNId: N must be even and ≥ 2"`
- Dynamic context appended after colon: `show` of offending values where helpful

**Error Types:**
- No custom exception hierarchy — plain `error` strings throughout
- `checkU128 lbl x` helper uses `"Liquidity.LiquidityChunk." ++ lbl ++ ": …"` pattern

## Logging

**Framework:**
- No logging library — tests use `putStrLn ("ok: " ++ label)` for pass messages
- Production executable (`app/Main.hs`) writes plot PNGs, not structured logs

## Comments

**When to Comment:**
- Explain **why** a staged `mulDiv` chain matches Solidity (reference `docs/BITWIDTHS.md` or README identity)
- Document theorem/proposition gates: `-- Thm 7(i)`, `-- Prop 1`, `-- TODO #28.1`
- Mark known Double leaks and budget items
- Avoid restating obvious code

**TODO Comments:**
- Inline: `-- TODO #N: …` or `-- TODO (brainstorm): …`
- Tracked items in `TODO.md` (Open / Done sections with issue + PR URLs)
- Agent workflow for open TODO items: `AGENTS.md` / `CLAUDE.md` (classify → branch → issue → PR → cross-comment)

## Function Design

**Size:**
- Keep constructors and single-formula functions small
- Payoff combinators (`addPayoff`, `scalePayoff`) stay as one-liners over `PayoffX96` arithmetic

**Parameters:**
- Smart constructors take atomic inputs; bundle config in records (`MintPlan`, `FeeStructure`)
- Range parameters use newtypes (`TickSpacing`, `VolSkew`, `KappaSpacing`) not raw `Int`

**Return Values:**
- Fixed-point results wrapped in newtypes (`PayoffX96`, `FeeFactorX96`)
- Guard clauses at top of smart constructors before constructing

## Module Design

**Exports:**
- Explicit export list listing types, functions, and `pattern` synonyms
- Re-export `pattern Q96` from modules that expose Q96 arithmetic to callers
- Internal helpers stay off the export list

**Library split:**
- `cfmm-vol-markets-spec` (public): pure numeric core in `src/`
- `cfmm-vol-markets-spec:plot` (internal): Chart/cairo layouts in `plot/`
- Downstream consumers (e.g. JSON-RPC bridges) depend only on the public library

**Barrel files:**
- No top-level re-export barrel — import from specific modules (`Payoffs.Forward`, `SqrtGrid`)

## Agent / Git Workflow (AGENTS.md)

When working **open** items in `TODO.md`:

1. **Classify** — `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `spike`
2. **Branch** — `<type>/todo-<N>-<short-slug>` from updated `main`
3. **Issue** — `[<type>] TODO #<N>: …` on `d2p-finance/cfmm-vol-markets-spec`
4. **PR** — push to `JMSBPP` fork; target `upstream` `main`; body must link issue (`Solves #N`)
5. **Cross-comment** — PR comment + issue comment linking each other
6. **Done** — move item under **Done** in `TODO.md` with issue + PR URLs when merged

Remotes: `upstream` = canonical (`d2p-finance/cfmm-vol-markets-spec`); `origin` = fork (`JMSBPP`). Never push directly to `d2p-finance/*`.

---

*Convention analysis: 2026-09-08*
*Update when patterns change*
