-- | Chart layouts for 'Greeks.Delta'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Greeks.Delta
  ( payoffDeltaLayout
  , deltaLayout
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy

import Greeks.Delta
  ( Delta(..)
  , PayoffDelta
  , PriceDeltaX96(..)
  , coveredCallDelta
  , cpmmDelta
  , rangeAccrualDelta
  , runPayoffDelta
  )
import OptionRatio (OptionRatio)
import Plotting.PlotSqrt (PlotY(..), sqrtFunctionLayout)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPlot(..)
  , SqrtPriceX96(..)
  , toDouble
  )
import StrikeX96 (StrikeX96)

-- | Deltas on one sqrt axis; y = raw token0 (EVM word), plotted through the
-- PayoffX96 channel of `sqrtFunctionLayout`.
payoffDeltaLayout :: SqrtPlot -> [(String, PayoffDelta)] -> Layout Double Double
payoffDeltaLayout config labeled =
  sqrtFunctionLayout config (RawY "token0 (raw, signed)")
    [ (lbl, \p -> let PriceDeltaX96 d = runPayoffDelta pd p in PayoffX96 d)
    | (lbl, pd) <- labeled ]

deltaLayout
  :: SqrtPlot
  -> StrikeX96
  -> OptionRatio
  -> Layout Double Double
deltaLayout config k r =
  execEC $ do
    let
      SqrtPriceX96 lowerBound = xMin config
      SqrtPriceX96 upperBound = xMax config
      numberOfSamples = 500 :: Integer
      sampleStep =
        max 1 ((upperBound - lowerBound) `div` numberOfSamples)
      samples =
        [ SqrtPriceX96 raw
        | raw <- [lowerBound, lowerBound + sampleStep .. upperBound]
        ]
      seriesPoints (Delta d) =
        [ (toDouble sample, fromRational (d sample) :: Double)
        | sample <- samples
        ]

    layout_title .= "Δ_π₉₆"
    layout_x_axis . laxis_title .= "sqrtPriceX96"
    layout_y_axis . laxis_title .= "Delta"
    setColors [opaque blue, opaque red, opaque green]

    plot $ line "Δ Covered Call" [seriesPoints (coveredCallDelta k)]
    plot $ line "Δ Range Accrual" [seriesPoints (rangeAccrualDelta k r)]
    plot $ line "Δ CPMM" [seriesPoints (cpmmDelta k r)]
