{-# LANGUAGE PatternSynonyms #-}

-- | Path accrual — the two legs of π^φ = π^φ_fee − π^LVR per chunk along a
-- tagged tick path (TODO #30; README § MODEL_CLOSURE, REPLICATION_THEORY Thm 5).
--
-- Per step p_i → p_j inside a chunk (overlap of [p_i,p_j] with [a,b]):
--   amount0 moved = L·(1/lo − 1/hi),  amount1 moved = L·(hi − lo)     (Uniswap)
--   price UP   (trader pays token1, receives token0): fee = φ_M·amount1
--   price DOWN (trader pays token0, receives token1): fee = φ_X·amount0·p_j²
--   LVR (arb steps only) = arb's profit marked at the corrected price p_j:
--     up:   amount0·p_j² − amount1     down: amount1 − amount0·p_j²        (≥ 0: concavity)
-- Fees are split by tag; LVR_net = LVR_gross − fees_arb (README after-fee
-- convention); π^φ (seller's net accrual) = fees_trans − LVR_net.
-- All token1-valued, Q96 fixed point, mulDiv chains (docs/BITWIDTHS.md).
module Payoffs.PathAccrual
  ( Tag(..)
  , Step(..)
  , Accrual(..)
  , zeroAccrual
  , addAccrual
  , ArbSharePips
  , mkArbSharePips
  , unArbSharePips
  , pattern PIPS_ONE
  , syntheticPath
  , stepAccrual
  , pathAccrual
  , planAccrual
  , netAccrual
  , linesLayout
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy

import Liquidity.LiquidityChunk
  ( LiquidityChunk
  , chunkLiquidity
  , chunkTickLower
  , chunkTickUpper
  )
import Panoptic.LegChunk (legChunks)
import Panoptic.MintPlan (MintPlan)
import Pricing.Stremia (FeePips, unFeePips)
import SqrtGrid (PayoffX96(..), SqrtPriceX96(..), Tick, mulDiv, pattern Q96, sqrtPriceX96)

-- | Holder = the position holder correcting the pool toward the external price
-- (rebate note §3).  To the LP's book a holder correction accrues like an arb
-- correction (fee + concavity gap); who receives the gap is tracked in
-- Payoffs.HolderPath, not here.
data Tag = Trans | Arb | Holder
  deriving (Show, Eq)

-- | One price move on the path with its flow tag.
data Step = Step
  { stepFrom :: Tick
  , stepTo   :: Tick
  , stepTag  :: Tag
  }
  deriving (Show, Eq)

data Accrual = Accrual
  { feesTrans :: Integer   -- token1, Q96-scaled payoff units
  , feesArb   :: Integer
  , lvrGross  :: Integer
  }
  deriving (Show, Eq)

zeroAccrual :: Accrual
zeroAccrual = Accrual 0 0 0

addAccrual :: Accrual -> Accrual -> Accrual
addAccrual (Accrual a b c) (Accrual a' b' c') = Accrual (a + a') (b + b') (c + c')

-- | Atomic arb share [ν_arb/ν] in pips (uint24, 1e6 = 1; same convention as
-- FeePips / txlVolumeRate) — read, never computed.
newtype ArbSharePips = ArbSharePips Integer
  deriving (Show, Eq, Ord)

pattern PIPS_ONE :: Integer
pattern PIPS_ONE = 1000000

mkArbSharePips :: Integer -> ArbSharePips
mkArbSharePips s
  | s < 0 || s > PIPS_ONE = error "Payoffs.PathAccrual.mkArbSharePips: share must be in [0, 1e6] pips"
  | otherwise = ArbSharePips s

unArbSharePips :: ArbSharePips -> Integer
unArbSharePips (ArbSharePips s) = s

-- | Deterministic synthetic path: n steps of ±stepTicks from i0; direction from a
-- 32-bit LCG (seed); tag = Arb on the Bresenham schedule of the share
-- (⌊(k+1)·s⌋ > ⌊k·s⌋), so #Arb/n → s exactly.  A vol proxy is stepTicks.
syntheticPath :: Int -> Tick -> Int -> Int -> ArbSharePips -> [Step]
syntheticPath seed i0 stepTicks n (ArbSharePips s) =
  go 0 i0 (fromIntegral seed :: Integer)
  where
    go k i st
      | k >= n = []
      | otherwise =
          let st' = (1664525 * st + 1013904223) `mod` 4294967296
              up = (st' `div` 65536) `mod` 2 == 0
              j = if up then i + stepTicks else i - stepTicks
              kI = toInteger k
              isArb = ((kI + 1) * s) `div` PIPS_ONE > (kI * s) `div` PIPS_ONE
          in  Step i j (if isArb then Arb else Trans) : go (k + 1) j st'

-- | Accrual of one step on one chunk (token1, Q96 units as PayoffX96).
stepAccrual :: FeePips -> FeePips -> LiquidityChunk -> Step -> Accrual
stepAccrual phiX phiM ch (Step iFrom iTo tag)
  | iFrom == iTo = zeroAccrual
  | hi <= lo     = zeroAccrual                        -- no overlap with the range
  | otherwise =
      let l = chunkLiquidity ch
          amt0 = mulDiv (l * Q96) (hi - lo) hi `div` lo  -- L(1/lo − 1/hi) staged (getAmount0)
          amt1 = mulDiv l (hi - lo) Q96                  -- L(hi − lo)            (getAmount1)
          SqrtPriceX96 pj = sqrtPriceX96 iTo
          amt0AtPj = mulDiv (mulDiv pj pj Q96) amt0 Q96  -- amount0 valued in token1 at p_j
          fee = if goingUp
                  then mulDiv amt1 (unFeePips phiM) 1000000
                  else mulDiv amt0AtPj (unFeePips phiX) 1000000
          lvr = if goingUp then amt0AtPj - amt1 else amt1 - amt0AtPj
      in  case tag of
            Trans  -> Accrual fee 0 0
            Arb    -> Accrual 0 fee (max 0 lvr)
            Holder -> Accrual 0 fee (max 0 lvr)
  where
    goingUp = iTo > iFrom
    SqrtPriceX96 a = sqrtPriceX96 (chunkTickLower ch)
    SqrtPriceX96 b = sqrtPriceX96 (chunkTickUpper ch)
    SqrtPriceX96 pFrom = sqrtPriceX96 iFrom
    SqrtPriceX96 pTo = sqrtPriceX96 iTo
    lo = max a (min pFrom pTo)
    hi = min b (max pFrom pTo)

pathAccrual :: FeePips -> FeePips -> LiquidityChunk -> [Step] -> Accrual
pathAccrual phiX phiM ch = foldr (addAccrual . stepAccrual phiX phiM ch) zeroAccrual

-- | Four-leg roll-up over a MintPlan (each leg chunk accrues on its own range).
planAccrual :: FeePips -> FeePips -> MintPlan -> [Step] -> [Accrual]
planAccrual phiX phiM plan path = [ pathAccrual phiX phiM ch path | ch <- legChunks plan ]

-- | (LVR_net, π^φ): LVR after the fees arbs paid; seller's net accrual = fees_trans − LVR_net.
netAccrual :: Accrual -> (PayoffX96, PayoffX96)
netAccrual (Accrual ft fa lg) =
  let lvrNet = lg - fa
  in  (PayoffX96 lvrNet, PayoffX96 (ft - lvrNet))

-- | Named-lines layout. Axes carry EVM-representable numbers only (pips, ticks,
-- raw PayoffX96 words); Double appears here solely as the chart's coordinate type.
linesLayout :: String -> String -> String -> [(String, [(Integer, Integer)])] -> Layout Double Double
linesLayout title xTitle yTitle series = execEC $ do
  layout_title .= title
  layout_x_axis . laxis_title .= xTitle
  layout_y_axis . laxis_title .= yTitle
  setColors (map opaque [blue, red, darkgreen, orange, purple, black])
  mapM_ (\(name, pts) -> plot (line name [[ (fromIntegral x, fromIntegral y) | (x, y) <- pts ]])) series
