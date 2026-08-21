{-# LANGUAGE PatternSynonyms #-}

module Volatility.VolOrder
  ( VolRangeWidth(..)
  , VolSkew
  , mkVolSkew
  , unVolSkew
  , VolOrder(..)
  , mkVolRangeWidth
  , mkVolOrder
  , tickVolatilityTick
  , roundTick
  , splitTick
  , tickBucketFromVolOrder
  , volOrderSplitPoints
  , legIntervals
  , fixtureSymmetricVolOrder
  ) where

import TargetVega (TargetVega)
import Payoffs.VolatilityCall (VolStrike, mkVolStrike, unVolStrike)
import SqrtGrid
  ( SqrtPriceX96(..)
  , Tick
  , TickSpacing
  , mkTickSpacing
  , pattern Q96
  , tickFromSqrtPriceX96
  , unTickSpacing
  )

data VolRangeWidth = VolRangeWidth
  { volWidth       :: Integer
  , volTickSpacing :: TickSpacing
  }
  deriving (Show, Eq)

newtype VolSkew = VolSkew Integer
  deriving (Show, Eq)

mkVolSkew :: Integer -> VolSkew
mkVolSkew s
  | s < 1 || s > 65534 =
      error "Volatility.VolOrder.mkVolSkew: skew must be in 1..65534"
  | otherwise = VolSkew s

unVolSkew :: VolSkew -> Integer
unVolSkew (VolSkew s) = s

mkVolRangeWidth :: Integer -> TickSpacing -> VolRangeWidth
mkVolRangeWidth w ts
  | w <= 0 =
      error "Volatility.VolOrder.mkVolRangeWidth: width must be > 0"
  | otherwise = VolRangeWidth w ts

data VolOrder = VolOrder
  { volRangeWidth :: VolRangeWidth
  , volStrike     :: VolStrike
  , volSkew       :: VolSkew
  , volTargetVega :: TargetVega
  }
  deriving (Show, Eq)

mkVolOrder :: VolRangeWidth -> VolStrike -> VolSkew -> TargetVega -> VolOrder
mkVolOrder = VolOrder

-- Plank: vol as Q64.96 sqrt word → getTickAtSqrtRatio. Scratchpad: same Integer as SqrtPriceX96.
tickVolatilityTick :: VolStrike -> Tick
tickVolatilityTick vs =
  tickFromSqrtPriceX96 (SqrtPriceX96 (unVolStrike vs))

-- Floor to the grid: Haskell's `div` already rounds toward -∞ for Integral
-- types, so `tick \`div\` d` is the compressed coordinate — no extra -1
-- (that was double-decrementing negative off-grid ticks; roundTick (-5) 10
-- must give -10, not -20).
roundTick :: Tick -> TickSpacing -> Tick
roundTick tick spacing =
  let
    d = unTickSpacing spacing
  in
    (tick `div` d) * d

splitTick :: VolSkew -> VolRangeWidth -> Tick -> (Tick, Tick)
splitTick (VolSkew skew) (VolRangeWidth width ts) tick =
  let
    right = (width * skew) `div` 65535
    left = width - right
  in
    ( roundTick (tick - fromInteger left) ts
    , roundTick (tick + fromInteger right) ts
    )

tickBucketFromVolOrder :: VolOrder -> (Tick, Tick, TickSpacing)
tickBucketFromVolOrder vo =
  let
    ts = volTickSpacing (volRangeWidth vo)
    center = roundTick (tickVolatilityTick (volStrike vo)) ts
    (lo, hi) = splitTick (volSkew vo) (volRangeWidth vo) center
  in
    (lo, hi, ts)

volOrderSplitPoints :: Tick -> Tick -> Tick -> TickSpacing -> (Tick, Tick)
volOrderSplitPoints iL iU iStar ts =
  ( roundTick (iL + (iStar - iL) `div` 2) ts
  , roundTick (iStar + (iU - iStar) `div` 2) ts
  )

legIntervals :: VolOrder -> [(Tick, Tick)]
legIntervals vo =
  let
    (iL, iU, ts) = tickBucketFromVolOrder vo
    iStar = roundTick (tickVolatilityTick (volStrike vo)) ts
    (mP, mC) = volOrderSplitPoints iL iU iStar ts
  in
    [(iL, mP), (mP, iStar), (iStar, mC), (mC, iU)]

-- width=40, Δ=10, skew=32768 → symmetric ±20 about tick 0 when volStrike=Q96.
fixtureSymmetricVolOrder :: TargetVega -> VolOrder
fixtureSymmetricVolOrder vega =
  mkVolOrder
    (mkVolRangeWidth 40 (mkTickSpacing 10))
    (mkVolStrike Q96)
    (mkVolSkew 32768)
    vega
