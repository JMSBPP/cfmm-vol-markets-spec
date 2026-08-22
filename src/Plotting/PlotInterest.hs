{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Plotting.PlotInterest
  ( InterestPlot(..)
  , plotInterestFunction
  , interestFunctionLayout
  , plotInterestTickFunction
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Backend.Cairo
import Graphics.Rendering.Chart.Easy

import Plotting.PlotSqrt (PlotY(..))
import Payoffs.Return (mkReturn, unReturnPips)
import Payoffs.Savings (savingsPayoff)
import Pricing.InterestSqrt
  ( InterestSqrtX96(..)
  , InterestTick
  , interestSqrtX96
  , mkInterestTick
  , unInterestSqrtX96
  , unInterestTick
  )
import SqrtGrid (PayoffX96, payoffToDouble)

data InterestPlot = InterestPlot
  { plotTitle  :: String
  , xAxisTitle :: String
  , yAxisTitle :: String
  , xMin       :: InterestSqrtX96
  , xMax       :: InterestSqrtX96
  }

interestToDouble :: InterestSqrtX96 -> Double
interestToDouble = fromIntegral . unInterestSqrtX96

interestFunctionEC
  :: InterestPlot
  -> PlotY
  -> [(String, InterestSqrtX96 -> PayoffX96)]
  -> EC (Layout Double Double) ()
interestFunctionEC config plotY labeledFunctions = do
  let
    InterestSqrtX96 lowerBound = xMin config
    InterestSqrtX96 upperBound = xMax config

    numberOfSamples :: Integer
    numberOfSamples = 500

    sampleStep =
      max 1 ((upperBound - lowerBound) `div` numberOfSamples)

    interestSamples =
      [ InterestSqrtX96 rawX96
      | rawX96 <-
          [ lowerBound
          , lowerBound + sampleStep
          .. upperBound
          ]
      ]

    yValue sample interestFunction =
      case plotY of
        PayoffY ->
          max 0 (payoffToDouble (interestFunction sample))
        ReturnY ->
          fromIntegral
            (unReturnPips
              (mkReturn (interestFunction sample) (savingsPayoff sample)))

    functionPoints interestFunction =
      [ (interestToDouble sample, yValue sample interestFunction)
      | sample <- interestSamples
      ]

    yTitle =
      case plotY of
        PayoffY -> "PayoffX96"
        ReturnY -> "ReturnPips"

  layout_title .= plotTitle config
  layout_x_axis . laxis_title .= xAxisTitle config
  layout_y_axis . laxis_title .= yTitle
  setColors
    [ opaque blue
    , opaque red
    , opaque green
    , opaque orange
    , opaque purple
    ]

  mapM_
    (\(seriesLabel, interestFunction) ->
      plot $
        line seriesLabel [functionPoints interestFunction]
    )
    labeledFunctions

interestFunctionLayout
  :: InterestPlot
  -> PlotY
  -> [(String, InterestSqrtX96 -> PayoffX96)]
  -> Layout Double Double
interestFunctionLayout config plotY labeledFunctions =
  execEC (interestFunctionEC config plotY labeledFunctions)

plotInterestFunction
  :: FilePath
  -> InterestPlot
  -> PlotY
  -> [InterestSqrtX96 -> PayoffX96]
  -> IO ()
plotInterestFunction output config plotY interestFunctions =
  toFile def output $
    interestFunctionEC config plotY
      [ ("", interestFunction)
      | interestFunction <- interestFunctions
      ]

-- | Sample by InterestTick (for Swap net along tenor). PayoffY is signed (no max 0).
plotInterestTickFunction
  :: FilePath
  -> InterestPlot
  -> PlotY
  -> InterestTick
  -> InterestTick
  -> [InterestTick -> PayoffX96]
  -> IO ()
plotInterestTickFunction output config plotY tMin tMax tickFunctions =
  toFile def output $ do
    let
      lo = unInterestTick tMin
      hi = unInterestTick tMax
      numberOfSamples = 500 :: Int
      sampleStep = max 1 ((hi - lo) `div` numberOfSamples)
      ticks =
        [ mkInterestTick t
        | t <- [lo, lo + sampleStep .. hi]
        ]

      yValue t tickFunction =
        case plotY of
          PayoffY ->
            payoffToDouble (tickFunction t)
          ReturnY ->
            let sr = interestSqrtX96 t
            in  fromIntegral
                  (unReturnPips
                    (mkReturn (tickFunction t) (savingsPayoff sr)))

      functionPoints tickFunction =
        [ (interestToDouble (interestSqrtX96 t), yValue t tickFunction)
        | t <- ticks
        ]

      yTitle =
        case plotY of
          PayoffY -> "PayoffX96"
          ReturnY -> "ReturnPips"

    layout_title .= plotTitle config
    layout_x_axis . laxis_title .= xAxisTitle config
    layout_y_axis . laxis_title .= yTitle
    setColors
      [ opaque blue
      , opaque red
      , opaque green
      , opaque orange
      , opaque purple
      ]

    mapM_
      (\(seriesLabel, tickFunction) ->
        plot $
          line seriesLabel [functionPoints tickFunction]
      )
      [ ("", tickFunction)
      | tickFunction <- tickFunctions
      ]
