{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Payoffs.LvrRate'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.LvrRate
  ( lvrRateLayout
  ) where

import Graphics.Rendering.Chart.Easy (Layout)
import Liquidity.LiquidityChunk (LiquidityChunk, chunkAmount0)
import Panoptic.LegChunk (legChunks)
import Panoptic.MintPlan (MintPlan)
import Payoffs.HolderPath (Regime(..), composedPath)
import Payoffs.PathAccrual (Accrual(..), Step(..), Tag(..), addAccrual, pathAccrual, pattern PIPS_ONE, stepVolume1, zeroAccrual)
import Plot.Payoffs.PathAccrual (linesLayout)
import Pricing.Stremia (FeePips, unFeePips)
import SqrtGrid (PayoffX96(..), Tick, mulDiv)
import Payoffs.LvrRate


-- | λ vs s for several φ, naive band (crosses zero at 2φ ticks) and rational band (≥ 0).
-- Axes: ticks, pips.
lvrRateLayout :: Int -> Tick -> Int -> Int -> MintPlan -> [FeePips] -> [Int] -> Layout Double Double
lvrRateLayout seed i0 n transAmp plan phis ss =
  linesLayout "λ_{X/M}: LVR_net per unit arb volume vs external step s (holder inactive)"
    "external step s (ticks / round)" "LVR_net / Σ amount_in (pips)"
    (concat
      [ [ ("φ = " ++ show (unFeePips phi) ++ " pips, band φ (naive)", lvrRateTable seed i0 n transAmp phi (naiveBandTicks phi) plan ss)
        , ("φ = " ++ show (unFeePips phi) ++ " pips, band 2φ (rational)", lvrRateTable seed i0 n transAmp phi (rationalBandTicks phi) plan ss) ]
      | phi <- phis ])
