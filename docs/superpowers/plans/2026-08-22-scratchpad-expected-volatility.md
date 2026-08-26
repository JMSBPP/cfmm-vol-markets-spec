# Scratchpad ExpectedVolatility σ^e — Slice 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Slice 1 of TODO #21 — typed `ExpectedVolatility` (oracle-integer units), uniform tenor stub, minimal `ImpliedVolatility` newtype for `volGap`, and tests; no `DiscountFactor` yet.

**Architecture:** New `Volatility.ExpectedVolatility` holds σ^e newtypes, `VolHorizon` tag, tenor path builder over `InterestPriceMap`, and WINDOW identity stub. Minimal `Volatility.ImpliedVolatility` (newtype only — full u-map remains TODO #20) enables `volGap`. Tests in `test/Spec.hs` assert uniform tenor + gap algebra.

**Tech Stack:** GHC via Stack (LTS 24.55), Haskell2010, `test/Spec.hs` IO asserts, `cfmm-scratchpad.cabal` exposed-modules.

**Spec:** `docs/superpowers/specs/2026-08-22-scratchpad-expected-volatility-design.md`

## Global Constraints

- Working directory: `/home/jmsbpp/learning/cfmm-theory/scratchpad`
- Branch: `feat/todo-21-expected-volatility-slice1` (issue [#31](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/31))
- σ^e and σ_X use **same integer units** as `VolatilityAverage` — not FeePips, not u88 sqrt trick
- `OracleWindowHorizon` Slice 1 = **identity stub** from realized average (documented non-𝔼^Q placeholder)
- `TenorHorizon` Slice 1 = **uniform** path — `averageVolatility` on `InterestPriceMap` tick ladder
- Do **not** import or implement `DiscountFactor` / full `expectedVolatility :: DiscountFactor`
- Minimal `ImpliedVolatility` newtype only; **no** `uStarFromCalibration` (TODO #20)
- CI: `stack build --pedantic` + `stack test`
- Commit only if the human asked; otherwise **skip every Commit step**

---

## File map

| File | Role |
|------|------|
| `src/Volatility/ExpectedVolatility.hs` | **Create.** Types, tenor path, uniform + window stubs |
| `src/Volatility/ImpliedVolatility.hs` | **Create.** Minimal newtype + `impliedVolatilityFromAverage` |
| `cfmm-scratchpad.cabal` | Expose both modules |
| `test/Spec.hs` | Slice 1 asserts |
| `README.md` | One-line Slice 1 shipped note under σ^e paragraph |
| `docs/superpowers/specs/2026-08-22-scratchpad-expected-volatility-design.md` | Status → `implementing` |

---

### Task 1: `Volatility.ExpectedVolatility` core types

**Files:**
- Create: `src/Volatility/ExpectedVolatility.hs`
- Modify: `cfmm-scratchpad.cabal` (add `Volatility.ExpectedVolatility` after `Volatility.TickVolatility`)

**Interfaces:**
- Consumes: `VolatilityAverage`, `unVolatilityAverage` from `Volatility.TickVolatility`
- Consumes: `InterestTick`, `unInterestTick`, `mkInterestTick` from `Pricing.InterestSqrt`
- Produces:
  - `ExpectedVolatility(..)`, `unExpectedVolatility`
  - `RealizedVolatility(..)`, `unRealizedVolatility`
  - `VolHorizon(..)` — `OracleWindowHorizon` | `TenorHorizon InterestTick`
  - `realizedVolatilityFromAverage :: VolatilityAverage -> RealizedVolatility`
  - `expectedVolatilityWindowStub :: VolatilityAverage -> ExpectedVolatility`

- [ ] **Step 1: Write the failing test**

Add to `test/Spec.hs` (after existing `averageVolatility` block ~L643):

```haskell
import Volatility.ExpectedVolatility
  ( ExpectedVolatility(..)
  , RealizedVolatility(..)
  , VolHorizon(..)
  , expectedVolatilityWindowStub
  , realizedVolatilityFromAverage
  , unExpectedVolatility
  , unRealizedVolatility
  )

-- ExpectedVolatility Slice 1
let volAvg0 = VolatilityAverage 0
assertEqual
  "realizedVolatilityFromAverage round-trip"
  0
  (unRealizedVolatility (realizedVolatilityFromAverage volAvg0))
assertEqual
  "expectedVolatilityWindowStub = realized (Slice 1 stub)"
  0
  (unExpectedVolatility (expectedVolatilityWindowStub volAvg0))
```

- [ ] **Step 2: Run test to verify it fails**

Run: `stack test 2>&1 | tail -20`  
Expected: FAIL — module `Volatility.ExpectedVolatility` not found

- [ ] **Step 3: Write minimal implementation**

```haskell
module Volatility.ExpectedVolatility
  ( ExpectedVolatility(..)
  , unExpectedVolatility
  , RealizedVolatility(..)
  , unRealizedVolatility
  , VolHorizon(..)
  , realizedVolatilityFromAverage
  , expectedVolatilityWindowStub
  ) where

import Pricing.InterestSqrt (InterestTick)
import Volatility.TickVolatility (VolatilityAverage(..), unVolatilityAverage)

-- | σ^e in Algebra oracle integer units (same as VolatilityAverage).
newtype ExpectedVolatility = ExpectedVolatility Integer
  deriving (Show, Eq)

unExpectedVolatility :: ExpectedVolatility -> Integer
unExpectedVolatility (ExpectedVolatility x) = x

newtype RealizedVolatility = RealizedVolatility Integer
  deriving (Show, Eq)

unRealizedVolatility :: RealizedVolatility -> Integer
unRealizedVolatility (RealizedVolatility x) = x

data VolHorizon
  = OracleWindowHorizon
  | TenorHorizon InterestTick
  deriving (Show, Eq)

realizedVolatilityFromAverage :: VolatilityAverage -> RealizedVolatility
realizedVolatilityFromAverage (VolatilityAverage x) = RealizedVolatility x

-- VISIBLE NOTE: Slice 1 non-𝔼^Q stub — WINDOW ensemble deferred to Slice 3.
expectedVolatilityWindowStub :: VolatilityAverage -> ExpectedVolatility
expectedVolatilityWindowStub (VolatilityAverage x) = ExpectedVolatility x
```

Add `Volatility.ExpectedVolatility` to `cfmm-scratchpad.cabal` `exposed-modules`.

- [ ] **Step 4: Run test to verify it passes**

Run: `stack build --pedantic && stack test 2>&1 | tail -30`  
Expected: PASS — new asserts `ok`

- [ ] **Step 5: Commit** (skip unless human asked)

---

### Task 2: Uniform tenor `expectedVolatilityUniformTenor`

**Files:**
- Modify: `src/Volatility/ExpectedVolatility.hs`
- Modify: `test/Spec.hs`

**Interfaces:**
- Consumes: `InterestPriceMap`, `priceTickAt`; `averageVolatility`, `TickPath`; `Data.Vector`
- Produces:
  - `expectedVolatilityUniformTenor :: InterestPriceMap -> InterestTick -> InterestTick -> ExpectedVolatility`
  - `tenorTickPath :: InterestPriceMap -> InterestTick -> InterestTick -> TickPath` (exported for tests)

- [ ] **Step 1: Write the failing test**

```haskell
import Pricing.InterestPriceMap (mkInterestPriceMap, priceTickAt)
import TickPath (TickPath(..), pathLength, ticks)
import Volatility.ExpectedVolatility (expectedVolatilityUniformTenor, tenorTickPath)

let
  ipmTen = mkInterestPriceMap 1 0
  t0 = mkInterestTick 0
  t7 = mkInterestTick 7
  flatPath = TickPath 8 (V.replicate 8 0)
  evFlat = expectedVolatilityUniformTenor ipmTen t0 t0
  path07 = tenorTickPath ipmTen t0 t7
assertEqual
  "tenorTickPath t0→t7 length"
  8
  (pathLength path07)
assertEqual
  "tenorTickPath t0 tick"
  0
  (ticks path07 ! 0)
assertEqual
  "tenorTickPath t7 tick"
  7
  (ticks path07 ! 7)
assertEqual
  "uniform tenor flat t0=t0 ⇒ σ^e=0"
  0
  (unExpectedVolatility evFlat)
assertEqual
  "uniform tenor flat matches averageVolatility constant path"
  (unVolatilityAverage (averageVolatility flatPath))
  (unExpectedVolatility (expectedVolatilityUniformTenor ipmTen t0 t0))
```

- [ ] **Step 2: Run test to verify it fails**

Run: `stack test 2>&1 | tail -20`  
Expected: FAIL — `expectedVolatilityUniformTenor` not defined

- [ ] **Step 3: Write minimal implementation**

Append to `ExpectedVolatility.hs`:

```haskell
import qualified Data.Vector as V
import Pricing.InterestPriceMap (InterestPriceMap, priceTickAt)
import Pricing.InterestSqrt (InterestTick, mkInterestTick, unInterestTick)
import TickPath (TickPath(..))
import Volatility.TickVolatility (averageVolatility, unVolatilityAverage)

tenorTickPath :: InterestPriceMap -> InterestTick -> InterestTick -> TickPath
tenorTickPath ipm t0 tR =
  let
    a = unInterestTick t0
    b = unInterestTick tR
    lo = min a b
    hi = max a b
    n = hi - lo + 1
    vec =
      V.generate n $ \j ->
        priceTickAt ipm (mkInterestTick (lo + j))
  in
    -- averageVolatility needs ≥2 ticks; duplicate when degenerate
    if n >= 2
      then TickPath n vec
      else
        let ti = priceTickAt ipm t0
        in TickPath 2 (V.replicate 2 ti)

expectedVolatilityUniformTenor
  :: InterestPriceMap
  -> InterestTick
  -> InterestTick
  -> ExpectedVolatility
expectedVolatilityUniformTenor ipm t0 tR =
  ExpectedVolatility $
    unVolatilityAverage (averageVolatility (tenorTickPath ipm t0 tR))
```

Update export list with `tenorTickPath`, `expectedVolatilityUniformTenor`.

- [ ] **Step 4: Run test to verify it passes**

Run: `stack build --pedantic && stack test 2>&1 | tail -30`  
Expected: PASS

- [ ] **Step 5: Commit** (skip unless human asked)

---

### Task 3: Minimal `ImpliedVolatility` + `volGap`

**Files:**
- Create: `src/Volatility/ImpliedVolatility.hs`
- Modify: `src/Volatility/ExpectedVolatility.hs` (add `VolGap`, `volGap`)
- Modify: `cfmm-scratchpad.cabal`
- Modify: `test/Spec.hs`

**Interfaces:**
- Consumes: `ImpliedVolatility`, `impliedVolatilityFromAverage` from Task 3 module
- Produces:
  - `ImpliedVolatility(..)`, `unImpliedVolatility`, `impliedVolatilityFromAverage`
  - `VolGap(..)`, `unVolGap`, `volGap :: ImpliedVolatility -> ExpectedVolatility -> VolGap`

- [ ] **Step 1: Write the failing test**

```haskell
import Volatility.ImpliedVolatility
  ( ImpliedVolatility(..)
  , impliedVolatilityFromAverage
  , unImpliedVolatility
  )
import Volatility.ExpectedVolatility (VolGap(..), unVolGap, volGap)

let
  iv = impliedVolatilityFromAverage (VolatilityAverage 100)
  ev = ExpectedVolatility 40
assertEqual
  "volGap σ_IV − σ^e"
  60
  (unVolGap (volGap iv ev))
assertEqual
  "volGap zero when equal"
  0
  (unVolGap (volGap iv (ExpectedVolatility 100)))
```

- [ ] **Step 2: Run test to verify it fails**

Run: `stack test 2>&1 | tail -20`  
Expected: FAIL — `Volatility.ImpliedVolatility` or `volGap` missing

- [ ] **Step 3: Write minimal implementation**

`src/Volatility/ImpliedVolatility.hs`:

```haskell
module Volatility.ImpliedVolatility
  ( ImpliedVolatility(..)
  , unImpliedVolatility
  , impliedVolatilityFromAverage
  ) where

import Volatility.TickVolatility (VolatilityAverage(..), unVolatilityAverage)

-- | Kristensen σ_IV word (full u-map in TODO #20).
newtype ImpliedVolatility = ImpliedVolatility Integer
  deriving (Show, Eq)

unImpliedVolatility :: ImpliedVolatility -> Integer
unImpliedVolatility (ImpliedVolatility x) = x

-- Slice 1 stand-in until uStarFromCalibration lands.
impliedVolatilityFromAverage :: VolatilityAverage -> ImpliedVolatility
impliedVolatilityFromAverage (VolatilityAverage x) = ImpliedVolatility x
```

Add to `ExpectedVolatility.hs`:

```haskell
import Volatility.ImpliedVolatility (ImpliedVolatility, unImpliedVolatility)

newtype VolGap = VolGap Integer
  deriving (Show, Eq)

unVolGap :: VolGap -> Integer
unVolGap (VolGap x) = x

volGap :: ImpliedVolatility -> ExpectedVolatility -> VolGap
volGap iv (ExpectedVolatility ev) =
  VolGap (unImpliedVolatility iv - ev)
```

Expose `Volatility.ImpliedVolatility` in cabal; export `VolGap`, `volGap`, `unVolGap` from ExpectedVolatility.

- [ ] **Step 4: Run test to verify it passes**

Run: `stack build --pedantic && stack test 2>&1 | tail -30`  
Expected: PASS

- [ ] **Step 5: Commit** (skip unless human asked)

---

### Task 4: Docs + spec status

**Files:**
- Modify: `README.md` (~σ^e paragraph)
- Modify: `docs/superpowers/specs/2026-08-22-scratchpad-expected-volatility-design.md`

**Interfaces:**
- Produces: README bullet that Slice 1 modules are shipped; spec status `implementing` → `done` when PR merges

- [ ] **Step 1: README note**

Under σ^e spec link, add:

```markdown
- **Shipped (Slice 1):** `Volatility.ExpectedVolatility` (uniform tenor stub, WINDOW identity stub), `Volatility.ImpliedVolatility` (minimal newtype), `volGap`
```

- [ ] **Step 2: Spec status**

Change header to:

```markdown
**Status:** done — plan `docs/superpowers/plans/2026-08-22-scratchpad-expected-volatility.md` (Slice 1)
```

- [ ] **Step 3: Final CI**

Run: `stack build --pedantic && stack test`  
Expected: PASS

- [ ] **Step 4: Commit** (skip unless human asked)

---

## Self-review (plan vs spec)

| Spec requirement | Task |
|------------------|------|
| `ExpectedVolatility` newtype (oracle int) | Task 1 |
| `VolHorizon` WINDOW \| Tenor | Task 1 |
| `RealizedVolatility` wrapper | Task 1 |
| WINDOW stub (non-𝔼^Q Slice 1) | Task 1 |
| `expectedVolatilityUniformTenor` | Task 2 |
| `volGap` | Task 3 |
| Minimal `ImpliedVolatility` | Task 3 |
| Equilibrium pins (flat tenor, gap zero) | Tasks 2–3 tests |
| No `DiscountFactor` | Global constraint |
| u88 / full u-map | Out of scope |

No placeholders in task steps. Type names consistent across tasks.

---

## Handoff

After Slice 1 PR merges: update `TODO.md` #21 with PR URL; cross-comment issue #31. Slice 2 (mixture weights) and Slice 3 (full 𝔼^Q) are separate plans.
