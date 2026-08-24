{-# LANGUAGE PatternSynonyms #-}

-- | 𝓑 — binning the T1 geometric ladder into a 4-leg Panoptic mint
-- (README § REPLICATION_THEORY Def 8, Corollary 1; TODO #28 item 3).
--
-- One token1 basis on every leg (asset = 1), so bin notional is the sum of the
-- rungs' amount1: n_leg = Σ_{x ∈ leg} L(i_x)·(b_x − a_x)/Q96 = Σ chunkAmount1.
-- or(leg) = round(127·n_leg/n_max), positionSize = ⌊n_max/127⌋.  The realized
-- leg liquidity or·positionSize·Q96/(b_leg − a_leg) is the c-weighted MEAN of the
-- rung liquidities — the weighted-L² optimum (Theorem 8).  Nothing is searched.
module Panoptic.Binning
  ( ladderFromVolOrder
  , binNotionals
  , binToLegs
  , mintPlanFromLadder
  , QuantizationRow(..)
  , quantizationReport
  , orMinDefault
  ) where

import Liquidity.LiquidityChunk
  ( chunkAmount1
  , chunkTickLower
  , createChunk
  )
import Panoptic.MintPlan (MintPlan(..))
import Panoptic.NId (volOrderToTokenId)
import Payoffs.LadderPosition (Ladder(..), ladderChunks, ladderFromSpan)
import SqrtGrid (PayoffX96(..), Tick, mulDiv)
import TargetVega (TargetVega, mkTargetVega, unTargetVega)
import Volatility.VolOrder
  ( VolOrder(..)
  , legIntervals
  , roundTick
  , tickBucketFromVolOrder
  , tickVolatilityTick
  )

orMinDefault :: Integer
orMinDefault = 8

-- | The ladder that shares the VolOrder's span, spacing and i* (at ξ*).
ladderFromVolOrder :: VolOrder -> Ladder
ladderFromVolOrder vo =
  let (iL, iU, ts) = tickBucketFromVolOrder vo
      iStar = roundTick (tickVolatilityTick (volStrike vo)) ts
  in  ladderFromSpan iL iU ts iStar (volTargetVega vo)

-- | n_leg (token1) for the four legIntervals bins, in leg order.
binNotionals :: Ladder -> VolOrder -> [Integer]
binNotionals l vo =
  [ sum [ n | ch <- ladderChunks l
            , let i = chunkTickLower ch
            , lo <= i && i < hi
            , let PayoffX96 n = chunkAmount1 ch ]
  | (lo, hi) <- legIntervals vo ]

-- | 𝓑: (or(leg))_{0..3} and positionSize.  Rejects (error) if any or < orMin
-- (Panoptic `validate` reverts on optionRatio = 0; below orMin the 7-bit
-- quantization error 1/(2·or) exceeds the tolerance we accept).
binToLegs :: Integer -> Ladder -> VolOrder -> ((Integer, Integer, Integer, Integer), TargetVega)
binToLegs orMin l vo =
  let ns = binNotionals l vo
      nMax = maximum ns
      ors = [ (127 * n + nMax `div` 2) `div` nMax | n <- ns ]   -- round(127·n/n_max)
      positionSize = nMax `div` 127
  in  case ors of
        [o0, o1, o2, o3]
          | any (< orMin) ors ->
              error ("Panoptic.Binning.binToLegs: or below orMin: " ++ show ors)
          | positionSize <= 0 || positionSize >= 2 ^ (128 :: Int) ->
              error "Panoptic.Binning.binToLegs: positionSize out of uint128"
          | otherwise -> ((o0, o1, o2, o3), mkTargetVega positionSize)
        _ -> error "Panoptic.Binning.binToLegs: expected four legs"

-- | The Panoptic mint realizing 𝓑(ladder): tokenId from the VolOrder geometry +
-- the computed ratios; envelope chunk at positionSize (SFPM positionSize).
mintPlanFromLadder :: Integer -> Ladder -> VolOrder -> MintPlan
mintPlanFromLadder poolId l vo =
  let (ratios, ps) = binToLegs orMinDefault l vo
      (iL, iU, _) = tickBucketFromVolOrder vo
  in  MintPlan (volOrderToTokenId vo poolId ratios) (createChunk iL iU (unTargetVega ps))

data QuantizationRow = QuantizationRow
  { qLeg          :: Int
  , qLo           :: Tick
  , qHi           :: Tick
  , qNotional     :: Integer   -- n_leg (token1)
  , qOr           :: Integer   -- or(leg)
  , qRealized     :: Integer   -- or·positionSize
  , qRelErrPpm    :: Integer   -- |realized − n_leg| / n_leg, ppm
  , qBoundPpm     :: Integer   -- 1/(2·or), ppm
  }
  deriving (Show, Eq)

quantizationReport :: Ladder -> VolOrder -> [QuantizationRow]
quantizationReport l vo =
  let ns = binNotionals l vo
      ((o0, o1, o2, o3), ps) = binToLegs orMinDefault l vo
      ors = [o0, o1, o2, o3]
      psRaw = unTargetVega ps
  in  [ QuantizationRow leg lo hi n o realized (mulDiv (abs (realized - n)) 1000000 n) (500000 `div` o)
      | (leg, (lo, hi), n, o) <- zip4 [0 ..] (legIntervals vo) ns ors
      , let realized = o * psRaw ]
  where
    zip4 (a:as) (b:bs) (c:cs) (d:ds) = (a, b, c, d) : zip4 as bs cs ds
    zip4 _ _ _ _ = []
