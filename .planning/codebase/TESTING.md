# Testing Patterns

**Analysis Date:** 2026-09-08

## Test Framework

**Runner:**
- Stack primary; Cabal also supported (hpack-generated `cfmm-vol-markets-spec.cabal`)
- No Hspec, Tasty, or QuickCheck — plain `IO` with custom helpers
- Test suite name: `cfmm-vol-markets-spec-test` (`type: exitcode-stdio-1.0`)

**Assertion style:**
- Custom helpers defined at top of `test/Spec.hs`:
  - `assertEqual label expected actual` — exact equality, fails with `error`
  - `assertThrows label value` — expects pure exception via `evaluate` + `try`
  - `approxEqual label tol expected actual` — `Double` tolerance (plotting/coordinate checks only)
- Pass messages: `putStrLn ("ok: " ++ label)`
- Failures: `error` with descriptive string (no test framework diff output)

**Run Commands:**
```bash
stack test                              # Run all tests (primary)
stack build --pedantic && stack test    # CI-equivalent local check
cabal test                              # Alternative via Cabal
stack test cfmm-vol-markets-spec:test   # Explicit target
```

## Test File Organization

**Location:**
- Single test entry point: `test/Spec.hs` (~2100 lines)
- No collocated `*.hs` test modules; no `tests/` tree beyond `test/Spec.hs`
- Plot smoke tests inline (build `Layout` values, call `execEC`, assert `canvasSize`)

**Naming:**
- One `main :: IO ()` — sequential script, not describe/it blocks
- Assertion labels are human-readable strings: `"forward naked at p* is 0"`, `"Thm 8 legLiquidity = c-weighted mean"`

**Structure:**
```
test/
  Spec.hs          # entire test suite (IO script)
src/               # code under test (no test files here)
plot/              # exercised by Spec for layout/canvas helpers
```

## Test Structure

**Suite Organization:**
```haskell
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main (main) where

import Control.Exception (ErrorCall, evaluate, try)
-- … extensive imports from src/ and plot/ …

assertEqual :: (Eq a, Show a) => String -> a -> a -> IO ()
assertThrows :: String -> a -> IO ()
approxEqual :: String -> Double -> Double -> Double -> IO ()

main :: IO ()
main = do
  assertEqual "canvasSize Cell is 1×1" (900, 720) (canvasSize (Cell dummy))
  -- … hundreds of sequential assertions …
  assertEqual "fee capture mixture w=1 ≡ Y_recv" yrCap yCapMix1
```

**Patterns:**
- **Sequential IO script** — one `main` runs all checks top-to-bottom; no test discovery
- State built with `let` bindings; later blocks reuse fixtures (`n32`, `atm0`, `planBig`)
- `evaluate` forces WHNF before asserting lazy Payoff values
- `sequence_` for batch property checks over lists (monotonicity grids, quantization rows)
- Inline `if … then putStrLn "ok: …" else error "…"` for tolerance-based Q96 checks
- Comments reference Lean theorems, README identities, and TODO gates (`-- TODO #28.1`)

**GHC options (test-only relaxations in `package.yaml`):**
```
-Wno-name-shadowing -Wno-type-defaults -Wno-gadt-mono-local-binds
```
Pedantic library build; pragmatic test file (heavy imports, shadowing, type defaults).

## Mocking

**Framework:**
- No mocking library — all tests hit real pure functions

**What to Mock:**
- Nothing — tests exercise actual `src/` implementations

**What NOT to Mock:**
- All business logic, fixed-point arithmetic, Panoptic packing, payoff combinators
- Chart layouts use real `execEC` with dummy titles (no file I/O in most layout tests)

## Fixtures and Factories

**Test Data:**
- Smart constructors from production code: `mkNId 32`, `mkVolStrike Q96`, `fixtureSymmetricVolOrder`
- Protocol constants via patterns: `Q96`, `WAD`, `BASE_ETA`, `SQRT_PRICE_1_4`
- Pre-built skeletons: `fourLegSkeleton`, `volOrderToMintPlan`, `ladderFromSpan`
- Tick grids iterated in comprehensions: `[ i | i <- [(-3000), (-2990) .. 3000], … ]`

**Location:**
- Fixtures defined in source modules (`Volatility.VolOrder.fixtureSymmetricVolOrder`, `Panoptic.NId.fourLegSkeleton`)
- Test-local `let` blocks for derived values; no separate `test/fixtures/` directory

## Coverage

**Requirements:**
- No coverage tooling configured
- No enforced line-coverage target
- Verification is **property- and theorem-driven**: tests name README/Lean claims (`Thm 7(i)`, `Thm 8`, `Prop 1`, `Cor 1`, `5.3 round trip`)

**Configuration:**
- None — rely on `stack test` exit code

## Test Types

**Unit / integration (combined):**
- Single file mixes:
  - Numeric identity checks (CLMM chunk amounts, `mulDiv` staging)
  - Payoff algebra (forward, log, variance portfolio, fee capture)
  - Panoptic packing round-trips (TokenId, MintPlan, binning)
  - Path accrual / LVR / holder P&L simulations
  - Plot layout dimensions (canvas grid arithmetic)
- No separation between unit and integration — all run in one `stack test` invocation

**Lean proofs (separate job):**
- CI job `lake build` compiles Lean under `lean/` with sorry/admit guard
- Haskell tests cross-check statements cited in Lean (e.g. `principal_inRange (Lean P2)`)
- Lean failure does not run Haskell tests in same job — parallel CI jobs

## CI

**Workflow:** `.github/workflows/ci.yml`

| Job | Command | Purpose |
|-----|---------|---------|
| `stack` | `stack build --pedantic` then `stack test` | Haskell build + test suite |
| `lean` | `lake exe cache get` then `lake build` (no sorry/admit) | Proof compilation |

- Triggers: `push` and `pull_request` to `main`
- Stack job installs Cairo dev libs (Chart-cairo dependency for plot tests)
- Concurrency group cancels superseded runs on force-push
- Comment in CI: *"Spec is a long IO script with intentional reuse; keep build pedantic."*

## Common Patterns

**Exact Q96 equality:**
```haskell
assertEqual "squareSqrtPrice tick0 is Q96" Q96 p0
assertEqual "naked forward is (P-P*)/P* in Q96" expectedNaked naked10
```

**Tolerance on integer Q96 (tick discretization):**
```haskell
if abs (log10 - expectedLog) <= Q96 `div` 1000000000
  then putStrLn "ok: naked log ≈ (i-i*) ln λ at a tick price (1e-9 Q96)"
  else error ("naked log vs tick formula: " ++ show log10 ++ " vs " ++ show expectedLog)
```

**Expected failure:**
```haskell
assertThrows "mkNId 1 rejected" (mkNId 1)
```

**Grid property (batch):**
```haskell
sequence_ [ if qRelErrPpm r <= qBoundPpm r + 1 then pure ()
            else error ("quantization bound fails: " ++ show r)
          | r <- rows ]
```

**Double tolerance (non-EVM checks only):**
```haskell
approxEqual "cev delta" 1e-6 expected actual
if abs (cS - 2.62294) < 2.0e-5 then putStrLn ("ok: c(4000) = " ++ show cS)
  else error ("c(4000) = " ++ show cS)
```

**Layout smoke test:**
```haskell
let dummy = execEC (layout_title .= "")
assertEqual "canvasSize Beside is 1×2" (1800, 720) (canvasSize (Beside (Cell dummy) (Cell dummy)))
putStrLn "ok: CEV vs-{sqrtPrice,gamma,xi} layouts"
```

**Snapshot Testing:**
- Not used — prefer explicit numeric assertions and named theorem labels

## Adding Tests

1. Append to `main` in `test/Spec.hs` (maintain sequential flow near related checks)
2. Use `assertEqual` for exact `Integer`/newtype equality; reserve `approxEqual` for `Double`
3. Label assertions with the economic/theorem claim being gated
4. For new smart constructors, add both success `assertEqual` and `assertThrows` cases
5. Run `stack build --pedantic && stack test` before PR — matches CI
6. If the test encodes a new fixed-point chain, cross-check staging against `docs/BITWIDTHS.md`

---

*Testing analysis: 2026-09-08*
*Update when test patterns change*
