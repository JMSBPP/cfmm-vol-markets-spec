-- | Chart layouts for 'Pricing.AdaptiveStremia'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Pricing.AdaptiveStremia
  ( adaptiveFeeLayout
  ) where

import Graphics.Rendering.Chart.Easy (Layout)
import Plot.Payoffs.PathAccrual (linesLayout)
import Pricing.Stremia (FeePips, mkFeePips, unFeePips)
import SqrtGrid (Tick)
import Pricing.AdaptiveStremia


-- | Fee (pips) vs volatility (oracle units) for a configuration. Axes: uint88 units × pips.
adaptiveFeeLayout :: AdaptiveStremia -> [Integer] -> Layout Double Double
adaptiveFeeLayout c vols =
  linesLayout "Algebra AdaptiveFee.getFee: baseFee + σ₁ + σ₂ (integer-exact port)"
    "volatility (oracle uint88 units, before /15)" "fee (pips)"
    [ ("getFee", [ (v, unFeePips (adaptiveFeePips c (Volatility v))) | v <- vols ])
    , ("baseFee + α₁ + α₂ cap", [ (v, baseFee c + alpha1 c + alpha2 c) | v <- vols ]) ]
