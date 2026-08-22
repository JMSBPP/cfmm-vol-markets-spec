{-# LANGUAGE PatternSynonyms #-}

module Plotting.PlotSqrt
  ( PlotY(..)
  , plotSqrtFunction
  , sqrtFunctionLayout
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Backend.Cairo
import Graphics.Rendering.Chart.Easy

import Payoffs.Linear (linearPayoff)
import Payoffs.Return (mkReturn, unReturnPips)
import SqrtGrid
  ( PayoffX96
  , SqrtPlot(..)
  , SqrtPriceX96(..)
  , payoffToDouble
  , toDouble
  )

data PlotY = PayoffY | ReturnY
  deriving (Show, Eq)

sqrtFunctionEC
  :: SqrtPlot
  -> PlotY
  -> [(String, SqrtPriceX96 -> PayoffX96)]
  -> EC (Layout Double Double) ()
sqrtFunctionEC config plotY labeledFunctions = do
  let
    SqrtPriceX96 lowerBound = xMin config
    SqrtPriceX96 upperBound = xMax config

    numberOfSamples :: Integer
    numberOfSamples = 500

    sampleStep =
      max 1 ((upperBound - lowerBound) `div` numberOfSamples)

    sqrtPriceSamples =
      [ SqrtPriceX96 rawX96
      | rawX96 <-
          [ lowerBound
          , lowerBound + sampleStep
          .. upperBound
          ]
      ]

    yValue sample sqrtFunction =
      case plotY of
        PayoffY ->
          max 0 (payoffToDouble (sqrtFunction sample))
        ReturnY ->
          fromIntegral
            (unReturnPips (mkReturn (sqrtFunction sample) (linearPayoff sample)))

    functionPoints sqrtFunction =
      [ (toDouble sample, yValue sample sqrtFunction)
      | sample <- sqrtPriceSamples
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
    (\(seriesLabel, sqrtFunction) ->
      plot $
        line seriesLabel [functionPoints sqrtFunction]
    )
    labeledFunctions

sqrtFunctionLayout
  :: SqrtPlot
  -> PlotY
  -> [(String, SqrtPriceX96 -> PayoffX96)]
  -> Layout Double Double
sqrtFunctionLayout config plotY labeledFunctions =
  execEC (sqrtFunctionEC config plotY labeledFunctions)

plotSqrtFunction
  :: FilePath
  -> SqrtPlot
  -> PlotY
  -> [SqrtPriceX96 -> PayoffX96]
  -> IO ()
plotSqrtFunction output config plotY sqrtFunctions =
  toFile def output $
    sqrtFunctionEC config plotY
      [ ("", sqrtFunction)
      | sqrtFunction <- sqrtFunctions
      ]
