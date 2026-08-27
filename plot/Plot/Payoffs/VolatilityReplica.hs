{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Payoffs.VolatilityReplica'.  Split out of the pure module
-- so that consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.VolatilityReplica
  ( legsLayout
  , replicaLayout
  ) where

import Graphics.Rendering.Chart.Easy (Layout)
import Liquidity.LiquidityChunk (LiquidityChunk, chunkAmount0, chunkAmount1)
import Panoptic.LegChunk (legChunk)
import Panoptic.MintPlan (MintPlan(..), fourLegNumLegs)
import Panoptic.NId (panopticTokenType)
import qualified Payoffs.CLMMPosition as CLMM
import qualified Payoffs.Payoff as Payoff
import Plotting.PlotSqrt (PlotY(..), sqrtFunctionLayout)
import SqrtGrid (PayoffX96(..), SqrtPlot, SqrtPriceX96(..), Tick, integerSqrt, mulDiv, pattern Q96, sqrtPriceX96)
import Payoffs.LadderPosition (Ladder(..), ladderN1, ladderT1)
import Volatility.VolOrder (VolOrder, tickBucketFromVolOrder)
import Payoffs.VolatilityReplica

-- | Per-leg replica terms H_leg(p) − π^φ(LC_leg; p) and their sum (= π̂^σ)
-- on one sqrt axis.
legsLayout :: SqrtPlot -> MintPlan -> Layout Double Double
legsLayout config plan =
  sqrtFunctionLayout config PayoffY $
    [ ("leg " ++ show leg ++ " H − π^φ(LC_leg)", legTerm leg)
    | leg <- [0 .. fourLegNumLegs (mintTokenId plan) - 1]
    ]
    ++ [ ("Σ_leg = π̂^σ", Payoff.runPayoff (fourLegReplica plan (SqrtPriceX96 0))) ]
  where
    legTerm leg p =
      let PayoffX96 h = legMintValue plan leg p
          PayoffX96 principal = legPrincipal (legChunk plan leg) p
      in  PayoffX96 (h - principal)

-- | π̂^σ against a reference curve (e.g. Hop B Carr–Madan) on one sqrt axis.
replicaLayout
  :: SqrtPlot
  -> MintPlan
  -> SqrtPriceX96
  -> [(String, SqrtPriceX96 -> PayoffX96)]
  -> Layout Double Double
replicaLayout config plan pStar references =
  sqrtFunctionLayout config PayoffY $
    ("π̂^σ 4-leg replica", Payoff.runPayoff (fourLegReplica plan pStar)) : references
