{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Payoffs.ReplicaDelta'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.ReplicaDelta
  ( replicaDeltaLayout
  ) where

import Graphics.Rendering.Chart.Easy (Layout)
import Greeks.Delta (deltaOfPayoff)
import Plot.Greeks.Delta (payoffDeltaLayout)
import Panoptic.MintPlan (MintPlan(..))
import Payoffs.VolatilityReplica (fourLegReplica)
import SqrtGrid (SqrtPlot, SqrtPriceX96(..))
import Payoffs.ReplicaDelta

-- | Closed form vs the generic finite-difference instance on the same axis.
replicaDeltaLayout :: SqrtPlot -> MintPlan -> SqrtPriceX96 -> Layout Double Double
replicaDeltaLayout config plan pStar =
  payoffDeltaLayout config
    [ ("Δ̂^σ closed form (Σ_leg)", replicaDelta plan)
    , ("∂_P π̂^σ central difference", deltaOfPayoff (fourLegReplica plan pStar))
    ]
