{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Payoffs.ReplicaDelta'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.ReplicaDelta
  ( replicaDeltaLayout
  ) where

import Graphics.Rendering.Chart.Easy (Layout)
import Greeks.Delta (PayoffDelta(..), PriceDeltaX96(..), deltaOfPayoff)
import Plot.Greeks.Delta (payoffDeltaLayout)
import Liquidity.LiquidityChunk (LiquidityChunk, chunkAmount0, chunkLiquidity, chunkTickLower, chunkTickUpper)
import Panoptic.LegChunk (legChunk)
import Panoptic.MintPlan (MintPlan(..), fourLegNumLegs)
import Panoptic.NId (panopticTokenType)
import Payoffs.VolatilityReplica (fourLegReplica)
import SqrtGrid (PayoffX96(..), SqrtPlot, SqrtPriceX96(..), mulDiv, pattern Q96, sqrtPriceX96)
import Payoffs.ReplicaDelta


-- | Closed form vs the generic finite-difference instance on the same axis.
replicaDeltaLayout :: SqrtPlot -> MintPlan -> SqrtPriceX96 -> Layout Double Double
replicaDeltaLayout config plan pStar =
  payoffDeltaLayout config
    [ ("Δ̂^σ closed form (Σ_leg)", replicaDelta plan)
    , ("∂_P π̂^σ central difference", deltaOfPayoff (fourLegReplica plan pStar))
    ]
